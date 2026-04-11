# 12 Questions Round 1 - Dagger CI Pipeline + Mise Setup

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. Dagger SDK Language

Which language should the Dagger pipeline be written in?

- [x] (A) Go — Dagger's native language, best docs and examples, most common in DevOps
- [ ] (B) TypeScript — familiar for frontend-oriented teams, good type safety
- [ ] (C) Python — simple syntax, good for scripting-heavy pipelines
- [ ] (D) Other (describe)

## 2. Pipeline Scope for This Spec

The roadmap says "build → test → coverage gate → image build → image push to ECR." ECR doesn't exist yet (Spec 13). What should this spec do about image push?

- [x] (A) Implement the full pipeline but make the ECR push step configurable/skippable — push fails gracefully if no ECR repo exists, works once Spec 13 provisions it

Note: The push step is a Dagger function that always exists in the code. It requires AWS/ECR credentials to succeed. Locally it skips gracefully when no credentials are present. In CI it runs with injected credentials once ECR exists (Spec 13). The pipeline is the same code regardless of trigger (Mise locally, GHA remotely).

## 3. Coverage Gate Threshold

JaCoCo is configured but has no threshold. What coverage gate should the pipeline enforce?

- [x] (D) Other: **Branch coverage at 80%** as the primary gate (ensures all code paths through conditionals are tested). Line coverage reported but not gated. JaCoCo `check` goal enforces the branch coverage minimum.

Note: User prefers branch coverage over line coverage as it measures meaningful decision points (if/else, switch, loops) rather than arbitrary line counts.

## 4. What Happens to Existing GitHub Actions Workflows?

There are two existing workflows: `e2e-tests.yml` and `performance-tests.yml`. How should we handle them?

- [x] (A) Replace both with a single unified Dagger-based workflow (`ci.yml` that calls `mise run ci`) — per Constitution Article 11, all pipeline logic must live in Dagger

## 5. Mise Tasks Scope

Beyond `ci`, what other Mise tasks should this spec define?

- [x] (C) Full set: `ci`, `test`, `build`, `format`, `lint`, `dev`, `dev:down` — complete developer experience. Also document usage in README.md.

## 6. Dagger Module Location

Where should the Dagger pipeline code live in the repo?

- [x] (B) `dagger/` directory in the project root — Dagger convention

## 7. Existing Pre-commit Maven Test Hook

The pre-commit config runs `./mvnw test` before every commit. The Dagger pipeline also runs tests. Should we change the pre-commit behavior?

- [x] (A) Keep pre-commit as-is — belt and suspenders, tests run both locally and in CI

## 8. Proof Artifacts

What would best demonstrate this spec is working?

- [x] (B) `mise run ci` succeeds locally (builds, tests pass, coverage reported, image built) + show that a code change with failing tests causes the pipeline to fail
