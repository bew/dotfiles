# Phase:Discover — Questions

Ask focused questions until you have enough requirements to draft.

For all artefact types:
- Single responsibility of artefact?
- Project-scoped or global/personal?
- Any constraints, failure modes, or edge cases?
  (may appear during review iterations or later as artefact used in different contexts)

For skills additionally:
- What inputs does agent receive? What should it produce?
- Any reference docs, scripts, or templates needed?
- Any sub-scenarios where only part of instructions applies?
  If yes: apply progressive disclosure — read <./skills-related/anatomy.md§progressive-disclosure>
  for pattern (split criteria, conditional trigger syntax).

For agents additionally:
- Primary agent or subagent? Hidden from autocomplete? Isolated context?
- Which tools should be allowed, denied, or ask-before-use?
- Different model or temperature needed?

For commands additionally:
- What arguments does it take? (if any)
- Shell output or file content injection needed?
- Run in subagent session to avoid polluting context?

For snippets additionally:
- Trigger name? any aliases?
- Expand inline, or use `<append>`/`<prepend>` blocks?
- Shell command output injection needed (`` !`cmd` ``)?
