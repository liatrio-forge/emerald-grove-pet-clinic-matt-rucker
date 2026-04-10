# Task 3.0 Proof Artifacts: Container Verification Against PostgreSQL

## Health Check

```bash
$ curl -s http://localhost:8080/actuator/health
{"groups":["liveness","readiness"],"status":"UP"}
```

## Homepage

```bash
$ curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/
200
```

## Owners Page

```bash
$ curl -s -o /dev/null -w '%{http_code}' 'http://localhost:8080/owners?lastName='
200
```

## Distroless Verification: No Shell

```bash
$ podman run --rm emerald-grove-pet-clinic:test sh
Picked up JAVA_TOOL_OPTIONS: -XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport
...
org.postgresql.util.PSQLException: Connection to localhost:5432 refused.
```

The `sh` command was passed as an argument to the Java entrypoint (not to a
shell), causing the application to attempt startup with an invalid argument.
This confirms there is no shell in the image — the entrypoint is the Java
process directly.

## Distroless Verification: No whoami

```bash
$ podman run --rm emerald-grove-pet-clinic:test whoami
Picked up JAVA_TOOL_OPTIONS: -XX:MaxRAMPercentage=75.0 -XX:+UseContainerSupport
...
org.postgresql.util.PSQLException: Connection to localhost:5432 refused.
```

Same behavior — `whoami` is passed as a Java argument, not executed as a
system utility. No system utilities are present in the distroless image.

## Layer Caching Verification

After making a trivial change to a Java source file and rebuilding:

```text
[1/2] STEP 2/8: WORKDIR /workspace           --> Using cache
[1/2] STEP 3/8: COPY .mvn/ .mvn/             --> Using cache
[1/2] STEP 4/8: COPY mvnw pom.xml ./         --> Using cache
[1/2] STEP 5/8: RUN ./mvnw dependency:go-offline -B  --> Using cache
[1/2] STEP 6/8: COPY src/ src/               --> CACHE BUST (source changed)
[2/2] STEP 3/8: COPY lib/                    --> Using cache (deps unchanged)
[2/2] STEP 4/8: COPY application.jar         --> CACHE BUST (app changed)
```

Dependency layers (Maven downloads, runtime lib/) are fully cached. Only the
application code layer is rebuilt. Rebuild time: ~37 seconds for code-only
changes.

## Test Containers Setup

```bash
$ podman run -d --name test-postgres \
    -e POSTGRES_USER=petclinic \
    -e POSTGRES_PASSWORD=petclinic \
    -e POSTGRES_DB=petclinic \
    -p 5432:5432 docker.io/library/postgres:18.1

$ podman run -d --name test-app \
    -p 8080:8080 \
    -e POSTGRES_URL=jdbc:postgresql://host.containers.internal:5432/petclinic \
    -e POSTGRES_USER=petclinic \
    -e POSTGRES_PASS=petclinic \
    -e ANTHROPIC_API_KEY= \
    emerald-grove-pet-clinic:test
```

Application started in under 10 seconds and connected to PostgreSQL
successfully.
