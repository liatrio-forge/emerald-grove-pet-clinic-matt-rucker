# 02-spec-no-direct-commits-to-main

## Introduction/Overview

This feature adds a pre-commit hook that prevents direct commits to the `main` branch, enforcing a branch-based workflow where all changes reach `main` only through pull requests. The hook leverages the project's existing pre-commit framework infrastructure, making it automatically shared with the entire team via the tracked `.pre-commit-config.yaml` file.

## Goals

- Prevent accidental direct commits to the `main` branch by catching them at commit time (before the commit is created)
- Enforce a pull-request-based workflow for all changes to `main`
- Leverage the existing pre-commit infrastructure without introducing new tooling or dependencies
- Provide a clear, actionable error message when a developer attempts to commit directly to `main`
- Document the new hook in the project's pre-commit documentation

## User Stories

**As a developer**, I want to be prevented from accidentally committing directly to `main` so that all changes go through the pull request review process.

**As a team lead**, I want the branch protection enforced locally (at commit time) so that mistakes are caught before they ever reach the remote repository.

**As a new team member**, I want a clear error message when I try to commit to `main` so that I understand the workflow expectation and know to create a feature branch.

## Demoable Units of Work

### Unit 1: Pre-commit Hook Implementation

**Purpose:** Add the branch protection hook to `.pre-commit-config.yaml` so that commits to `main` are blocked at the pre-commit stage. This is the core deliverable that enforces the workflow.

**Functional Requirements:**

- The system shall include a new local hook entry in `.pre-commit-config.yaml` with `id: no-direct-commits-to-main`
- The hook shall detect the current branch name using `git symbolic-ref --short HEAD`
- The hook shall exit with a non-zero status code and display an error message when the current branch is `main`
- The hook shall exit with status code 0 (success) when the current branch is any branch other than `main`
- The hook shall gracefully handle detached HEAD states (where `git symbolic-ref` fails) by allowing the commit to proceed
- The hook shall run with `always_run: true` and `pass_filenames: false` so it fires on every commit regardless of staged files
- The hook shall use `language: system` to avoid requiring any additional runtime dependencies
- The hook entry shall be added to the existing `repo: local` section in `.pre-commit-config.yaml`, alongside the Maven compile check

**Proof Artifacts:**

- CLI output: Attempting `git commit` on `main` branch shows the error message and the commit is rejected
- CLI output: Attempting `git commit` on a feature branch succeeds (hook passes)
- File diff: `.pre-commit-config.yaml` shows the new hook entry in the `repo: local` section

### Unit 2: Documentation Update

**Purpose:** Update `docs/PRECOMMIT.md` to document the new branch protection hook, so that developers understand its purpose and behavior.

**Functional Requirements:**

- The documentation shall include a description of the `no-direct-commits-to-main` hook in the "Available Hooks" section under an appropriate subsection (e.g., "Branch Protection")
- The documentation shall explain why the hook exists (enforcing PR-based workflow)
- The documentation shall note that the standard `--no-verify` flag can bypass the hook in exceptional cases
- The documentation shall be consistent with the existing documentation style and formatting in `docs/PRECOMMIT.md`

**Proof Artifacts:**

- File diff: `docs/PRECOMMIT.md` shows the new documentation section for the branch protection hook
- Markdown lint: `pre-commit run markdownlint --files docs/PRECOMMIT.md` passes without errors

## Non-Goals (Out of Scope)

1. **Server-side branch protection:** This spec only covers local pre-commit enforcement. GitHub branch protection rules are a separate concern.
2. **Protecting branches other than `main`:** Only `main` is protected. If `master`, `develop`, or other branches need protection, that can be added in a future iteration.
3. **Custom bypass mechanisms:** No environment variable or configuration-based bypass is provided. The standard `git commit --no-verify` is sufficient for exceptional cases.
4. **Pre-push hook:** The hook runs at pre-commit time, not pre-push. This catches errors earlier (before the commit exists locally).
5. **Changes to CI configuration:** The existing `ci` section in `.pre-commit-config.yaml` does not need modification. The hook handles detached HEAD states gracefully.

## Design Considerations

No specific design requirements identified. This is a developer tooling change with no UI impact.

## Repository Standards

- **Pre-commit configuration:** Follow the existing patterns in `.pre-commit-config.yaml` -- each hook has `id`, `name`, `entry`, `language`, `pass_filenames`, and `description` fields matching the style of the existing `maven-compile-check` hook (lines 69-77)
- **Documentation style:** Follow the existing style in `docs/PRECOMMIT.md` -- use heading hierarchy, code blocks for commands, and descriptive prose consistent with the current sections
- **Markdown linting:** All Markdown changes must pass `markdownlint` with the project's `.markdownlint.yaml` configuration
- **Commit conventions:** Use conventional commits (e.g., `feat:` or `chore:`) as established in the repository

## Technical Considerations

- **Hook entry point:** The hook uses inline bash via the `entry` field rather than a separate script file. This keeps the implementation self-contained in `.pre-commit-config.yaml` and avoids creating additional files.
- **`git symbolic-ref` behavior:** In detached HEAD states (common in CI), `git symbolic-ref --short HEAD` returns a non-zero exit code. The hook script uses `2>/dev/null` to suppress the error and the branch variable will be empty, causing the `main` check to be false -- so the hook passes. This is the desired behavior.
- **`always_run: true`:** This ensures the hook fires on every commit, regardless of which files are staged. Without this, pre-commit would only run the hook when files matching the `files` pattern are staged, which is not applicable for a branch check.
- **`pass_filenames: false`:** Since the hook doesn't inspect file contents, it should not receive filenames as arguments.
- **Placement in `repo: local`:** The new hook is added to the existing `repo: local` section. Pre-commit allows multiple hooks under a single `repo: local` entry.
- **`stages` field:** No explicit `stages` field is needed because the `default_stages: [pre-commit]` setting (line 80) applies to all hooks without an explicit stage.

## Security Considerations

No specific security considerations identified. The hook is a read-only check that inspects the current branch name and does not handle any sensitive data.

## Success Metrics

1. **Prevention rate:** 100% of direct commit attempts to `main` are blocked when the pre-commit hook is installed
2. **False positive rate:** 0% -- commits on non-`main` branches are never blocked by this hook
3. **CI compatibility:** The hook does not cause failures in CI environments running in detached HEAD mode
4. **Documentation completeness:** The new hook is documented in `docs/PRECOMMIT.md` and passes markdown lint checks

## Open Questions

No open questions at this time. The feature scope is well-defined and all clarifying questions have been resolved.
