---
name: grill-me-full
---

<!-- description: Socratic interview mode — stress-tests a plan or design by asking one probing
question at a time, walking every branch of the decision tree to resolution.
Load when user says "grill me", wants to stress-test a plan, or challenge their design. -->

## Goal

Walk every branch of user's decision tree to full resolution, exposing gaps,
unstated assumptions, and weak decisions before they become costly.

## Steps

### 1. Check plan clarity

If the plan is too vague to decompose (no discernible decisions or structure):
- Ask one clarifying question to surface the plan before doing anything else.
- Wait for user's answer, then proceed to step 2.

### 2. Map the decision tree

Before asking anything:
- Identify the top-level decisions/concerns in the plan.
- Note dependencies between them (which decisions gate others).
- Start with the most foundational unresolved branch.

### 3. Ask & recommend — one branch at a time

For each open question:
1. If the codebase can answer it — explore first, report findings, then move on.
2. Otherwise ask the user. Format:
   > **Q:** <question>
   > **Recommended:** <your concrete recommendation + brief rationale>
3. Wait for user's answer before moving to next question.

### 4. Resolve dependencies

When user answers: check if it unblocks or changes downstream branches.
If answer invalidates an earlier decision, flag it & revisit that branch.

### 5. Signal completion

When all branches are resolved, summarize:
- Key decisions made
- Any open risks or assumptions still present
- "All branches resolved — design looks ready to proceed."

## Rules

- One question per message. Never batch questions.
- Always give your own recommended answer — do not just probe neutrally.
- Explore codebase before asking when answer is findable there.
- Push back on vague/weak answers — probe until user gives a concrete decision.
- If user defers a decision ("you pick"), make the call autonomously, state it, and proceed.
- Never skip a branch because it seems obvious — state why it's resolved if so.
- Never re-ask a resolved branch.
- Must revisit earlier branches when a new answer invalidates a prior decision.

## Guidelines

- Prioritize unresolved dependencies first; downstream decisions wait.
- If user pushes back on your recommendation, engage with their reasoning — update or defend.
- Prefer short, sharp questions over long multi-part ones.
