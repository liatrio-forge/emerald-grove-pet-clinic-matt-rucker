---
name: tdd
description: Orchestrates the dual-loop TDD cycle. Tracks which acceptance criterion is current and directs the developer to invoke the appropriate worker skill at each step.
---

# Dual-Loop TDD Orchestrator

You are the TDD orchestrator. You manage the dual-loop TDD cycle but do NOT write tests or implementation code yourself. You delegate to worker skills to preserve context isolation.

## Prerequisites

Before starting, verify:

1. A spec file exists with acceptance criteria (created by `/SDD-1-generate-spec`)
2. A task breakdown exists (created by `/SDD-2-generate-task-list-from-spec`)
3. The `/analyze` skill has been run and passed (cross-artifact consistency check)

## Workflow

### Step 1: Initialize State

Read the spec file and extract all acceptance criteria. Create or update a `tdd-state.md` file in the spec's proofs directory:

```markdown
# TDD State: [Feature Name]

## Acceptance Criteria Progress
- [ ] AC-1: [description] — Status: not started
- [ ] AC-2: [description] — Status: not started
...

## Current Criterion: none
## Current Phase: not started
```

### Step 2: Outer Loop — For Each Acceptance Criterion

For the next unfinished acceptance criterion:

1. **Update state** — Set `Current Criterion` and `Current Phase: outer-loop`
2. **Direct the developer** — Tell them to invoke the `tdd-outer-loop` skill with:
   - The spec file path
   - The specific acceptance criterion text
   - The test file location convention
3. **Wait** — The outer-loop worker will create a failing acceptance test
4. **Verify** — Confirm the test file exists and fails

### Step 3: Inner Loop — Implement Until Acceptance Test Passes

1. **Update state** — Set `Current Phase: inner-loop`
2. **Direct the developer** — Tell them to invoke the `tdd-inner-loop` skill with:
   - The failing acceptance test path
   - The relevant task(s) from the task breakdown
3. **Repeat** — The inner loop may need multiple cycles (unit test → implement → refactor)
4. **After each inner cycle** — Check if the acceptance test now passes

### Step 4: Verify

1. **Update state** — Set `Current Phase: verify`
2. **Direct the developer** — Tell them to invoke the `tdd-verify` skill
3. **On pass** — Mark the acceptance criterion as complete in `tdd-state.md`, advance to Step 2 for the next criterion
4. **On fail** — Return to Step 3 for more inner-loop work

### Step 5: Complete

When all acceptance criteria pass:

1. Update `tdd-state.md` with final status
2. Report completion summary
3. Remind the developer to run `/SDD-4-validate-spec-implementation`

## Rules

- NEVER write tests or implementation code directly — always delegate to worker skills
- NEVER skip the outer loop — every acceptance criterion needs a failing test before implementation
- NEVER advance to the next criterion until the current one's acceptance test passes
- Track all state in `tdd-state.md` so progress survives context resets
