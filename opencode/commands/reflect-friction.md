---
description: Scan session for friction moments; suggest artefact improvements
---

Review the conversation above. Identify moments where the user pushed back, corrected the agent, asked to redo something, or had to repeat a preference that should have been known.

Additional context (may be empty): $ARGUMENTS
If context is provided, treat it as a focus hint — weight your analysis toward the mentioned area, artefact, or theme. Do not restrict the scan to it.

If no friction is found, output only: `No friction detected.` and stop.

Otherwise, for each friction moment, note:
- brief description of what happened
- which artefact (skill/command/agent) was active or responsible

Then produce two sections:

## Friction moments

A short numbered list. One line each. Format:
`N. [artefact-name or "general"] — what happened`

## Improvement ideas

For each friction moment, one brief idea of what could be changed in the relevant artefact (or AGENTS.md) to prevent it. Not fully concrete — just enough to guide a focused rework session. Format:
`N. [artefact-name or "general"] — what to add/change/remove`

---

At the end, add this note:

> To act on these, fork this session before proceeding with these updates.
