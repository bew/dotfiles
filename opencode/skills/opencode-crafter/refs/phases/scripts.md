# Phase:Scripts — Script POC & iterate via subagent

Invoke `opencode-skill-script-crafter` subagent via `task` tool.
Pass in prompt:
- `$draftpath` (agent works there), SKILL.md there used for script's interface spec
- Only extra context not captured in SKILL.md: behavioral notes, edge cases, impl details
  discussed in `Phase:Discover`/`Phase:Draft` that SKILL draft intentionally omits.

Subagent writes scripts + tests into `$draftpath`, iterates with user, returns when confirmed.

Proceed to `Phase:Review` only once user confirms scripts done.
Script review does not count as full-artefact review — `Phase:Review` covers complete artefact.
If user abandons script work mid-phase, note unresolved scripts & carry gap into `Phase:Review`.
