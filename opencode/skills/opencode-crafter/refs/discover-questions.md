# Phase:Discover — Questions

Ask focused questions until you have enough requirements to draft.

For all artefact types:
- Single responsibility of artefact?
- Project-scoped or global/personal?
- Any constraints, failure modes, or edge cases?
  (may appear during review iterations or later as artefact used in different contexts)

For skills additionally:
- What inputs does agent receive? What should it produce?
- Trigger style: when and how does the skill load?
  Read <./skills-related/trigger-styles.md> for the full style catalogue and discovery questions.
  If skill has a companion command trigger: read <./skills-related/with-command-trigger.md>.
- Does skill receive structured inputs to extract from free-form context (path, scope, hints, …)?
  If yes: read <./with-precise-inputs.md> for the `## Setup` pattern.
  For each input: does it have a default, or is it required (skill stops if absent)?
- Does skill compute values that are referenced across multiple steps (e.g. a path, slug, or dir)?
  If yes: read <./with-computed-vars.md> for the declaration block pattern, naming guidelines, and rules.
- Any reference docs, scripts, or templates needed?
- Any sub-scenarios where only part of instructions applies?
  If yes: apply progressive disclosure — read <./skills-related/anatomy.md§progressive-disclosure>
  for pattern (split criteria, conditional trigger syntax).

For agents additionally:
- Primary agent or subagent? Hidden from autocomplete? Isolated context?
- Which tools should be allowed, denied, or ask-before-use?
- Different model or temperature needed?
- Trigger style: the `description` field drives auto-invocation for agents too.
  Same trigger style questions as skills apply — see <./skills-related/trigger-styles.md>.
- Does agent extract structured inputs from free-form context (path, scope, hints, …)?
  If yes: same `## Setup` pattern applies — see <./with-precise-inputs.md>.

For commands additionally:
- What arguments does it take? (if any)
- Shell output or file content injection needed?
- Run in subagent session to avoid polluting context?

For snippets additionally:
- Trigger name? any aliases?
- Expand inline, or use `<append>`/`<prepend>` blocks?
- Shell command output injection needed (`` !`cmd` ``)?
