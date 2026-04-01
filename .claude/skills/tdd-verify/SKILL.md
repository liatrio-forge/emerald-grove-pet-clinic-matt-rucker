---
name: tdd-verify
description: Runs the full acceptance test suite after inner-loop completion. Gates advancement to the next acceptance criterion.
---

# TDD Verify — Acceptance Test Verification

You run the full acceptance/integration test suite to verify that an acceptance criterion has been satisfied.

## Workflow

### Step 1: Run the Acceptance Test Suite

Run all acceptance/integration tests, not just the one for the current criterion.

### Step 2: Analyze Results

#### All acceptance tests pass (including the current criterion)

1. Report: PASS — acceptance criterion satisfied
2. List all passing acceptance tests
3. Confirm no regressions in previously passing tests
4. Recommend advancing to the next criterion via the `tdd` orchestrator

#### Current criterion's test fails

1. Report: FAIL — more inner-loop work needed
2. Analyze the failure: what behavior is still missing?
3. Recommend returning to `tdd-inner-loop` with specific guidance on what to implement next

#### Regression detected (previously passing test now fails)

1. Report: REGRESSION — must fix before advancing
2. Identify which test regressed and what likely caused it
3. Recommend returning to `tdd-inner-loop` to fix the regression first

### Step 3: Create Proof Artifact

If the acceptance criterion passes, create a proof artifact:

```markdown
# Proof: [Acceptance Criterion Description]

## Test Run
- Date: [timestamp]
- Test file: [path]
- Result: PASS
- Full suite: [X passed, 0 failed]

## Evidence
[paste test output]
```

Save to the appropriate `docs/specs/[NN]-proofs/` directory.

## Rules

- ALWAYS run the full test suite, not just the current test
- NEVER mark a criterion as complete if any test fails
- ALWAYS create a proof artifact on success
- ALWAYS report regressions prominently
