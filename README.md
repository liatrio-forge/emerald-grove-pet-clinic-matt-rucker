# Emerald Grove Veterinary Clinic

A comprehensive veterinary clinic management system built with Spring Boot. This application demonstrates modern Java web development practices and serves as a reference implementation for enterprise-grade applications.

## Overview

The Emerald Grove Veterinary Clinic application manages the core operations of a veterinary clinic, including:

- **Owner Management**: Register and manage pet owners with contact information
- **Pet Management**: Track pets, their types, and medical records
- **Veterinarian Management**: Manage veterinary staff and their specialties
- **Appointment System**: Schedule and track veterinary visits
- **Medical Records**: Maintain comprehensive health records for pets

## Quick Start

### Prerequisites

- **[Mise](https://mise.jdx.dev/)** — tool version manager (installs Java, Node, Maven, Dagger, AWS CLI automatically)
- **[Podman](https://podman.io/)** — container runtime (used for CI pipeline and local dev)

After installing Mise, activate it in your shell (one-time setup):

```bash
# Fish
echo 'mise activate fish | source' >> ~/.config/fish/config.fish

# Bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc

# Zsh
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
```

Then restart your shell or source the config file.

### Setup

```bash
# Clone the repository
git clone https://github.com/liatrio-forge/emerald-grove-pet-clinic-matt-rucker.git
cd emerald-grove-pet-clinic-matt-rucker

# Install all required tools (Java 17, Node 20, Maven, Dagger, AWS CLI, OpenTofu)
mise install

# Trust the project config (first time only)
mise trust

# Run the application
mise run dev
```

Access the application at `http://localhost:8080`

### Database Options

- **Default**: H2 in-memory database (auto-populated with sample data)
- **`mise run dev`**: PostgreSQL via Podman Compose (recommended for development)
- **MySQL**: `./mvnw spring-boot:run -Dspring-boot.run.profiles=mysql`

## Development Commands

All commands are defined in `.mise.toml` and run via `mise run <task>`.

| Command | Description |
|---|---|
| `mise run ci` | Run the full CI pipeline (build, test, coverage, image build) |
| `mise run test` | Run unit and integration tests |
| `mise run build` | Compile and package the application (skip tests) |
| `mise run format` | Apply Spring Java code formatting |
| `mise run lint` | Check formatting and code style (Checkstyle) |
| `mise run dev` | Start local dev environment (PostgreSQL + Spring Boot) |
| `mise run dev:down` | Stop local dev environment |

## CI/CD Pipeline

This project uses [Dagger](https://dagger.io/) for containerized, reproducible CI/CD pipelines and [Mise](https://mise.jdx.dev/) as the developer-facing task runner. All pipeline logic lives in Go code (`dagger/main.go`), not in CI system YAML. GitHub Actions serves only as a thin trigger.

### Running CI Locally

```bash
# Full pipeline: build → test → coverage gate (80% branch) → image build
mise run ci

# Or call Dagger directly (identical behavior)
dagger -m dagger call run --source=.
```

The pipeline runs inside containers, so results are identical whether you run locally or in CI. No "works on my machine" issues.

### Running Individual Steps

```bash
# Build only
dagger -m dagger call build --source=.

# Test only (with JaCoCo coverage)
dagger -m dagger call test --source=.

# Build container image only
dagger -m dagger call build-image --source=.

# Full pipeline with ECR push (requires AWS credentials)
dagger -m dagger call run --source=. --registry=<account>.dkr.ecr.<region>.amazonaws.com/<repo>
```

### How CI Works in GitHub Actions

On every push to `main` and on pull requests, the `.github/workflows/ci.yml` workflow runs:

1. Checks out the code
2. Installs Mise and all project tools (Java 17, Maven, Dagger)
3. Runs `mise run ci` — the same command you run locally
4. Uploads the JaCoCo coverage report as a workflow artifact

The workflow YAML contains zero build logic — it's 19 lines total. All intelligence lives in the Dagger pipeline.

### Coverage Gate

The pipeline enforces **80% branch coverage** via JaCoCo. Branch coverage measures whether all code paths through conditionals (if/else, switch, loops) are tested — a more meaningful metric than line coverage. If coverage drops below 80%, the pipeline fails.

### Architecture

```text
Developer (local)          GitHub Actions (CI)
       │                          │
  mise run ci                mise run ci
       │                          │
       └──── dagger call run ─────┘
                    │
            ┌───────┴────────┐
            │  Dagger Engine │
            │ (containerized)│
            └───────┬────────┘
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
     Build        Test      Image Build
   (Maven)    (JaCoCo)   (Containerfile)
```

## Documentation

- **[Development Guide](docs/DEVELOPMENT.md)** - Setup, testing, and contribution guidelines
- **[Architecture Guide](docs/ARCHITECTURE.md)** - System design and technical decisions
- **[Testing Guide](docs/TESTING.md)** - Comprehensive testing strategies and patterns
- **[E2E Tests (Playwright)](docs/TESTING.md#end-to-end-e2e-browser-tests-playwright)** - How to run browser-based end-to-end tests
- **[AWS Bootstrap Guide](docs/BOOTSTRAP.md)** - One-time AWS state backend setup
- **[Infrastructure Guide](infra/README.md)** - OpenTofu modules, environments, and deployment

## Development Standards

⚠️ **Important**: This project follows **Strict Test-Driven Development (TDD)** methodology. All feature implementations must follow the Red-Green-Refactor cycle:

1. **RED**: Write a failing test first
2. **GREEN**: Write minimum code to pass the test
3. **REFACTOR**: Improve code while maintaining tests

See the [Development Guide](docs/DEVELOPMENT.md) for detailed TDD requirements and development workflow.

## Technology Stack

- **Spring Boot (3.x)** - Modern Java application framework
- **Spring MVC** - Web layer with Thymeleaf templating
- **Spring Data JPA** - Data persistence layer
- **Hibernate** - ORM implementation
- **H2/MySQL/PostgreSQL** - Database options
- **Bootstrap 5** - Responsive UI framework

## Containerization

Build a production container image with Podman:

```bash
podman build -t emerald-grove-pet-clinic .
```

The `Containerfile` uses a multi-stage build (Maven/Corretto 17 → Chainguard distroless JRE) producing a minimal, non-root, shell-less production image. See [Spec 11](docs/specs/11-spec-production-containerization/11-spec-production-containerization.md) for details.

## Application Features

### Core Entities

- **Owners**: Pet owners with contact details and address information
- **Pets**: Individual pets with type, birth date, and medical history
- **Vets**: Veterinary staff with specialties and contact information
- **Visits**: Appointment records with examination details
- **Specialties**: Medical specialties (Radiology, Surgery, Dentistry)

### Key Functionality

- **Owner Registration**: Add and edit pet owner information
- **Pet Management**: Register pets, track medical history
- **Veterinarian Directory**: Browse vet profiles and specialties
- **Visit Scheduling**: Book and manage veterinary appointments
- **Medical Records**: Track treatments, diagnoses, and medications

### User Interface

- **Responsive Design**: Mobile-friendly interface using Bootstrap 5
- **Intuitive Navigation**: Easy access to all major functions
- **Search & Filter**: Find owners, pets, and vets quickly
- **Form Validation**: Client-side and server-side input validation

## Configuration

### Environment Variables

Override configuration using environment variables:

```bash
export SPRING_PROFILES_ACTIVE=mysql
export SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/petclinic
```

### Key Configuration Files

- `application.properties` - Main application configuration
- `application-{profile}.properties` - Database-specific settings

## License

This application is released under version 2.0 of the [Apache License](https://www.apache.org/licenses/LICENSE-2.0).

## Origin

This repository was initially created from https://github.com/spring-projects/spring-petclinic
