# 02 Questions Round 1 - No Direct Commits to Main

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. Protected Branch Names

Should the hook protect only the `main` branch, or also other branches like `master` or `develop`?

- [x] (A) Only `main` -- this is the project's default branch and the only one that needs protection
- [ ] (B) Both `main` and `master` for maximum compatibility
- [ ] (C) Configurable list of protected branches
- [ ] (D) Other (describe)

**Auto-answer rationale:** The repository uses `main` as its default branch (confirmed via git status). Protecting only `main` keeps the hook simple and focused. If `master` or other branches need protection later, it's a trivial addition.

## 2. Error Message Content

What information should the error message include when a developer tries to commit directly to main?

- [x] (A) Simple message: branch name is protected, create a feature branch instead
- [ ] (B) Detailed message with instructions on how to create a feature branch
- [ ] (C) Include a link to the contributing guide or workflow documentation
- [ ] (D) Other (describe)

**Auto-answer rationale:** A concise, actionable error message is sufficient. Developers working on this project are expected to know Git branching basics. The initial idea already includes a clear message: "Direct commits to main are not allowed. Please create a feature branch."

## 3. Bypass Mechanism

Should there be an officially documented way to bypass this hook for exceptional cases (e.g., hotfixes, initial setup)?

- [x] (A) No special bypass -- developers can use `git commit --no-verify` if absolutely needed (standard pre-commit escape hatch)
- [ ] (B) Add an environment variable (e.g., `ALLOW_MAIN_COMMIT=1`) to bypass
- [ ] (C) Document `--no-verify` as the official bypass mechanism
- [ ] (D) Other (describe)

**Auto-answer rationale:** The standard `--no-verify` flag already exists as a pre-commit bypass. Adding a custom env var is over-engineering for this use case. The docs/PRECOMMIT.md already documents `--no-verify` as a general hook skip mechanism.

## 4. Hook Placement Within Config

Where in the `.pre-commit-config.yaml` should the new hook be placed?

- [x] (A) Add it to the existing `repo: local` section alongside the Maven compile check
- [ ] (B) Create a new separate `repo: local` section for branch protection hooks
- [ ] (C) Place it at the top of the file as the first hook (since it's a gate check)
- [ ] (D) Other (describe)

**Auto-answer rationale:** Adding to the existing `repo: local` section (lines 69-77) is the cleanest approach. It avoids duplicating `repo: local` entries and keeps all local hooks together. The `fail_fast: false` setting means hook ordering doesn't affect whether other hooks run.

## 5. Documentation Updates

Which documentation files should be updated to reflect the new hook?

- [x] (A) Only `docs/PRECOMMIT.md` -- add a section describing the branch protection hook
- [ ] (B) Both `docs/PRECOMMIT.md` and `CLAUDE.md` / `AGENTS.md`
- [ ] (C) All documentation files that reference pre-commit hooks
- [ ] (D) Other (describe)

**Auto-answer rationale:** `docs/PRECOMMIT.md` is the primary documentation for pre-commit hooks (referenced in CLAUDE.md via `@docs/PRECOMMIT.md`). Updating it is sufficient since CLAUDE.md already imports it. No changes to CLAUDE.md or AGENTS.md are needed unless the hook introduces new workflow requirements for AI agents.

## 6. CI Considerations

Should the hook be skipped in CI environments (where pre-commit.ci runs)?

- [x] (A) No special CI handling needed -- the hook checks the branch name, which is correct in CI contexts. If CI commits to main directly, that's intentional (merge commits from PRs).
- [ ] (B) Add the hook to the `ci: skip` list to avoid blocking CI pipelines
- [ ] (C) Other (describe)

**Auto-answer rationale:** The `ci` section in `.pre-commit-config.yaml` has an empty `skip: []` list. The branch protection hook uses `git symbolic-ref --short HEAD` which may not resolve in CI detached-HEAD contexts (it would return non-zero, causing the branch variable to be empty, which means the check passes). This is safe default behavior -- no CI changes needed.
