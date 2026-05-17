---
name: agent-stuck
description: |
  Load when the agent cannot proceed without a human decision or a strategy change.
  Track consecutive identical failures — load this skill at the third. Also load when
  the task requires a library that is not yet in the project.
---

## Goal

Break the loop or surface the decision to the user so the task can continue.

## Steps

### 1. Classify the situation

If a doom loop appears to be caused by a missing library, treat it as **Library needed** —
skip the doom loop branch and address the root cause directly.

| Case | Signal |
|---|---|
| **Doom loop** | The same error has occurred 3 or more consecutive times |
| **Library needed** | Code requires an external package not yet in the project |

The doom loop count is per distinct error. Reset the count when a materially different error
appears.

### 2. Act based on case

#### Doom loop

1. Stop retrying immediately.
2. Summarize: what was attempted, what failed each time, what output was identical.
3. Try one materially different approach (different tool, different flag, different algorithm).
4. If that also fails, halt and present the full diagnosis to the user:
   - All attempted approaches
   - The repeating error
   - Hypotheses for root cause, ranked by likelihood
5. Ask the user how to proceed.

#### Library needed

1. Check the project's dependency manifest (`package.json`, `pyproject.toml`, `go.mod`,
   `Cargo.toml`, `requirements.txt`, etc.) to confirm the library is truly absent.
2. State the capability gap: what the code needs to do that no current dependency covers.
3. List up to 5 libraries — include what you know; flag if the list may be incomplete.
   Use web search if you have no knowledge of any library for this need.
   For each entry: name, one-line description, short install command. Do NOT recommend one.
4. Ask the user which library to use, or whether to proceed without one.
5. Pause. Wait for the user's choice before writing any code.

### 3. After resolution

Resume the original task from the step that was blocked. Do not restart from scratch.

If the same block recurs after a resolution attempt, re-enter this skill but skip step 3
(no retry). Go directly to halt and ask the user.

## Rules

- Never retry a doom-loop pattern more than once after classifying it as such.
  The single retry in step 3 must be materially different — not just re-running the same command.
- Never silently skip a situation that requires a human decision.
- Never install a library without explicit user approval.
- Resolve each situation in the minimum number of turns — one ask, wait for user response,
  then resume. Do not let resolution consume enough context to lose the original task.

## Guidelines

- Prefer the simplest diagnosis. Don't over-investigate before asking.
- Batch multiple questions into a single message when more than one is needed.
- Keep each ask short and actionable.
- For doom loops: hypotheses should be ranked by likelihood, not exhaustiveness.
