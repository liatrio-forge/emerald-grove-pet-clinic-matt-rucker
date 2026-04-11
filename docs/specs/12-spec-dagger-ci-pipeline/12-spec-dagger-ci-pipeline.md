# 12-spec-dagger-ci-pipeline

## Introduction/Overview

The Emerald Grove Veterinary Clinic application has no unified CI/CD pipeline. Existing GitHub Actions workflows (E2E tests, performance tests) contain build logic directly in YAML, violating Constitution Article 11 which mandates all pipeline logic live in Dagger. This spec creates the foundational CI pipeline: a `.mise.toml` for tool and task management, a Dagger module (Go SDK) implementing build/test/coverage/image steps, and a thin GitHub Actions workflow that simply calls `mise run ci`.

## Goals

- Create a `.mise.toml` that manages all tool versions (Java 17, Node 20, Maven, Dagger) and defines developer-facing tasks (`ci`, `test`, `build`, `format`, `lint`, `dev`, `dev:down`)
- Implement a Dagger pipeline in Go that runs: build → test → branch coverage gate (80%) → image build → image push (configurable, skippable without ECR credentials)
- Replace existing GitHub Actions workflows with a single thin workflow that calls `mise run ci`
- Ensure `mise run ci` produces identical results locally and in CI
- Document all Mise tasks in README.md

## User Stories

- **As a developer**, I want to run `mise run ci` locally so that I can verify my changes pass the same pipeline that runs in CI before pushing.
- **As a DevOps engineer**, I want CI/CD logic defined in Go (Dagger) so that I can test, debug, and evolve the pipeline with real programming tools instead of editing YAML.
- **As a new contributor**, I want to run `mise install` and have all required tools available so that I can start working without manually installing Java, Maven, Node, or Dagger.
- **As a team lead**, I want a branch coverage gate so that code paths through conditionals, loops, and switches are tested — not just lines executed.

## Demoable Units of Work

### Unit 1: Mise Configuration and Developer Tasks

**Purpose:** Set up `.mise.toml` as the single entry point for tool version management and developer commands. A new contributor can clone the repo, run `mise install`, and have everything they need.

**Functional Requirements:**

- The `.mise.toml` file shall define tool versions: Java 17 (via `java` backend), Node 20, Maven (latest 3.9.x), and Dagger (latest)
- The `.mise.toml` file shall define the following tasks with descriptions:
  - `ci` — runs the full Dagger CI pipeline (build, test, coverage, image build)
  - `test` — runs `./mvnw test`
  - `build` — runs `./mvnw package -DskipTests`
  - `format` — runs `./mvnw spring-javaformat:apply`
  - `lint` — runs `./mvnw spring-javaformat:validate checkstyle:check`
  - `dev` — starts local dev environment (Podman Compose postgres + Spring Boot)
  - `dev:down` — stops local dev environment
- The README.md shall be updated with a "Development Commands" section documenting all Mise tasks
- Running `mise install` in the project root shall install all required tools without errors

**Proof Artifacts:**

- CLI: `mise install` completes successfully, demonstrating tool installation works
- CLI: `mise run test` runs the Maven test suite and passes, demonstrating task execution works
- CLI: `mise ls` shows Java 17, Node 20, Maven, and Dagger installed at correct versions

### Unit 2: Dagger CI Pipeline (Build, Test, Coverage Gate)

**Purpose:** Implement the core CI pipeline as Dagger functions in Go. The pipeline builds the app, runs tests with JaCoCo coverage, and fails if branch coverage is below 80%.

**Functional Requirements:**

- A Dagger module shall be initialized in `dagger/` using the Go SDK (`dagger init --sdk=go`)
- The Dagger module shall expose a `Ci` function that orchestrates the full pipeline
- The `Ci` function shall execute the following steps in order:
  1. **Build**: Compile the application with `./mvnw package -DskipTests`
  2. **Test**: Run the test suite with `./mvnw test` and generate JaCoCo coverage reports
  3. **Coverage Gate**: Parse the JaCoCo XML report and fail if overall branch coverage is below 80%
  4. **Image Build**: Build the production container image using the existing `Containerfile`
- Each step shall be implemented as a separate Dagger function (e.g., `Build`, `Test`, `CoverageCheck`, `BuildImage`) so they can be called independently
- The pipeline shall accept the project source directory as input
- The pipeline shall run inside a Maven/Corretto 17 container (consistent with the Containerfile build stage)
- The coverage gate shall report the actual branch coverage percentage in its output, whether it passes or fails

**Proof Artifacts:**

- CLI: `dagger call ci --source=.` completes successfully, demonstrating the full pipeline works
- CLI: `mise run ci` completes successfully, demonstrating Mise invokes Dagger correctly
- CLI: A deliberately failing test causes the pipeline to fail, demonstrating the test step catches failures

### Unit 3: Image Build and Push (ECR-Ready)

**Purpose:** Add container image build and optional push to ECR as Dagger functions. Push is skippable when ECR credentials are not available (local dev, or before Spec 13 provisions ECR).

**Functional Requirements:**

- The Dagger module shall expose a `BuildImage` function that builds the production image using the existing `Containerfile`
- The Dagger module shall expose a `Push` function that pushes the built image to an ECR registry
- The `Push` function shall accept the ECR registry URL as a parameter
- The `Ci` function shall skip the push step if no registry URL is provided (local-only mode)
- The `Ci` function shall accept an optional `--registry` flag to enable pushing
- Image tagging shall use the git SHA (short) as the tag, with `latest` added when on the main branch

**Proof Artifacts:**

- CLI: `dagger call build-image --source=.` produces a container image, demonstrating image build works independently
- CLI: `mise run ci` without registry flag completes without attempting to push, demonstrating graceful skip

### Unit 4: GitHub Actions Thin Workflow

**Purpose:** Replace existing GitHub Actions workflows with a single workflow that installs Mise and calls `mise run ci`. All logic lives in Dagger per Constitution Article 11.

**Functional Requirements:**

- A new `.github/workflows/ci.yml` workflow shall be created that:
  - Triggers on push to `main` and on pull requests
  - Uses `jdx/mise-action@v3` to install Mise and project tools
  - Runs `mise run ci` as the only build step
  - Uploads JaCoCo coverage reports as artifacts
- The existing `.github/workflows/e2e-tests.yml` shall be removed (E2E tests can be added as a Dagger function later)
- The existing `.github/workflows/performance-tests.yml` shall be removed (perf tests can be added as a Dagger function later)
- The workflow YAML shall contain no build logic, test commands, or deployment steps — only Mise/Dagger invocation

**Proof Artifacts:**

- Diff: `.github/workflows/ci.yml` contains only checkout → mise-action → `mise run ci`, demonstrating thin wrapper pattern
- Diff: `e2e-tests.yml` and `performance-tests.yml` are deleted, demonstrating old workflows are removed

## Non-Goals (Out of Scope)

1. **ECR repository creation** — Covered in Spec 13 (OpenTofu Foundation)
2. **CD/deployment pipeline** — Covered in Spec 14 (CD Pipeline)
3. **Security scanning (Grype)** — Covered in Spec 16 (Security Scanning)
4. **E2E tests in Dagger** — The E2E Playwright tests require a browser; integrating them into Dagger is deferred. The old workflow is removed but E2E will be re-added in a future spec.
5. **Performance tests in Dagger** — JMeter integration is deferred similarly.
6. **Tilt removal** — The Tiltfile stays for now; `mise run dev` provides an alternative path. Full Tilt removal is Spec 17.
7. **Pre-commit hook changes** — Pre-commit Maven test hook stays as-is (belt and suspenders).

## Design Considerations

No specific design requirements identified. This is infrastructure/tooling work with no UI impact.

## Repository Standards

- Follow conventional commits: `feat(ci): ...` for CI pipeline code, `chore(ci): ...` for config
- Dagger module in `dagger/` directory following Dagger conventions
- `.mise.toml` in project root
- GitHub Actions workflows in `.github/workflows/`
- Follow Constitution Article 11 (Mise + Dagger CI/CD) — this spec implements it
- Pre-commit hooks remain active; all commits must pass existing checks

## Technical Considerations

- **Dagger Go SDK**: Initialize with `dagger init --sdk=go --name=ci --source=dagger`. The module creates Go code in `dagger/` with `main.go` containing pipeline functions.
- **Dagger + Podman**: Dagger requires a container runtime. On this system, Podman is available. Dagger may need `DOCKER_HOST` pointed at the Podman socket (`unix:///run/user/$(id -u)/podman/podman.sock`) or `podman system service` running.
- **JaCoCo branch coverage**: The `jacoco:check` Maven goal can enforce branch coverage. Alternatively, the Dagger pipeline can parse the JaCoCo XML report (`target/site/jacoco/jacoco.xml`) to extract branch coverage percentages. The XML approach gives more control over reporting.
- **Mise tool backends**: Java can be installed via `mise use java@corretto-17` (Amazon Corretto) or `mise use java@temurin-17`. Maven is available as `maven` backend. Dagger as `ubi:dagger`.
- **GitHub Actions + Mise**: The `jdx/mise-action@v3` handles Mise installation and tool caching in GHA. It reads `.mise.toml` automatically.
- **Dagger in GHA**: Dagger needs a container runtime in GHA. Ubuntu runners have Docker pre-installed, which Dagger uses by default. No special configuration needed for GHA runners.
- **Source directory passing**: Dagger functions receive the project source via `--source=.` which maps the current directory into the Dagger container. The `.containerignore` / `.dockerignore` apply to Dagger's context as well.

## Security Considerations

- **No secrets in Dagger code**: ECR credentials, AWS keys, and other secrets must be passed as Dagger function arguments or environment variables at runtime, never hardcoded.
- **GitHub Actions secrets**: The `ci.yml` workflow will eventually need AWS credentials for ECR push (Spec 13+). These will be injected via GitHub Actions secrets/OIDC, not stored in code.
- **Mise trust**: Running `mise trust` is required the first time to allow `.mise.toml` to execute tasks. Document this in the README.
- **Dagger Cloud**: Not used. All pipeline execution is local or on GHA runners. No telemetry or external services.

## Success Metrics

1. **`mise run ci` succeeds locally** — builds, tests, coverage report, image built
2. **`mise run ci` and `dagger call ci --source=.` produce identical results** — proving Mise is just a wrapper
3. **Coverage gate enforces 80% branch coverage** — pipeline fails if threshold not met
4. **GitHub Actions workflow is under 20 lines** of YAML (excluding comments) — proving it's a thin wrapper
5. **All existing tests continue to pass** — no regressions from pipeline changes
6. **New contributor can go from clone to running tests** with `mise install && mise run test`

## Open Questions

1. Exact Mise backend for Java 17 — need to verify whether `java@corretto-17` or `java@temurin-17` is the correct syntax. Will resolve during implementation.
2. Dagger + Podman socket configuration — may need `DOCKER_HOST` env var or podman service running. Will test during implementation.
