---
description: Scan session for friction moments; suggest artefact improvements
---

Review conversation above.
Identify moments where user pushed back, corrected agent, asked to redo something, or had to repeat a preference that should have been known.

Additional context (may be empty): $ARGUMENTS
If context is provided, treat as focus hint — weight analysis toward mentioned area, artefact, or theme.
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
Not fully concrete — enough to guide focused rework session.
Format: `N. [artefact-name or "general"] — what to add/change/remove`

---

If the last 1-2 message has explicit mention that session was forked (e.g. "session forked" or similar):
- Omit the fork note below.
- Instead, offer to directly proceed with applying the improvement ideas.

Otherwise, add this note at end:

> To act on these, fork this session before proceeding with these updates.
