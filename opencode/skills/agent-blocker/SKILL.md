---
name: agent-blocker
description: |
  Load when the agent hits an environment or runtime wall: missing binary, version/runtime mismatch,
  permission denied, auth/credentials failure, unreachable network/API, or a test suite broken
  independently of agent changes.
---

## Goal

Diagnose the environment blocker and escalate to the user with a concrete, actionable ask.

## Steps

### 1. Classify the blocker

Capture the exact raw error output first — do not paraphrase it. Then identify which case
applies before acting. More than one may apply simultaneously.

| Case | Signal |
|---|---|
| **Missing binary** | `command not found`, `No such file or directory` for an executable |
| **Version/runtime mismatch** | Wrong interpreter, compiler, or runtime version detected |
| **Permission denied** | `Permission denied`, `EACCES`, `EPERM` on a file, socket, or port |
| **Auth/credentials failure** | HTTP 401/403, expired token, missing API key or credential |
| **Network/API unavailable** | External service unreachable, timeout, 5xx, or DNS failure |
| **Test suite broken independently** | Tests fail in ways unrelated to agent's own changes |

### 2. Act based on case

#### Missing binary

1. Identify the binary name and which tool/task requires it and why.
2. Do NOT attempt to install it.
3. Ask: "Binary `<name>` required but missing."

#### Version/runtime mismatch

1. State the detected version and the required version.
2. Do NOT attempt to install or switch versions.
3. Ask user to fix

#### Permission denied

1. Identify the exact path, port, or resource.
2. Check if fixable by the agent (e.g., `chmod` on an agent-created file) or requires elevated privileges.
3. If fixable: propose the exact fix command for the user to run (never run it autonomously).
4. If not fixable: ask the user to resolve it.

#### Auth/credentials failure

1. State the exact call that failed and the error (401, 403, token expired, etc.).
2. Do NOT attempt to read, guess, or generate credential values.
3. Ask the user to set or renew the credential and confirm when done.

#### Network/API unavailable

1. State what was called and what the error was (timeout, 5xx, DNS failure).
2. Do not retry in a tight loop. Wait or ask the user to confirm the service is up.
3. If the API is optional for the task: proceed without, flag as skipped.

#### Test suite broken independently

1. Run `git diff HEAD -- <specific files the tests cover>`. If those files are unchanged relative
   to `HEAD`, the failure pre-dates the agent's edits.
2. Never run `git stash`.
3. If pre-existing: doc, skip those tests, continue main task.
4. Do not spend cycles trying to fix tests outside the current task's scope.
5. Report the pre-existing failures to the user as a side note.

### 3. After unblocking

Resume the original task from the step that was blocked. Do not restart from scratch.

If the user confirms the blocker is unresolvable: document what cannot be completed, state
which part of the task is blocked, and stop. Do not speculate on alternatives.

## Rules

- Never install binaries, packages, or system dependencies without explicit user approval.
- Never silently skip a blocker — always surface it to the user.
- Never run destructive commands (permission changes, version switches) autonomously.
- Never run `git stash`.
- Never read, guess, or generate credential or secret values.
- `git diff HEAD -- <files>` is allowed; scope it to files relevant to the failure.
- Resolve each blocker in the minimum number of turns — one ask, wait for user response, then
  resume. Do not let blocker resolution consume enough context to lose the original task.

## Guidelines

- Prefer simplest diagnosis. Don't over-investigate before asking.
- When multiple cases apply at once, address the most fundamental one first
  (missing binary blocks everything else).
- Batch multiple questions into a single message when more than one is needed.
- Keep each ask short and actionable.
