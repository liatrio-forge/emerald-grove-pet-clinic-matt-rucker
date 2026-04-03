# AI Agent Development Guide — Emerald Grove Veterinary Clinic

This document provides guidance for AI agents working on this Spring Boot web application. Sections marked **(Claude-specific)** apply only to Claude Code.

## Context Marker (Claude-specific)

Always begin your response with all active emoji markers, in the order they were introduced.

Format:  "<marker1><marker2><marker3>\n<response>"

The marker for this instruction is: 🤖

## Mandatory Governance

**Read and comply with [`docs/constitution.md`](docs/constitution.md) before any implementation work.**
The constitution defines immutable principles: test-first, library-first, simplicity, anti-abstraction, integration-first testing, proof artifacts, uncertainty markers, single-threaded execution, and conventional commits.

## Mandatory Development Workflow: Spec-Driven Development (SDD)

**All code changes must follow the Spec-Driven Development workflow. No exceptions.**

1. **`/SDD-1-generate-spec`** — Generate specification with clarifying Q&A
2. **`/SDD-2-generate-task-list-from-spec`** — Break spec into demoable tasks
3. **`/analyze`** — Cross-artifact consistency check (quality gate before implementation)
4. **`/SDD-3-manage-tasks`** — Execute tasks with dual-loop TDD
5. **`/SDD-4-validate-spec-implementation`** — Validate implementation against spec

The scope assessment in SDD-1 determines the appropriate level of detail (a CSS fix will have a simpler spec than a new feature), but **the stages must not be skipped**. Even bug fixes and "small" changes go through the workflow — the workflow protects against the kind of broken implementations that result from skipping design review and testing steps.

**Available skills** (see `.claude/skills/`): `tdd`, `tdd-outer-loop`, `tdd-inner-loop`, `tdd-verify`, `analyze`, `constitution-check`, `context-check`

## Project Overview

- **Framework**: Spring Boot 4.0 (Spring MVC, Spring Data JPA, Thymeleaf)
- **Database**: H2 (default), MySQL, PostgreSQL via Spring profiles
- **Build**: Maven (primary), Gradle (secondary)
- **Testing**: JUnit 5, Mockito, TestContainers, JaCoCo, Playwright (E2E)

## Documentation

- @docs/DEVELOPMENT.md — **[Development Guide](docs/DEVELOPMENT.md)** - TDD workflow, setup, and development process
- @docs/TESTING.md — **[Testing Guide](docs/TESTING.md)** - Testing strategies, patterns, and TDD implementation
- @docs/ARCHITECTURE.md — **[Architecture Guide](docs/ARCHITECTURE.md)** - System design and technical decisions
- @docs/PRECOMMIT.md — **[Pre-commit Guide](docs/PRECOMMIT.md)** - Hook configuration, usage, and troubleshooting
- @docs/constitution.md — **[Constitution](docs/constitution.md)** - Immutable governance principles
- @docs/STYLE_GUIDE.md — **[Style Guide](docs/STYLE_GUIDE.md)** - Visual design system (colors, typography, components)

## TDD Requirements

All feature implementations must follow **Strict Test-Driven Development (TDD)**:

### Dual-Loop TDD

- **Outer loop**: Convert acceptance criteria into failing acceptance/integration tests. The test writer must NOT see implementation plans (context isolation).
- **Inner loop**: Red-Green-Refactor at the unit level. Write a failing unit test → minimal code to pass → refactor.
- **Verify**: Run the full test suite after the inner loop completes. All tests must pass before advancing.

### Coverage Requirements

- **Minimum 90% line coverage** for new code
- **100% branch coverage** for critical business logic
- All edge cases must be explicitly tested

### Test Organization

- Follow **Arrange-Act-Assert** pattern
- Use descriptive test method names that document behavior
- Tests must be **fast, isolated, and repeatable**

## Branching Strategy: Trunk-Based Development

- **Never commit directly to `main`** — `main` requires PRs
- Use **short-lived feature branches** named by convention:
  - `feat/<feature-name>` — new features
  - `fix/<bug-name>` — bug fixes
  - `docs/<topic>` — documentation changes
  - `chore/<task>` — maintenance/tooling
- Branches should be **short-lived** (hours to days, not weeks)
- **Delete branches** after merge

## Coding Standards

### Architecture

- **Layered Architecture**: Presentation → Business → Data layers
- **Spring Boot Best Practices**: Use starters, follow conventions
- **Clean Code**: SOLID principles, DRY, single responsibility

### Database

- **Spring Data JPA** for data access
- **Proper entity relationships** with appropriate cascade settings
- **DTOs** for data transfer between layers

### Commits

- Use conventional commits: `type(scope): description`
- Use `[NEEDS CLARIFICATION]` tags for ambiguous requirements — never guess
- Ask before installing new tools or dependencies

## Definition of Done

A feature is not complete unless ALL of the following are true:

### Validation Completeness

- Every user-facing form input must have **server-side validation** before the feature is considered done
- Validation error messages must be user-friendly and specific (not raw exceptions)
- Edge cases (empty, null, too long, invalid format) must be covered

### Error Handling

- All user-facing endpoints must handle not-found and invalid states with **friendly error pages**, never raw exceptions or stack traces
- Use `@ControllerAdvice` or per-controller exception handlers as appropriate

### Pagination & Filtering Contract

- Any list endpoint that supports filtering or search **must preserve query parameters across pagination links** from day one — this is not a follow-up task, it is part of the feature
- New filter parameters must be included in pagination URLs

### Frontend Quality

- UI changes must follow accessibility best practices
- Test responsive behavior at standard breakpoints

## UI & Frontend Work (Claude-specific)

- Use the **frontend-design** skill for building UI components and pages
- Use the **web-design-guidelines** skill to review UI for accessibility and design compliance
- For automated E2E testing, use **Playwright** (see `e2e-tests/`)
- Never use embedded/preview browsers for UI verification — they produce misleading results
- For visual verification, use headed Playwright: `npm run test:headed` from `e2e-tests/`

## Database Access (Claude-specific)

- Use **dbhub** (Bytebase MCP server) to query the database during development and testing
- Default database is H2 in-memory; connection details are in `application.properties`

## Tools and Frameworks

- **Testing**: JUnit 5, Mockito, TestContainers, JaCoCo, JMeter, Playwright
- **Build**: Maven (primary), Gradle (secondary)
- **Quality**: Checkstyle, SpotBugs, SonarQube
- **Database**: dbhub for direct DB querying during development (Claude-specific)
- **Version Control**: Git with conventional commits
- **Pre-commit**: Hooks installed via `pre-commit` (see `docs/PRECOMMIT.md`)

## Review Checklist

Before committing code:

- [ ] Tests written before implementation (outer loop first, then inner loop)
- [ ] All tests pass (`./mvnw test`)
- [ ] Code coverage meets requirements (>90%)
- [ ] Follows SOLID principles
- [ ] No code duplication
- [ ] Proper error handling (friendly pages, no stack traces)
- [ ] All form inputs have server-side validation
- [ ] Pagination preserves filter/search params
- [ ] UI reviewed with web-design-guidelines skill (Claude-specific)
- [ ] Commit message follows conventional commits
- [ ] Branch is not `main`
- [ ] `[NEEDS CLARIFICATION]` markers are resolved
