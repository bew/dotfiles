# Phase:Scripts — Script POC & iterate via subagent

Invoke `opencode-skill-script-crafter` subagent via `task` tool.

Resolve every rule file below to an absolute path under this skill's directory before passing it:
the subagent cannot resolve a ref path against this skill.
Pass in prompt:
- `$draftpath` (agent works there), SKILL.md there used for script's interface spec
- Only extra context not captured in SKILL.md: behavioral notes, edge cases, impl details
  discussed in `Phase:Discover`/`Phase:Draft` that SKILL draft intentionally omits.
- Absolute path of <./../skills-related/with-script.md>, always.
- Absolute path of <./../skills-related/with-script-python-split.md>, when the script is Python
  and expected to outgrow one file.

The subagent stops when it receives no rule file, so a prompt without them yields nothing.

Subagent writes scripts + tests into `$draftpath`, iterates with user, returns when confirmed.
Always propose a companion `.bats` test file alongside the script.
A Python script that outgrows one file may also get a pytest suite, but only once the user
agrees to the `scripts/lib/` restructure.
Check `pytest` is available before writing that suite.
If it is missing, surface it and ask the user before installing anything.

Proceed to `Phase:Review` only once user confirms scripts done.
Script review does not count as full-artefact review — `Phase:Review` covers complete artefact.
If user abandons script work mid-phase, note unresolved scripts & carry gap into `Phase:Review`.

NOTE: Passing the script's own tests (`.bats` end-to-end, pytest unit) is script correctness only.
The simulated test runner (skill-level agent behaviour) runs in `Phase:Review`.
Do not conflate the two when reporting test results to the user.
