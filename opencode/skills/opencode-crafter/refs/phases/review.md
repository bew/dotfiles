# Phase:Review — Review & iterate with user via subagent

Invoke `opencode-reviewer` subagent via `task` tool.
Pass in prompt:
- Artefact type and name
- `$draftpath` (reviewer reads and edits files there)
- Path to writing rules file: `./refs/rules-for-writing.md`
- Path to steps/phases/headers rules file: `./refs/rules-for-steps-phases-headers.md`
  NOTE: these are crafter-root-relative paths — pass as literal strings in the task prompt; reviewer resolves them from the crafter skill directory.
- For updates: which parts changed, so reviewer can focus

Subagent reads & edits files at `$draftpath`, asks user questions via `question` tool.
Reviewer handles writing & structural conformance — do not pre-apply rules yourself.
For updates: tell reviewer to focus on changed sections & verify coherence with unchanged parts.
Continue until user confirms / types "done". No round limit.

After iterations, briefly reflect on diff between initial & final draft.
Ask: *Ready to write `<name>` to `$installpath` ?* (skip for updates — `$draftpath` = `$existingpath`)

IMPORTANT: Must receive explicit user confirmation (e.g. "yes", "ship", "proceed") before entering `Phase:Ship`.
Review Q&A answers do NOT count as ship confirmation. Do not skip this gate.
