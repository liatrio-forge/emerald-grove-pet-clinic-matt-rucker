# 11-tasks-production-containerization

Task list for [11-spec-production-containerization](11-spec-production-containerization.md).

## Relevant Files

- `Containerfile` - **New file.** Multi-stage production container build definition (Podman convention).
- `.containerignore` - **New file.** Excludes unnecessary files from the Podman build context.
- `.dockerignore` - **New file.** Symlink to `.containerignore` for Docker compatibility.
- `docs/specs/11-spec-production-containerization/11-proofs/` - **New directory.** Proof artifact outputs for each task.

### Notes

- Use `podman` CLI for all container operations — no Docker dependency.
- The project uses Maven (`./mvnw`) as the primary build tool. Java 17, Spring Boot 4.0.0.
- Tests are run with `./mvnw test`. Pre-commit hooks run tests automatically.
- Follow conventional commits: `feat(infra): ...` for new infrastructure files.
- The Chainguard distroless image (`cgr.dev/chainguard/amazon-corretto-jre:latest`) is free for the `:latest` tag only.
- All proof artifacts should be saved as text files in the proofs directory with commands and their output.

## Tasks

### [x] 1.0 Create Build Context Optimization (.containerignore)

Create a `.containerignore` file to exclude unnecessary files from the Podman build context. This must be in place before the first image build to ensure clean, fast builds from the start.

#### 1.0 Proof Artifact(s)

- CLI: `podman build --no-cache -t test-context . 2>&1 | head -5` shows a small build context size (under 5MB), demonstrating unnecessary files are excluded
- Diff: `.containerignore` file committed with comprehensive exclusion list demonstrates build context optimization

#### 1.0 Tasks

- [x] 1.1 Create `.containerignore` in the project root with the following exclusions: `.git/`, `target/`, `node_modules/`, `e2e-tests/`, `.idea/`, `*.iws`, `*.iml`, `*.ipr`, `*.md`, `docs/`, `.devcontainer/`, `k8s/`, `.github/`, `Tiltfile`, `docker-compose.yml`, `.local/`, `test-results/`, `.claude/`, `.gradle/`, `build/`, `.settings/`, `.classpath`, `.project`, `.factorypath`, `.springBeans`, `.sts4-cache`, `bin/`, `*.log`, `.env`, `.gitpod.yml`
- [x] 1.2 Create `.dockerignore` as a symlink to `.containerignore` (`ln -s .containerignore .dockerignore`) for compatibility with tools that expect `.dockerignore`
- [x] 1.3 Create a temporary minimal `Containerfile` (just `FROM alpine` + `RUN ls /`) to verify the build context is small, then delete it. Save the build context size output to `docs/specs/11-spec-production-containerization/11-proofs/11-task-01-proofs.md`

### [ ] 2.0 Create Multi-Stage Production Containerfile

Create the core `Containerfile` with a multi-stage build: Amazon Corretto 17 JDK for building, Chainguard `amazon-corretto-jre:latest` distroless for runtime. Uses Spring Boot layered JAR extraction for optimal layer caching. Includes all security hardening (non-root user, no HEALTHCHECK, JAVA_TOOL_OPTIONS for JVM defaults, postgres profile default).

#### 2.0 Proof Artifact(s)

- CLI: `podman build -t emerald-grove-pet-clinic:test .` completes successfully, demonstrating the multi-stage build works end-to-end
- CLI: `podman images emerald-grove-pet-clinic:test --format '{{.Size}}'` shows image size under 300MB, demonstrating distroless optimization
- CLI: `podman inspect emerald-grove-pet-clinic:test --format '{{.Config.User}}'` returns a non-root user, demonstrating security hardening
- CLI: `podman inspect emerald-grove-pet-clinic:test --format '{{.Config.Env}}'` shows `SPRING_PROFILES_ACTIVE=postgres` and `JAVA_TOOL_OPTIONS` with JVM defaults, demonstrating runtime configuration

#### 2.0 Tasks

- [ ] 2.1 Create `Containerfile` in the project root with the build stage:
  - `FROM amazoncorretto:17 AS build`
  - Set `WORKDIR /workspace`
  - Copy Maven wrapper and pom.xml first (`COPY .mvn/ .mvn/`, `COPY mvnw pom.xml ./`)
  - Run `./mvnw dependency:go-offline -B` to download dependencies (cached layer)
  - Copy source code (`COPY src/ src/`)
  - Run `./mvnw package -DskipTests -B` to build the fat JAR
  - Extract layered JAR: `java -Djarmode=tools -jar target/*.jar extract --layers --destination /workspace/extracted`
- [ ] 2.2 Add the runtime stage to the Containerfile:
  - `FROM cgr.dev/chainguard/amazon-corretto-jre:latest AS runtime`
  - Set `WORKDIR /app`
  - Copy layers from build stage in dependency order:
    - `COPY --from=build /workspace/extracted/dependencies/ ./`
    - `COPY --from=build /workspace/extracted/spring-boot-loader/ ./`
    - `COPY --from=build /workspace/extracted/snapshot-dependencies/ ./`
    - `COPY --from=build /workspace/extracted/application/ ./`
- [ ] 2.3 Add runtime configuration to the Containerfile:
  - `ENV SPRING_PROFILES_ACTIVE=postgres`
  - `ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport"`
  - `EXPOSE 8080`
  - `ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]`
- [ ] 2.4 Verify the Chainguard image provides a non-root user by default. If it does, no additional `USER` instruction is needed. If not, add user creation in the build stage and copy `/etc/passwd` to the runtime stage. Document the finding.
- [ ] 2.5 Build the image with `podman build -t emerald-grove-pet-clinic:test .` and verify:
  - Build completes without errors
  - Image size is under 300MB (`podman images emerald-grove-pet-clinic:test --format '{{.Size}}'`)
  - User is non-root (`podman inspect emerald-grove-pet-clinic:test --format '{{.Config.User}}'`)
  - Environment variables are set correctly (`podman inspect emerald-grove-pet-clinic:test --format '{{.Config.Env}}'`)
  - Save all output to `docs/specs/11-spec-production-containerization/11-proofs/11-task-02-proofs.md`
- [ ] 2.6 If the Chainguard distroless image causes build or runtime failures (e.g., musl libc incompatibility with Spring AI), switch the runtime stage to `amazoncorretto:17-alpine` and add a non-root user manually (`adduser -D -u 1001 appuser && USER appuser`). Document the fallback decision in the proofs file.

### [ ] 3.0 Verify Container Runs Against PostgreSQL

Start a PostgreSQL instance via Podman, run the production container pointing at it, and verify the application starts, responds to requests, and the actuator health endpoint works. Also verify distroless properties (no shell access).

#### 3.0 Proof Artifact(s)

- CLI: `curl http://localhost:8080/actuator/health` returns `{"status":"UP"}` from the running container, demonstrating the application starts and connects to PostgreSQL
- CLI: `curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/` returns `200`, demonstrating the application serves pages
- CLI: `podman run --rm emerald-grove-pet-clinic:test sh` fails with an error, demonstrating the distroless image has no shell
- CLI: `podman run --rm emerald-grove-pet-clinic:test whoami` fails with an error, demonstrating no system utilities are present

#### 3.0 Tasks

- [ ] 3.1 Create a Podman pod (or use `--network` flag) so the app container can reach PostgreSQL. Start a PostgreSQL container:
  - `podman run -d --name test-postgres -e POSTGRES_USER=petclinic -e POSTGRES_PASSWORD=petclinic -e POSTGRES_DB=petclinic -p 5432:5432 postgres:18.1`
  - Wait for postgres to be ready: `podman exec test-postgres pg_isready -U petclinic`
- [ ] 3.2 Run the production container connected to the test PostgreSQL:
  - `podman run -d --name test-app -p 8080:8080 -e POSTGRES_URL=jdbc:postgresql://host.containers.internal:5432/petclinic -e POSTGRES_USER=petclinic -e POSTGRES_PASS=petclinic -e ANTHROPIC_API_KEY= emerald-grove-pet-clinic:test`
  - Note: `ANTHROPIC_API_KEY` is set to empty string intentionally — the AI assistant feature degrades gracefully without it
- [ ] 3.3 Verify the application is healthy and serving pages:
  - Wait up to 40 seconds for startup, then: `curl http://localhost:8080/actuator/health` — expect `{"status":"UP"}`
  - `curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/` — expect `200`
  - `curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/owners?lastName=` — expect `200`
- [ ] 3.4 Verify distroless properties:
  - `podman run --rm emerald-grove-pet-clinic:test sh` — expect failure (no shell)
  - `podman run --rm emerald-grove-pet-clinic:test whoami` — expect failure (no utilities)
- [ ] 3.5 Verify layer caching: make a trivial change to a Java source file, rebuild with `podman build -t emerald-grove-pet-clinic:test .`, and confirm the dependency layers are reused (look for `CACHED` or `Using cache` in build output). Confirm rebuild takes under 30 seconds for code-only changes.
- [ ] 3.6 Save all verification output to `docs/specs/11-spec-production-containerization/11-proofs/11-task-03-proofs.md`
- [ ] 3.7 Clean up test containers: `podman rm -f test-app test-postgres`
