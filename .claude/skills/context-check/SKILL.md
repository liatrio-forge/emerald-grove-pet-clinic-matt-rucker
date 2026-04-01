---
name: context-check
description: Detects context degradation during SDD stages by verifying emoji markers are present. Alerts when the model has lost its instructions.
---

# Context Degradation Check

You detect when an AI agent has lost track of its SDD stage instructions during a long conversation.

Based on [Liatrio's context verification marker system](https://github.com/liatrio-labs/spec-driven-workflow).

## How It Works

Each SDD stage requires the AI to prefix responses with a stage-specific marker:

- **SDD Stage 1** (Spec): Responses should include `SDD1` marker
- **SDD Stage 2** (Tasks): Responses should include `SDD2` marker
- **SDD Stage 3** (Execute): Responses should include `SDD3` marker
- **SDD Stage 4** (Validate): Responses should include `SDD4` marker

When the AI stops producing these markers, it has likely lost its stage instructions due to context window pressure.

## When to Run

- Periodically during long SDD sessions
- When AI responses seem off-topic or unfocused
- When the AI starts suggesting approaches that contradict the constitution
- When task execution seems to skip steps

## Workflow

### Step 1: Identify Current Stage

Determine which SDD stage should be active based on:

- Most recent `/SDD-*` command invoked
- State of artifacts (spec exists? tasks exist? implementation in progress?)

### Step 2: Check Recent Responses

Review the AI's recent responses for:

- Presence of the expected stage marker
- Adherence to the stage's workflow rules
- Signs of confusion or topic drift

### Step 3: Report

```markdown
## Context Check Report

- Expected stage: SDD[N]
- Marker present: YES / NO
- Workflow adherence: YES / PARTIAL / NO
- Signs of drift: [describe any observed issues]

### Recommendation
- HEALTHY: Continue as normal
- DEGRADED: Re-invoke the current stage command to re-anchor
- LOST: Start a fresh conversation and re-invoke from the current stage
```

## Recovery Actions

If degradation is detected:

1. **Mild** (marker missing but workflow intact): Remind the AI of the current stage
2. **Moderate** (workflow steps being skipped): Re-invoke the stage slash command
3. **Severe** (AI contradicting constitution or working on wrong task): Start fresh conversation, load the spec/task state, and re-invoke from the current stage
