# Phase:review — Review & iterate with user via subagent

Invoke `opencode-artefact-reviewer` subagent via `task` tool.
Pass in prompt:
- Artefact type and name
- `$draftpath` (reviewer reads and edits files there)
- For updates: which parts changed, so reviewer can focus

Subagent reads and edits files at `$draftpath`, asks user questions via `question` tool.
Reviewer handles writing-style conformance — do not pre-apply style yourself.
For updates: tell reviewer to focus on changed sections and verify coherence with unchanged parts.
Continue until user confirms or types "done". No round limit.

After iterations, briefly reflect on diff between initial & final draft.
Ask: *Ready to write `<name>` to `$installpath` ?* (skip for updates — `$draftpath` = `$existingpath`)
