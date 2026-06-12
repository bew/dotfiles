# Phase:scripts — Script POC & iterate via subagent

Invoke `opencode-skill-script-crafter` subagent via `task` tool.
Pass in prompt:
- `$draftpath` (agent works there), SKILL.md there used for script's interface spec
- Only extra context not captured in SKILL.md: behavioral notes, edge cases, impl details
  discussed in `Phase:discover/draft` that SKILL draft intentionally omits.

Subagent writes scripts and tests into `$draftpath`, iterates with user, and returns when confirmed.

Only proceed to `Phase:review` once user confirms scripts are done.
Script review does not count as full-artefact review — `Phase:review` covers the complete artefact.
If user abandons script work mid-phase, note any unresolved scripts and carry the gap into `Phase:review`.
