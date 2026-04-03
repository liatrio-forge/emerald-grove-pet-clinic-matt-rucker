# SDD Workflow Customization Analysis

> Why the stock Spec-Driven Development workflow is insufficient for AI-assisted development, and what our customizations add.

## Executive Summary

The stock [liatrio-labs/spec-driven-workflow](https://github.com/liatrio-labs/spec-driven-workflow) provides four prompt files (SDD-1 through SDD-4) that describe a structured development process. However, prompts are **suggestions** — they rely on the AI choosing to follow them. Through real-world use on this project, we observed multiple failure modes where the AI ignored documented instructions, skipped steps, or produced broken output despite having clear guidance in CLAUDE.md, DEVELOPMENT.md, and ARCHITECTURE.md.

Our customizations add **enforcement layers** that structurally prevent these failures. This document catalogs each customization, the failure mode it addresses, and evidence from this project's development history.

---

## The Core Problem: AI Ignores Documentation

### Observed Behavior

AI coding assistants (including Claude) routinely ignore instructions written in documentation files. During this project, the following files contained explicit instructions that were ignored at various points:

- **CLAUDE.md** — Contained TDD requirements, coding standards, and review checklists
- **DEVELOPMENT.md** — Contained Red-Green-Refactor workflow, quality gates, and coverage requirements
- **ARCHITECTURE.md** — Contained layered architecture patterns and design decisions
- **constitution.md** — Contained immutable governance principles

### Why This Happens

1. **Context window pressure**: In long conversations, earlier instructions get compressed or dropped. The AI literally forgets what it was told.
2. **No enforcement mechanism**: Documentation is passive. It says "you must do X" but nothing prevents the AI from doing Y instead.
3. **Optimization bias**: AI assistants optimize for speed and "helpfulness." Following a 5-stage workflow feels slower than just writing the code, so the AI rationalizes skipping steps ("this change is too small for a full spec").
4. **Scope judgment calls**: The SDD-1 prompt includes scope assessment examples showing some changes are "too small" for the workflow. The AI uses this as justification to skip the workflow entirely, rather than producing a simpler spec.

### Evidence: The Filter Pill Incident

During this project, the user reported two UI issues: an "Error" nav item that shouldn't be visible, and broken vet specialty filter pills. Despite having:

- **CLAUDE.md** stating "Use the frontend-design skill for building UI components"
- **CLAUDE.md** stating "Use the web-design-guidelines skill to review UI for accessibility and design compliance"
- **Constitution Article 6** requiring proof artifacts for every completed task
- **Constitution Article 1** requiring tests before implementation

The AI (Claude):

1. Created GitHub issues (#16, #17) — correct
2. Created a minimal spec with no clarifying questions — **skipped SDD-1 Q&A**
3. Wrote no task list — **skipped SDD-2 entirely**
4. Ran no analysis — **skipped the analyze step entirely**
5. Went straight to editing CSS without writing tests — **violated Article 1**
6. Did not use the frontend-design or web-design-guidelines skills — **ignored CLAUDE.md**
7. Committed broken CSS that rendered pills as flat unstyled text — **broken output shipped**

The user had to catch the broken output, point out the process violation, and request a redo. The redo, following the full SDD workflow, produced working CSS with proper design review and accessibility verification.

**Root cause**: The AI judged the fix as "too small" for the full workflow and skipped it. Nothing structurally prevented this.

---

## Customization Catalog

### 1. The Constitution (`docs/constitution.md`)

**What the stock SDD provides**: Nothing. No governance document ships with the stock repo.

**What we added**: 10 immutable articles governing all AI-assisted development.

**Why it's necessary**:

The stock SDD prompts contain scattered instructions ("write tests first," "use conventional commits") but these are embedded in long prompt files that the AI may not fully process. The constitution extracts these into a standalone, authoritative document with explicit article numbers that can be referenced in analysis and validation.

| Article | Failure Mode It Prevents |
|---|---|
| 1: Test-First Mandate | AI writes implementation code before tests, then writes tests that match the implementation rather than the requirements |
| 2: Library-First | AI implements custom solutions when established libraries exist (e.g., writing a custom CSV escaper when a library might exist) |
| 3: Simplicity Gate | AI adds speculative features, configuration options, or abstractions "just in case" |
| 4: Anti-Abstraction Gate | AI extracts helper classes, utility functions, or base classes prematurely after seeing only one use case |
| 5: Integration-First Testing | AI mocks internal modules, producing tests that pass but don't verify real behavior |
| 6: Proof Artifact Requirement | AI claims "it works" without committed evidence — the next conversation has no way to verify |
| 7: Uncertainty Markers | AI guesses at ambiguous requirements instead of asking, producing implementations that need rework |
| 8: Single-Threaded Execution | AI starts multiple features in parallel, leaving half-finished work across the codebase |
| 9: Conventional Commits | AI writes vague commit messages like "update files" that provide no traceability |
| 10: Frontend Visual Compliance | AI makes visual changes without referencing the style guide or running design reviews, producing inconsistent UI |

**Evidence of value**: Article 10 was added specifically because the AI violated every frontend-related instruction during the filter pill incident. After adding the article and the analyze skill check, the subsequent filter pill redesign (Spec 09) included proper design review, accessibility audit, and style guide reference.

---

### 2. The Analyze Skill (`.claude/skills/analyze/`)

**What the stock SDD provides**: Nothing. The stock workflow goes directly from SDD-2 (task generation) to SDD-3 (implementation) with no quality gate.

**What we added**: A cross-artifact consistency check that must PASS before implementation begins. It verifies:

- Every spec requirement maps to at least one task
- Every task's acceptance criteria are testable
- No scope creep (tasks that don't trace to spec requirements)
- Constitution compliance across all articles
- No unresolved `[NEEDS CLARIFICATION]` markers
- No ambiguous language ("might," "could," "possibly")
- Frontend changes reference the style guide (Article 10)

**Why it's necessary**:

Without this gate, the AI can generate a spec and task list that look comprehensive but have gaps. The analyze step catches these gaps before any code is written.

**Evidence of value**: During Spec 03 (Owner Search & Data Export), the analyze step verified 27/27 functional requirements were covered by tasks and flagged one nuance: the telephone search validation in the controller needed to be programmatic (not Bean Validation on the entity) because the search form doesn't use `@Valid`. This was noted in the analysis and correctly handled during implementation.

---

### 3. The Dual-Loop TDD Skill System (`.claude/skills/tdd*`)

**What the stock SDD provides**: SDD-3 mentions "follow your project's testing approach" but provides no structure for TDD beyond that generic instruction.

**What DEVELOPMENT.md provides**: A single-loop Red-Green-Refactor description — write failing test, make it pass, refactor.

**What we added**: Four specialized skills forming a dual-loop TDD system:

#### `tdd` (Orchestrator)

- Manages the overall TDD cycle but **never writes code itself**
- Tracks state in `tdd-state.md` so progress survives context resets
- Directs the developer to invoke the correct worker skill at each step
- Verifies prerequisites: spec exists, tasks exist, `/analyze` passed

#### `tdd-outer-loop` (Acceptance Test Writer)

- Converts spec acceptance criteria into failing integration/acceptance tests
- **Context-isolated**: explicitly forbidden from reading implementation plans, task breakdowns, or source code
- Can only read: spec file, existing test files, test config, constitution

#### `tdd-inner-loop` (Unit Implementation)

- Implements code using strict red-green-refactor at the unit level
- Writes the smallest failing unit test, minimal code to pass, refactors
- Checks the acceptance test after each cycle to track progress
- References constitution articles 2-4 (library-first, simplicity, anti-abstraction)

#### `tdd-verify` (Acceptance Gate)

- Runs the full test suite (not just the current test)
- Detects regressions in previously passing tests
- Creates proof artifacts on success
- Gates advancement to the next acceptance criterion

**Why it's necessary — the context isolation argument**:

This is the single most important difference between our approach and both the stock SDD and DEVELOPMENT.md.

When an AI writes tests after seeing the implementation plan (or after writing the implementation), it unconsciously writes tests that verify the implementation rather than the requirements. This is the AI equivalent of "teaching to the test" — the tests pass, but they don't actually validate that the feature works correctly from a user's perspective.

The `tdd-outer-loop` skill's isolation rule structurally prevents this:

```text
You must NOT read:
- Task breakdown files (*-tasks-*.md)
- Implementation source code
- Architecture or design documents
- Any file that reveals how the feature will be implemented
```

This means the acceptance tests are written purely from the spec's acceptance criteria — what the user asked for, not how the developer plans to build it.

**Evidence of value**: During Spec 03, the outer-loop acceptance tests for the extended owner search were written before any repository or controller code existed. The tests defined the expected behavior (`searchOwners` method with specific parameters), and the implementation was driven by making those tests pass. The tests caught a real issue: the existing `testProcessFindFormSuccess` test was still mocking `findByLastNameStartingWith` after the controller was changed to call `searchOwners`, causing a `NullPointerException`. Without the test-first approach, this regression would have been missed.

**What DEVELOPMENT.md's single-loop misses**:

DEVELOPMENT.md describes Red-Green-Refactor but doesn't address:

- **What** tests to write (unit? integration? acceptance?)
- **When** to write acceptance-level tests vs unit tests
- **How** to prevent the AI from seeing implementation details while writing tests
- **How** to track which acceptance criteria have been satisfied
- **How** to survive context window compression in long conversations

---

### 4. The Context Check Skill (`.claude/skills/context-check/`)

**What the stock SDD provides**: Emoji markers (SDD1, SDD2, SDD3, SDD4) in each prompt file. These are passive — if the AI drops them, nothing happens.

**What we added**: An active skill that can be invoked to check for context degradation. It:

- Identifies what SDD stage should be active
- Checks if the AI's recent responses include the expected marker
- Detects workflow adherence, topic drift, and constitution violations
- Recommends recovery actions (mild: remind, moderate: re-invoke command, severe: new conversation)

**Why it's necessary**:

In long conversations (this project's main session exceeded 100+ exchanges), the AI's context window compresses earlier messages. The SDD stage instructions, CLAUDE.md content, and constitution articles can all be lost. The context check provides a diagnostic tool to detect and recover from this.

**Evidence of value**: The stock emoji markers worked during the early specs (03, 04) but were not actively monitored. The filter pill incident occurred deep in the conversation where context pressure was highest — the AI had lost its adherence to the SDD workflow despite having the markers defined.

---

### 5. The Constitution Check Skill (`.claude/skills/constitution-check/`)

**What the stock SDD provides**: Nothing.

**What we added**: A skill that validates any plan, task breakdown, or implementation against all 10 constitutional articles, producing a per-article PASS/FAIL/N/A report with evidence and justification.

**Why it's necessary**:

The analyze skill checks constitution compliance at the task-planning stage. The constitution-check skill can be run at any point — on a plan, during implementation, or during review. It provides a structured, repeatable evaluation rather than relying on the AI to "remember" the constitution.

---

### 6. Claude Code Hooks (`.claude/settings.json`)

**What the stock SDD provides**: Nothing. The stock repo has no `.claude/` directory.

**What we added**: Two hooks:

- **postToolUse (Edit|Write)**: Reminds the AI to run tests after implementation changes
- **preCommit**: Reminds the AI to verify proof artifacts, passing tests, and conventional commit format

**Why they're necessary**:

These are the closest thing to automated enforcement we have. The AI sees these reminders every time it edits a file or attempts a commit. They're not optional — the hook system injects them into the conversation automatically.

**Evidence of value**: The pre-commit hook reminder consistently kept commits in conventional format throughout all 9 specs. Without it, the AI tends to drift toward generic messages.

---

### 7. The Style Guide and Article 10

**What the stock SDD provides**: Nothing related to frontend quality.

**What we added**:

- `docs/STYLE_GUIDE.md` — Complete visual design system documentation (colors, typography, spacing, components, interaction states, accessibility requirements)
- Constitution Article 10 — Requires style guide reference and design review for all visual changes
- Analyze skill check — Flags missing style guide during cross-artifact analysis

**Why it's necessary**:

AI assistants treat CSS as "just code" — if it compiles (or in CSS's case, doesn't error), it's considered done. But CSS that "works" can still look terrible, be inaccessible, or clash with the existing design system. Article 10 and the style guide create a verifiable standard for visual work.

**Evidence of value**: The filter pill incident is the direct proof. First attempt (no style guide, no design review) → broken unstyled text. Second attempt (with style guide reference, web-design-guidelines audit, WCAG contrast verification) → properly styled pills matching the dark theme with accessibility compliance.

---

### 8. Mandatory SDD Workflow Declaration in CLAUDE.md

**What the stock SDD provides**: The prompts describe the workflow but don't mandate it. The scope assessment in SDD-1 explicitly lists changes that are "too small" for the workflow.

**What we added**: An explicit section in CLAUDE.md:

> **All code changes must follow the Spec-Driven Development workflow. No exceptions.**
> The scope assessment in SDD-1 determines the appropriate level of detail, but **the stages must not be skipped**. Even bug fixes and "small" changes go through the workflow.

**Why it's necessary**:

The stock SDD-1 prompt includes scope examples where changes are "too small" for a spec (e.g., "changing the color of a button in CSS"). This gives the AI an escape hatch to skip the entire workflow. Our mandate closes that escape hatch — the workflow always runs, but the scope assessment adjusts the level of detail.

**Evidence of value**: The filter pill incident. The AI classified the fix as "too small" and skipped the workflow. After adding the mandatory declaration, the subsequent Spec 09 followed the full workflow and produced a working result.

---

## Comparison: What Happens Without These Customizations

| Scenario | Stock SDD Outcome | Our Customized SDD Outcome |
|---|---|---|
| AI decides a fix is "too small" | Skips workflow entirely, writes code directly | Runs workflow with simpler spec; analyze step still validates |
| AI writes tests after implementation | Tests verify implementation, not requirements | Outer-loop tests written in isolation, verify requirements |
| Spec has gaps in requirement coverage | Goes undetected until validation (if it catches it) | Analyze gate catches gaps before any code is written |
| AI forgets its instructions mid-conversation | No detection mechanism | Context-check skill diagnoses and recommends recovery |
| CSS change looks wrong but "works" | No design review gate | Article 10 requires style guide reference + web-design-guidelines audit |
| AI skips proof artifacts | Nothing prevents it | Article 6 + analyze gate + SDD-4 validation all check for proofs |
| AI uses ambiguous language in spec | Goes to implementation with assumptions | Analyze scans for "might," "could," "possibly" and flags them |

---

## Recommendations

1. **The stock SDD workflow is a good starting point** but should be considered a minimum, not a complete solution
2. **The constitution pattern is the highest-value addition** — it creates referenceable, checkable rules that survive context compression
3. **The analyze gate is the second-highest value** — catching gaps before implementation saves significant rework
4. **Context isolation in TDD is essential for AI** — without it, tests become implementation mirrors rather than requirement validators
5. **Frontend work needs explicit governance** — AI treats visual changes as low-priority, leading to broken or inconsistent UI without enforcement
6. **"No exceptions" mandates beat scope-based exemptions** — any escape hatch the AI can find, it will use

---

## Why Context Window Management Is the Wrong Variable

A common response to AI instruction drift is to reduce the context window or start fresh conversations more frequently. This is optimizing the wrong variable.

### Smaller windows don't solve the problem

1. **Smaller window = more frequent resets = more re-reading files = same vulnerability.** A fresh conversation still loads CLAUDE.md, constitution, DEVELOPMENT.md, etc. — and "Lost in the Middle" research applies to those loaded files too, not just conversation history. If the constitution is file #3 of 5 loaded docs, it's already in the middle.

2. **The failure mode isn't "too many tokens."** The failure mode is "AI rationalizes skipping steps." That happens at token 1,000 just as easily as at token 500,000. During the filter pill incident, the AI didn't skip the workflow because it forgot the rules — it skipped because it judged (incorrectly) that the rules didn't apply. That's a discipline problem, not a memory problem.

3. **Enforcement layers work regardless of context size.** The constitution gets re-read from disk by the analyze skill. The SDD commands inject fresh prompts. The context-check runs at defined checkpoints. These work the same at 10K tokens as at 500K tokens.

### Evidence from this session

This session ran to 535K tokens — 9 specs, 12 issues, ~20 PRs. One failure occurred.

| What the AI "forgot" | Was it actually forgotten? | What caught it |
|---|---|---|
| SDD workflow for filter pills | No — AI chose to skip it | User caught it; led to mandatory SDD declaration |
| Frontend design skills | No — AI chose to skip them | User caught it; led to Article 10 |
| Style guide reference | Didn't exist yet | The redo's web-design-guidelines review revealed the gap |

None of these were memory failures. They were **judgment failures** — the AI deciding it knew better than the process. The skills and constitution articles fix this by removing judgment from the equation. The analyze gate doesn't ask "do you think you should check the constitution?" — it checks it every time, mechanically.

### The right architecture

The investment in enforcement layers (constitution, analyze gate, context-check integration, mandatory SDD declaration) is the correct approach. The workflow handles context management for the user through:

- **Re-injection**: Each SDD stage command injects fresh instructions (~2-3K tokens)
- **Disk reads**: The analyze skill re-reads the constitution from disk, not from compressed conversation history
- **Checkpoint self-assessment**: Context-check runs before and between parent tasks in SDD-3
- **Mechanical compliance**: Skills check the constitution every time, regardless of what the AI "remembers"

Users should not have to manage context windows. The flow should handle it for them — and it does.

---

## Appendix: Project Statistics

- **Specs completed**: 9 (03 through 09, plus 2 pre-existing)
- **Issues resolved**: 12 (10 original + 2 UI fixes)
- **Total JUnit tests**: 97 (added ~50 new tests)
- **Playwright E2E test files**: 12 new test suites
- **PRs merged**: 8
- **Constitution articles**: 10
- **Custom skills**: 7
- **SDD workflow violations caught**: 1 (filter pill incident → led to Article 10 and mandatory SDD declaration)
- **SDD workflow violations that shipped broken code**: 1 (same incident — the only broken code that reached main)
