# 11 Questions Round 1 - Production Containerization

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. Base Image Strategy

What base image approach should we use for the production runtime stage?

- [ ] (A) Eclipse Temurin JRE 17 slim (e.g., `eclipse-temurin:17-jre-jammy`) — widely used, well-maintained, ~80MB
- [x] (B) Amazon Corretto 17 (e.g., `amazoncorretto:17-alpine`) — AWS-optimized JDK, good fit for ECS/Fargate
- [ ] (C) Distroless Java (e.g., `gcr.io/distroless/java17-debian12`) — minimal attack surface, no shell, ~50MB
- [ ] (D) Alpine-based JRE (e.g., `eclipse-temurin:17-jre-alpine`) — smallest image, potential musl libc issues
- [ ] (E) Other (describe)

## 2. Spring Boot Packaging Strategy

How should we package the Spring Boot application inside the container?

- [ ] (A) Fat JAR — simple `java -jar app.jar`, single layer, standard approach
- [x] (B) Layered JAR with Spring Boot's built-in layer extraction — splits dependencies/app into separate Docker layers for better caching (dependencies change rarely, app code changes often)
- [ ] (C) Exploded directory layout — fastest startup, most complex Containerfile
- [ ] (D) Other (describe)

## 3. Health Check Endpoints

The existing k8s manifests use `/livez` and `/readyz`. What health check approach for the container itself?

- [x] (A) Use Spring Boot Actuator `/actuator/health` as the container HEALTHCHECK — simple, standard
- [ ] (B) Use the k8s-style `/livez` and `/readyz` endpoints (requires `management.endpoint.health.probes.add-additional-paths=true`) — matches existing k8s config
- [ ] (C) No container-level HEALTHCHECK — let ECS Fargate handle health checks via ALB target group
- [ ] (D) Other (describe)

## 4. Container Registry Target

Where will the production image be pushed? (This affects image naming/tagging in the Containerfile and CI)

- [x] (A) Amazon ECR only — images tagged as `<account>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>`
- [ ] (B) GitHub Container Registry (GHCR) only — images tagged as `ghcr.io/<org>/<repo>:<tag>`
- [ ] (C) Both ECR and GHCR — push to both for redundancy/portability
- [ ] (D) Other (describe)

## 5. Image Tagging Strategy

How should we tag production images?

- [ ] (A) Git SHA only (e.g., `abc123f`) — simple, traceable to exact commit
- [ ] (B) Semantic version from git tags (e.g., `v1.2.3`) — requires release discipline
- [ ] (C) Both git SHA + `latest` tag on main branch — common pattern
- [x] (D) Git SHA + semver when tagged + `latest` on main — most flexible
- [ ] (E) Other (describe)

## 6. JVM Tuning for Containers

Should we include JVM container-awareness flags in the Containerfile?

- [ ] (A) Yes, set sensible defaults (e.g., `-XX:MaxRAMPercentage=75.0`, `-XX:+UseContainerSupport`) — prevents OOM in Fargate
- [ ] (B) No, leave JVM defaults and configure via ECS task definition environment variables — more flexible
- [x] (C) Set minimal defaults in Containerfile, allow override via env vars (e.g., `JAVA_OPTS`) — balanced approach
- [ ] (D) Other (describe)

## 7. Database Profile Default

What Spring profile should the container default to?

- [ ] (A) No default — require `SPRING_PROFILES_ACTIVE` to be set explicitly at deploy time
- [x] (B) Default to `postgres` — this is the production database. Note: the H2 embedded database should NOT be used in the container. Production always connects to an external RDS PostgreSQL instance.
- [ ] (C) Default to `h2` — safe fallback, won't fail if no database is configured
- [ ] (D) Other (describe)

## 8. Proof Artifacts

What would best demonstrate this spec is working correctly?

- [x] (A) `podman build` succeeds + `podman run` starts and responds on port 8080 + health check passes. Note: Grype/container security scanning will come in Spec 16.
- [ ] (B) Above + image size comparison (before/after or vs naive single-stage build)
- [ ] (C) Above + security scan of the image (e.g., `podman scan` or Grype) showing no critical vulnerabilities
- [ ] (D) Other (describe)
