---
name: agent-stuck
description: |
  Load when the agent cannot proceed without a human decision or a strategy change.
  Track consecutive identical failures — load this skill at the third. Also load when
  the task requires a library that is not yet in the project.
---

## Goal

Break the loop or surface decision to user so task can continue.

## Steps

### 1. Classify the situation

If doom loop appears to be caused by missing library, treat as **Library needed** —
skip doom loop branch and address root cause directly.

| Case | Signal |
|---|---|
| **Doom loop** | Same error occurred 3 or more consecutive times |
| **Library needed** | Code requires external package not yet in project |

Doom loop count is per distinct error. Reset count when materially different error appears.

### 2. Act based on case

#### Doom loop

1. Stop retrying immediately.
2. Summarize: what was attempted, what failed each time, what output was identical.
3. Try one materially different approach (different tool, different flag, different algorithm).
4. If that also fails, halt & present full diagnosis to user:
   - All attempted approaches
   - Repeating error
   - Hypotheses for root cause, ranked by likelihood
5. Ask user how to proceed.

#### Library needed

1. Check project's dependency manifest (`package.json`, `pyproject.toml`, `go.mod`,
   `Cargo.toml`, `requirements.txt`, etc.) to confirm library is truly absent.
2. State capability gap: what code needs to do that no current dependency covers.
3. List up to 5 libraries — include what you know; flag if list may be incomplete.
   Use web search if you have no knowledge of any library for this need.
   For each entry: name, one-line description, short install command. Do NOT recommend one.
4. Ask user which library to use, or whether to proceed without one.
5. Pause. Wait for user's choice before writing any code.

### 3. After resolution

Resume original task from step that was blocked.

NOTE: If same block recurs after resolution attempt, re-enter this skill but skip step 3
(no retry). Go directly to halt and ask user.

## Rules

- Never retry doom-loop pattern more than once after classifying it as such.
  Single retry in step 3 must be materially different — not just re-running same command.
- Never silently skip a situation that requires human decision.
- Never install a library without explicit user approval.
- Resolve each situation in minimum turns — one ask, wait for user response,
  then resume. Do not let resolution consume enough context to lose original task.

## Guidelines

- Prefer simplest diagnosis. Don't over-investigate before asking.
- Batch multiple questions into single message when more than one needed.
- Keep each ask short & actionable.
- For doom loops: hypotheses ranked by likelihood, not exhaustiveness.
