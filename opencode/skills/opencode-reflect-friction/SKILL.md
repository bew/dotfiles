---
name: opencode-reflect-friction
description: |
  Load ONLY when user explicitly invokes /reflect-friction or directly asks to review session friction
  (e.g. "review friction", "what went wrong", "where did you push back").
  Do NOT auto-load speculatively.
metadata:
  maintainers: bew
---

Goal: surface all friction from this session — both the main conversation and any subagents that were
launched — so every source of misalignment or repeated correction is captured in one report.

## Step 1 — Discover subagents

Scan the conversation for `task` tool calls that produced a `task_id`.
Collect: task_id, agent type, and brief description of what each subagent was launched to do.

If any task_ids are found:
- List them to the user: task_id, agent type, one-line purpose.
- Ask via `question` tool: "Which of these subagents should I collect friction from?" (allow "all", "none", or a subset)
- **STOP. Wait for user's answer before doing anything else.**

If none found, skip to *Main conversation scan*.

## Step 2 — Collect subagent friction

For each selected subagent, resume it using the `task` tool with its `task_id`.

Prompt to send to the revived subagent:

> You are being revived to report on your own session's friction.
> Please load the `opencode-reflect-friction` skill and run it on your inner transcript.
> If you cannot load a skill, here is the core friction prompt to run instead:
>
> Review your conversation above. Identify moments where: the user pushed back or corrected you,
> you had to redo something, you misunderstood an instruction, you missed a preference that should
> have been known, or you hit a tool/environment failure that caused retries.
>
> For each friction moment, note a brief description of what happened and which artefact or action
> was responsible.
>
> Output only a flat numbered list: `N. [artefact-name or "general"] — what happened`
> If no friction found, output only: `No friction detected.`

Wait for each subagent's response before proceeding.

## Step 3 — Main conversation scan

Review the main conversation above (excluding subagent tool result blocks already collected in
*Collect subagent friction*).
Identify moments where user pushed back, corrected agent, asked to redo something,
or had to repeat a preference that should have been known.

If a focus hint was provided by the caller, weight analysis toward that area, artefact, or theme.
Do not restrict scan to it.

Collect internally — do not output anything yet.
If no friction found anywhere (main + all subagents), output only: `No friction detected.` and stop.

Proceed to *Produce report*.

## Step 4 — Produce report

### Friction moments

Short numbered list. One line each.
- Main conversation items: `N. [artefact-name or "general"] — what happened`
- Subagent items: `N. [artefact-name or "general" | subagent-type via invoking-artefact] — what happened`

### Improvement ideas

For each friction moment, one brief idea of what to change in the relevant artefact (or `AGENTS.md`)
to prevent it.
Not fully concrete — enough to guide a focused rework session.
- Main conversation items: `N. [artefact-name or "general"] — what to add/change/remove`
- Subagent items: `N. [artefact-name or "general" | subagent-type via invoking-artefact] — what to add/change/remove`

## Post-output notes

If the last 1–2 messages mention that the session was forked (e.g. "session forked"):
- Omit the fork note below.
- Instead, offer to directly proceed with applying the improvement ideas.

Otherwise, add at end:
> To act on these, fork this session before proceeding with these updates.

If context has many old messages/tool outputs, also add:
> Consider compressing context (saves tokens/money!)
