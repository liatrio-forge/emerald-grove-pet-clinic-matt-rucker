# 11-spec-production-containerization

## Introduction/Overview

The Emerald Grove Veterinary Clinic application currently has no production container image. The only existing Dockerfile is a dev container for Gitpod/VS Code, and the Kubernetes manifests reference a third-party `dsyer/petclinic` image. This spec defines a production-ready Containerfile that produces an optimized, secure, distroless container image using Podman (no Docker dependency), suitable for deployment to Amazon ECS Fargate via Amazon ECR.

## Goals

- Create a multi-stage Containerfile that builds and packages the Spring Boot application into a minimal, distroless production image
- Use Chainguard's `amazon-corretto-jre` distroless image as the runtime base for maximum security and AWS optimization
- Leverage Spring Boot's layered JAR extraction for efficient image layer caching
- Harden the container with a non-root user, no shell, no package manager, and sensible JVM defaults
- Create a `.containerignore` file to exclude unnecessary files from the build context
- Ensure the image is fully compatible with Podman, ECR, and ECS Fargate

## User Stories

- **As a DevOps engineer**, I want to build a production container image with a single command (`podman build`) so that I can deploy the application to AWS without manual packaging steps.
- **As a developer**, I want container builds to be fast on repeat builds so that I don't waste time waiting for unchanged dependencies to re-download.
- **As a security engineer**, I want the production container to use a distroless base image with no shell or package manager so that the attack surface is minimized.

## Demoable Units of Work

### Unit 1: Multi-Stage Containerfile with Layered JAR

**Purpose:** Create the core Containerfile that builds the application and produces an optimized production image using Spring Boot's layered JAR extraction and a Chainguard distroless runtime.

**Functional Requirements:**

- The Containerfile shall use a multi-stage build: Amazon Corretto 17 (full JDK) for the build stage, Chainguard `amazon-corretto-jre:latest` (`cgr.dev/chainguard/amazon-corretto-jre:latest`) for the runtime stage
- The build stage shall use Maven to compile and package the application (`./mvnw package -DskipTests`)
- The build stage shall leverage Spring Boot's layered JAR tool (`java -Djarmode=tools -jar app.jar extract --layers --destination extracted`) to split the JAR into dependency layers
- The runtime stage shall copy layers in dependency order (dependencies → spring-boot-loader → snapshot-dependencies → application) for optimal container layer caching
- The Containerfile shall be named `Containerfile` (Podman convention) and placed in the project root

**Proof Artifacts:**

- CLI: `podman build -t emerald-grove-pet-clinic:test .` completes successfully, demonstrating the multi-stage build works
- CLI: `podman images emerald-grove-pet-clinic:test` shows image size under 300MB, demonstrating the distroless image is optimized

### Unit 2: Security Hardening and Runtime Configuration

**Purpose:** Harden the container for production use with non-root execution and configurable JVM settings. Health checks are delegated to the platform (ECS Fargate + ALB) since the distroless image has no shell.

**Functional Requirements:**

- The Containerfile shall run the application as a non-root user (the Chainguard distroless image provides a default non-root user; verify and use it, or create one in the build stage and copy `/etc/passwd` to the runtime stage)
- The Containerfile shall NOT include a `HEALTHCHECK` instruction — health checking is delegated to ECS Fargate via ALB target group health checks against `/actuator/health` (distroless images have no shell to execute health check commands)
- The Containerfile shall set `SPRING_PROFILES_ACTIVE=postgres` as the default profile via `ENV`
- The Containerfile shall expose port 8080
- The Containerfile shall set sensible JVM defaults via a `JAVA_OPTS` environment variable (e.g., `-XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport`) that can be overridden at runtime
- The entrypoint shall use `exec` form: `ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]` — JVM options are passed via the `JAVA_OPTS` env var using `ENV JAVA_TOOL_OPTIONS` (which the JVM reads automatically, no shell expansion needed)

**Proof Artifacts:**

- CLI: `podman run -d -p 8080:8080 -e POSTGRES_URL=jdbc:postgresql://host.containers.internal:5432/petclinic emerald-grove-pet-clinic:test` starts successfully and responds to `curl http://localhost:8080/actuator/health` from the host, demonstrating the container runs correctly
- CLI: `podman inspect emerald-grove-pet-clinic:test --format '{{.Config.User}}'` returns a non-root user, demonstrating non-root execution
- CLI: `podman run --rm emerald-grove-pet-clinic:test whoami` fails (no shell), demonstrating the distroless nature of the image

### Unit 3: Build Context Optimization

**Purpose:** Create a `.containerignore` file to exclude unnecessary files from the build context, speeding up builds and reducing image attack surface.

**Functional Requirements:**

- A `.containerignore` file shall be created in the project root
- The file shall exclude: `.git/`, `target/`, `node_modules/`, `e2e-tests/`, `.idea/`, `*.md` (except README.md), `docs/`, `.devcontainer/`, `k8s/`, `.github/`, `Tiltfile`, `docker-compose.yml`, `.local/`, `test-results/`, `.claude/`
- The `.containerignore` file shall also work as `.dockerignore` (symlink or identical content) for compatibility

**Proof Artifacts:**

- CLI: `podman build` with `.containerignore` in place completes faster than without (build context size reduction), demonstrating unnecessary files are excluded

## Non-Goals (Out of Scope)

1. **CI/CD integration** — Image build/push automation is covered in Spec 12 (Dagger CI Pipeline)
2. **Container registry setup** — ECR repository creation is covered in Spec 13 (OpenTofu Foundation)
3. **Security scanning** — Grype and AWS Inspector integration is covered in Spec 16 (Security Scanning)
4. **GraalVM native image** — Native compilation adds complexity without clear benefit for this exercise
5. **Docker Compose changes** — The existing Docker-compose.yml for local dev databases is unchanged by this spec
6. **Image tagging strategy** — Tag naming (git SHA, semver, latest) is implemented in Spec 12 (Dagger CI Pipeline)
7. **Container-level HEALTHCHECK** — Delegated to ECS Fargate + ALB (Specs 13/14) since distroless has no shell
8. **ECS task definition** — Fargate configuration (CPU, memory, env vars) is covered in Spec 13 (OpenTofu Foundation)

## Design Considerations

No specific design requirements identified. This is infrastructure work with no UI impact.

## Repository Standards

- Follow conventional commits: `feat(infra): add production Containerfile`
- Place Containerfile in project root (standard convention)
- Follow the project's existing `.pre-commit-config.yaml` checks
- Follow Constitution Article 11 (Mise + Dagger CI/CD) — this spec creates the Containerfile; the Dagger pipeline in Spec 12 will invoke it
- Follow Constitution Article 12 (Infrastructure as Code) — container config is code

## Technical Considerations

- **Podman compatibility**: The Containerfile must use OCI-standard instructions only. No Docker-specific extensions. Use `Containerfile` as the filename (Podman convention; Podman also reads `Dockerfile`).
- **Chainguard distroless image**: `cgr.dev/chainguard/amazon-corretto-jre:latest` is free for the `:latest` tag. No version pinning available on the free tier — acceptable for a learning exercise. The image has no shell, no package manager, and no debugging tools. This is intentional.
- **JVM options without shell**: Since there's no shell in distroless, we cannot use `$JAVA_OPTS` expansion in the entrypoint. Instead, use `JAVA_TOOL_OPTIONS` env var, which the JVM reads natively without shell interpolation. This is the standard pattern for distroless Java containers.
- **Spring Boot layered JAR**: Requires Spring Boot 2.3+ (we're on 4.0.0). The `spring-boot-maven-plugin` already supports layer extraction without additional configuration.
- **Build argument for Java version**: Consider using `ARG JAVA_VERSION=17` to make the Containerfile forward-compatible.
- **Maven dependency caching**: The build stage should copy `pom.xml` and download dependencies before copying source code, so dependency layers are cached across builds.
- **Fallback strategy**: If the Chainguard distroless image causes compatibility issues (e.g., with Spring AI / Anthropic SDK native dependencies), fall back to `amazoncorretto:17-alpine` with manually removed unnecessary packages.

## Security Considerations

- **Distroless runtime**: No shell, no package manager, no debugging tools in the production image. This eliminates entire classes of container escape and RCE attacks.
- **Non-root execution**: The container must not run as root. Chainguard images provide a default non-root user.
- **No secrets in image**: The Containerfile must NOT embed any credentials, API keys, or sensitive configuration. All secrets (`ANTHROPIC_API_KEY`, `POSTGRES_PASS`, etc.) are injected at runtime via environment variables.
- **No build tools in runtime**: The multi-stage build ensures Maven, the full JDK, and source code are not present in the final image.
- **Read-only filesystem**: The application should be able to run with a read-only root filesystem. Spring Boot writes to `/tmp` for Tomcat work directory — ensure `/tmp` is writable (tmpfs mount in ECS task definition).

## Success Metrics

1. **Image builds successfully** with `podman build` on the developer's local machine
2. **Image size** is under 300MB (distroless should be significantly smaller than Alpine-based alternatives)
3. **Container starts and responds** to `curl http://localhost:8080/actuator/health` within 40 seconds when pointed at a PostgreSQL instance
4. **Runs as non-root** — verified via `podman inspect`
5. **No shell access** — `podman run --rm <image> sh` fails, confirming distroless
6. **Rebuild with only app code changes** reuses cached dependency layers (build time < 30 seconds for code-only changes)

## Open Questions

No open questions at this time. If the Chainguard distroless image causes compatibility issues during implementation, the fallback to `amazoncorretto:17-alpine` is documented in Technical Considerations.
