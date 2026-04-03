---
name: analyze
description: Cross-artifact consistency analysis. Compares spec vs tasks vs tests to detect misalignments. Quality gate between SDD Stage 2 (Tasks) and Stage 3 (Execute).
---

# Cross-Artifact Analysis

You perform consistency analysis across all SDD artifacts for a feature. This is a quality gate that must pass before implementation begins.

Inspired by [GitHub Spec Kit's `/speckit.analyze` command](https://github.com/github/spec-kit).

## When to Run

After `/SDD-2-generate-task-list-from-spec` completes and before `/SDD-3-manage-tasks` begins.

## Workflow

### Step 1: Locate Artifacts

Find the relevant files in `docs/specs/`:

- Spec file: `[NN]-spec-[feature].md`
- Task file: `[NN]-tasks-[feature].md`
- Constitution: `docs/constitution.md`

### Step 2: Spec → Tasks Coverage

For every requirement and acceptance criterion in the spec:

- [ ] Is there a corresponding task in the task breakdown?
- [ ] Does the task's completion criteria align with the spec requirement?
- [ ] Are there tasks that don't map to any spec requirement? (scope creep)

Report:

```markdown
## Spec → Tasks Coverage
| Spec Requirement | Mapped Task(s) | Status |
|---|---|---|
| [requirement] | [task IDs] | COVERED / MISSING / PARTIAL |
```

### Step 3: Tasks → Tests Readiness

For every task in the breakdown:

- [ ] Is the acceptance criterion clear enough to write a test?
- [ ] Are the completion criteria specific and testable?
- [ ] Are there implicit behaviors that should be explicit?

### Step 4: Constitution Compliance

Check the task breakdown against each constitutional article:

- [ ] **Test-First** (Art. 1): Tasks are structured to allow test-first development
- [ ] **Library-First** (Art. 2): No custom implementations where libraries exist
- [ ] **Simplicity** (Art. 3): No speculative features in the task list
- [ ] **Anti-Abstraction** (Art. 4): No premature abstractions planned
- [ ] **Integration-First** (Art. 5): Test strategy favors integration tests
- [ ] **Proof Artifacts** (Art. 6): Each task has defined proof artifacts
- [ ] **Single-Threaded** (Art. 8): Tasks are ordered for sequential execution of demoable slices
- [ ] **Frontend Visual Compliance** (Art. 10): If the spec includes visual changes (templates, CSS, UI), verify: (a) tasks reference the project style guide (`docs/STYLE_GUIDE.md`) — if no style guide exists, flag as FAIL and recommend prompting the user to create one, (b) tasks include a `web-design-guidelines` review step, (c) tasks include a `frontend-design` skill usage step for new components, (d) proof artifacts include visual verification (screenshots or Playwright visual tests)

### Step 5: Context Health Check

Run the `context-check` skill inline to verify the AI has not lost its SDD stage instructions:

- [ ] Expected SDD stage marker is present in recent responses
- [ ] Workflow rules are being followed (not skipping steps)
- [ ] No signs of topic drift or constitution violations
- [ ] If degradation detected: report it in the analysis and recommend re-anchoring before proceeding to implementation

Report:

```markdown
## Context Health
- Expected stage: SDD2 → SDD3 transition
- Marker present: YES / NO
- Workflow adherence: YES / PARTIAL / NO
- Recommendation: HEALTHY / DEGRADED (re-invoke stage) / LOST (new conversation)
```

### Step 6: Unresolved Markers

Scan all artifacts for:

- `[NEEDS CLARIFICATION]` tags — list each one with its location
- `[TBD]` or `[TODO]` markers
- Ambiguous language ("might", "could", "possibly", "optionally")

### Step 7: Generate Report

```markdown
# Cross-Artifact Analysis: [Feature Name]

## Summary
- Spec requirements: [N]
- Tasks: [N]
- Coverage: [N/N] ([%])
- Unresolved markers: [N]
- Constitution violations: [N]

## Verdict: PASS / FAIL

## Details
[coverage table, violations, unresolved markers]
```

## Gate Rules

**PASS** requires:

- 100% spec-to-task coverage (every requirement has a task)
- 0 unresolved `[NEEDS CLARIFICATION]` markers
- 0 constitution violations
- All acceptance criteria are testable

**FAIL** blocks implementation until issues are resolved.
