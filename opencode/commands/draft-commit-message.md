---
description: Draft a git commit message from staged changes
subtask: true # isolated context
---

Draft a commit message for the currently staged changes.

## Recent commits

```
!`git log --oneline -10`
```

## Staged diff

```
!`git diff --staged`
```

## Instructions

### Step 0 — Guard: verify staged changes exist

If the staged diff above is empty, output exactly:
```
No staged changes. Stage files with `git add` before running this command.
```
Then stop. Do not produce a commit message.

### Step 1 — Detect commit style

Inspect the 10 recent commits above.

- If the majority follow `<type>(<scope>): <subject>` (conventional commits), use that format.
- Otherwise, derive a short lowercase topic word from the diff (subsystem, directory, or area
  being changed) and use it as a prefix. Examples of what that might look like: `ci`, `docs`,
  `adapters`. If no clear topic can be derived, use no prefix.

### Step 2 — Analyse the diff

Identify the distinct concerns in the diff. A concern is a logically independent change
(e.g. a bug fix, a new feature, a refactor of a separate module).

**Warning**: if the staged diff contains 3 or more unrelated concerns, output this warning
before the commit message:

```
WARNING: This diff mixes N distinct concerns. Consider splitting into separate commits:
- <concern 1>
- <concern 2>
- …
```

### Step 3 — Write the commit message

**Subject line rule**: the subject must complete this sentence:
> "When applied, this commit will <subject>"

Keep it 50 chars or fewer. Imperative mood. No trailing period.
Use the style detected in step 1.

**Body**: always include a body. One short paragraph per distinct concern. State directly
what that part of the commit does. Wrap at 72 chars.

Blank line between subject and body, and between paragraphs.
This MUST ALWAYS be respected, even when the user asks for a shorter message.

Output only the raw commit message (and warning if applicable) — no markdown fencing,
no extra commentary.
