---
name: reflect-script-skills
description: |
  Post-iteration reflection for script writing sessions.
  Load after a script has been written or iterated and the user signals it is done.
metadata:
  maintainers: [bew]
---

## Goal

Surface patterns and decisions from the current script-writing session that are not yet encoded
in the active `write-script-*` skills, and ask the user whether to add them.

## When to load

Load this skill when all of the following are true:
- A `write-script-*` skill was active during the session.
- A script file was written or meaningfully iterated.
- The user explicitly signals the script is done (e.g. "looks good", "done", "ship it").

Do not load speculatively or mid-iteration.

## Steps

1. **Scan the session** — Review what was written or changed in the script.
   Identify anything that:
   - Is a deliberate stylistic or structural choice.
   - Deviates from or extends the active `write-script-*` skills.
   - Was improvised without a documented rule backing it.
   - Came up as a decision point (e.g. "should I use X or Y?").

2. **Identify candidate rules** — For each pattern found, decide:
   - Is it general enough to belong in `write-script-generic`?
   - Is it language-specific and belongs in the active lang skill?
   - Is it a one-off, not worth encoding?

3. **Ask the user** — Present candidates as a short list.
   For each, name: what the pattern is, which skill it would go into, and why.
   Ask the user to confirm which ones to capture.

4. **Summarize** — After the user responds, output a brief summary:
   - What will be added and where.
   - What was consciously left out and why.

   If no candidates were found, say so briefly — do not invent friction.

## Rules

- Never edit skill files silently — always confirm with the user first.
- Never add rules that are already covered in `write-script-generic` or the active lang skill.
- Keep candidates concrete: name the actual pattern observed, not an abstraction of it.
- One candidate per bullet — do not bundle unrelated patterns together.
