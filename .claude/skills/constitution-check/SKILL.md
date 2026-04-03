---
name: constitution-check
description: Validates any plan or implementation against the project constitution. Reports pass/fail per gate with justification.
---

# Constitution Compliance Check

You validate a plan, task breakdown, or implementation against the project constitution (`docs/constitution.md`).

## Workflow

### Step 1: Read the Constitution

Load `docs/constitution.md` and extract all 9 articles.

### Step 2: Read the Target

Read the file(s) being validated (plan, task breakdown, or code changes).

### Step 3: Evaluate Each Gate

For each constitutional article, evaluate compliance:

```markdown
## Constitution Compliance Report

### Article 1: Test-First Mandate
- Status: PASS / FAIL / N/A
- Evidence: [what you observed]
- Justification: [why it passes or fails]

### Article 2: Library-First
- Status: PASS / FAIL / N/A
- Evidence: [what you observed]
- Justification: [why it passes or fails]

### Article 3: Simplicity Gate
- Status: PASS / FAIL / N/A
- Evidence: [what you observed]
- Justification: [why it passes or fails]

### Article 4: Anti-Abstraction Gate
- Status: PASS / FAIL / N/A
- Evidence: [what you observed]
- Justification: [why it passes or fails]

### Article 5: Integration-First Testing
- Status: PASS / FAIL / N/A
- Evidence: [what you observed]
- Justification: [why it passes or fails]

### Article 6: Proof Artifact Requirement
- Status: PASS / FAIL / N/A
- Evidence: [what you observed]
- Justification: [why it passes or fails]

### Article 7: Uncertainty Markers
- Status: PASS / FAIL / N/A
- Evidence: [what you observed]
- Justification: [why it passes or fails]

### Article 8: Single-Threaded Execution
- Status: PASS / FAIL / N/A
- Evidence: [what you observed]
- Justification: [why it passes or fails]

### Article 9: Conventional Commits
- Status: PASS / FAIL / N/A
- Evidence: [what you observed]
- Justification: [why it passes or fails]

### Article 10: Frontend Visual Compliance
- Status: PASS / FAIL / N/A
- Evidence: [what you observed — does the change have visual impact? is there a style guide? was web-design-guidelines used?]
- Justification: [why it passes or fails. If no style guide exists and the change is visual, this MUST FAIL with recommendation to create docs/STYLE_GUIDE.md]
```

### Step 4: Verdict

- **PASS**: All applicable articles pass
- **FAIL**: One or more articles fail — list violations and recommended fixes

## Rules

- N/A is acceptable when an article doesn't apply to the target (e.g., Article 9 doesn't apply to a plan)
- Be specific in evidence — cite file paths, line numbers, or specific decisions
- A FAIL verdict should include actionable remediation steps
