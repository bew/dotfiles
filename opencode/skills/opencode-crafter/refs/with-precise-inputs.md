# Artefact with Precise Inputs

Skills and agents may need to extract structured inputs (e.g. path, scope, diff type, free-text hints)
from free-form context (user message, command output, session prompt).

If triggered by a command: read <./skills-related/with-command-trigger.md> for the command body shape.

## `## Setup` section

Add a `## Setup` section as the **first section** of the skill or agent body (before `## Overview` or the first phase).

The section must:
- List every input with its source and default (or "required" if no default).
- Describe how to infer each value from whatever is in context — no assumption about the caller.
- State all resolved values in a fenced `text` block so later phases can reference them by name.

NOTE: Never mention `$ARGUMENTS` in a skill body.
By the time the skill loads, `$ARGUMENTS` has already been expanded by the command into plain text.
The skill sees only the resulting context — it does not know where it came from.

Template:

`````md
## Setup — resolve inputs

Determine the following values from whatever is available in context
(user message, prior context, session prompt, or defaults):

- **<Input 1>**: <what it is>. Default: `<default>`.
- **<Input 2>**: <what it is>. Required — stop and ask user if absent.
- **<Input N>**: any remaining free-form text. Carry forward as hints. Default: `(none)`.

State resolved values:
```text
<Input 1>: <resolved value>
<Input 2>: <resolved value>
<Input N>: <resolved value, or "(none)">
```
`````

## Rules

- Every input must have either a default or a "required" declaration.
- If a required input is absent: stop. Tell the user which input is missing and how to provide it.
  Do not guess or substitute.
- Never fail silently on missing input — always surface what is needed.
- Free-form remainder after extracting structured inputs → treat as hints; carry forward.
- Later phases reference resolved values by name (e.g. "use `Scope` from *Setup*").
  Do not re-parse raw context in later phases.
