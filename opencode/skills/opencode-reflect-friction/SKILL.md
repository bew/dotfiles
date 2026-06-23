---
name: opencode-reflect-friction
description: |
  Load ONLY when user explicitly invokes /reflect-friction or directly asks to review session friction
  (e.g. "review friction", "what went wrong", "where did you push back").
  Do NOT auto-load speculatively.
metadata:
  maintainers: bew
---

Review conversation above.
Identify moments where user pushed back, corrected agent, asked to redo something,
or had to repeat a preference that should have been known.

If a focus hint was provided by the caller, weight analysis toward that area, artefact, or theme.
Do not restrict scan to it.

If no friction found, output only: `No friction detected.` and stop.

Otherwise, for each friction moment, note:
- brief description of what happened
- which artefact (skill/command/agent) was active or responsible

Then produce two sections:

## Friction moments

Short numbered list. One line each.
Format: `N. [artefact-name or "general"] — what happened`

## Improvement ideas

For each friction moment, one brief idea of what to change in relevant artefact (or AGENTS.md) to prevent it.
Not fully concrete — enough to guide a focused rework session.
Format: `N. [artefact-name or "general"] — what to add/change/remove`

## Post-output notes

If the last 1–2 messages mention that the session was forked (e.g. "session forked"):
- Omit the fork note below.
- Instead, offer to directly proceed with applying the improvement ideas.

Otherwise, add at end:
> To act on these, fork this session before proceeding with these updates.

If context has many old messages/tool outputs, also add:
> Consider compressing context (saves tokens/money!)
