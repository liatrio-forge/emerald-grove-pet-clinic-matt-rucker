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

- **[Mise](https://mise.jdx.dev/)** — tool version manager (installs Java, Node, Maven, Dagger automatically)
- **[Podman](https://podman.io/)** — container runtime (used for CI pipeline and local dev)

### Setup

```bash
# Clone the repository
git clone https://github.com/liatrio-forge/emerald-grove-pet-clinic-matt-rucker.git
cd emerald-grove-pet-clinic-matt-rucker

# Install all required tools (Java 17, Node 20, Maven, Dagger)
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

The CI pipeline uses [Dagger](https://dagger.io/) for containerized, reproducible builds.
Running `mise run ci` locally produces identical results to the GitHub Actions CI workflow.

## Documentation

- **[Development Guide](docs/DEVELOPMENT.md)** - Setup, testing, and contribution guidelines
- **[Architecture Guide](docs/ARCHITECTURE.md)** - System design and technical decisions
- **[Testing Guide](docs/TESTING.md)** - Comprehensive testing strategies and patterns
- **[E2E Tests (Playwright)](docs/TESTING.md#end-to-end-e2e-browser-tests-playwright)** - How to run browser-based end-to-end tests

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

Build a Docker container image:

```bash
./mvnw spring-boot:build-image
```

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
