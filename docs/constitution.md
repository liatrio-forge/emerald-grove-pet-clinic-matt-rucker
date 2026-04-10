# Project Constitution

> Immutable governance principles for all AI-assisted development on this project.
> Inspired by [GitHub Spec Kit's constitution concept](https://github.com/github/spec-kit).
> Amendments require documented rationale, maintainer review, and backwards-compatibility assessment.

---

## Article 1: Test-First Mandate

No implementation code shall be written without a failing test first.

- Acceptance tests are derived from spec acceptance criteria (outer loop)
- Unit tests are written before implementation code (inner loop)
- A test that passes on first run is suspect — verify it tests the right thing

## Article 2: Library-First

Use existing, maintained libraries before writing custom code.

- Search for established solutions before implementing from scratch
- Custom code is justified only when no suitable library exists or when the library introduces unacceptable complexity/risk
- Document the justification when choosing custom over library

## Article 3: Simplicity Gate

Every plan and implementation must pass a simplicity check.

- [ ] No speculative features — every feature traces to a concrete user story
- [ ] No "might need later" code
- [ ] The simplest approach that satisfies the requirement is preferred
- [ ] Three similar lines of code is better than a premature abstraction

## Article 4: Anti-Abstraction Gate

No abstraction until the third concrete use case.

- First occurrence: write it inline
- Second occurrence: note the duplication, leave it
- Third occurrence: now extract the abstraction
- Premature abstractions are harder to undo than duplication

## Article 5: Integration-First Testing

Prefer integration tests over mocks. Mocks are permitted only at true system boundaries.

- Test real behavior, not mocked behavior
- Mocks are acceptable for: external APIs, third-party services, time-dependent behavior
- Mocks are NOT acceptable for: internal modules, database access (use test databases), file system operations

## Article 6: Proof Artifact Requirement

Every completed task must produce committed, verifiable evidence.

- Proof artifacts include: test output, screenshots, CLI results, API responses
- "The AI said it works" is not a proof artifact

## Article 7: Uncertainty Markers

The AI must flag ambiguity — never guess.

- Use `[NEEDS CLARIFICATION]` tags whenever a requirement is ambiguous, incomplete, or has multiple valid interpretations
- All `[NEEDS CLARIFICATION]` markers must be resolved before implementation begins
- Guessing at requirements leads to rework; flagging leads to alignment

## Article 8: Single-Threaded Execution

Complete one demoable slice before starting the next.

- Each parent task (demoable unit) must be fully implemented, tested, and proved before advancing
- No parallel work on multiple features unless explicitly authorized
- Half-finished work creates more drag than sequential completion

## Article 9: Conventional Commits

All commits follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

- Format: `type(scope): description`
- Types: `feat`, `fix`, `test`, `docs`, `refactor`, `chore`, `ci`
- Each commit should be atomic — one logical change per commit

## Article 10: Frontend Visual Compliance

Any change with visual impact must follow frontend UI/UX best practices and adhere to the project style guide.

- Changes that modify templates, CSS, or any user-facing rendering must be reviewed against the project style guide (`docs/STYLE_GUIDE.md`)
- If no style guide exists, the AI must **pause implementation and prompt the user** to create one before proceeding. Guide the user through documenting: color palette, typography, spacing scale, component patterns, and interaction states
- Use the `web-design-guidelines` skill to audit visual changes for accessibility compliance (WCAG AA contrast, focus-visible states, semantic HTML)
- Use the `frontend-design` skill when building new UI components
- Visual changes without a style guide reference or design review are not considered complete
- "It compiles and the tests pass" is not sufficient for frontend work — visual correctness must be verified

## Article 11: Mise + Dagger CI/CD

All CI/CD pipeline logic must live in Dagger pipelines, invoked through Mise tasks. External CI systems (GitHub Actions, etc.) serve only as triggers.

- **Mise** is the developer-facing entry point for all project commands (`mise run ci`, `mise run dev`, `mise run deploy:staging`)
- **Mise** manages tool versions (Java, Node, Maven, Dagger) and environment variables via `.mise.toml` — no system-level dependencies required beyond Mise itself
- **Dagger** implements containerized pipeline steps (build, test, scan, image build, deploy) as functions
- **Podman** is the container runtime — no Docker dependency. Rootless by default.
- CI system workflows must be thin wrappers: checkout → install Mise → `mise run ci`
- No build logic, test orchestration, or deployment steps in CI system YAML/config
- Pipelines must produce identical results locally and in CI
- This ensures CI/CD is portable, testable, and not locked to any single CI platform or container runtime

## Article 12: Infrastructure as Code

All cloud infrastructure must be defined in code using OpenTofu. No manual resource creation via console or CLI.

- Infrastructure changes follow the same review process as application code (PR-based)
- State must be stored remotely with locking (S3 + DynamoDB)
- Environments are parameterized via variable files, not duplicated modules
- Secrets and credentials must never appear in IaC files — use AWS Secrets Manager or SSM Parameter Store
