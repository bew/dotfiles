# Building a Skill with a Script

This is the canonical reference for all scripting decisions in skill artefacts.
Apply when writing scripts, choosing languages, documenting scripts in SKILL.md or any reference file.

## Script basics

Language preference order for new scripts:

1. **Python** (`#!/usr/bin/env python3`) — default for most scripts.
2. **Nushell** (`#!/usr/bin/env nu`) — preferred for data-wrangling or shell-workflow scripts.
   NOTE: Nushell is only suitable for personal skills — it is not yet common enough for shareable/team skills.
3. **Bash** — fallback when portability or minimal dependencies matter most.

Add shebang, make executable (`chmod +x`).
Scripts must always be called directly — no interpreter prefix, no file extension.
This applies everywhere a script is invoked: SKILL.md, reference files, phase guides, docs.

Good: `./scripts/validate -f input.json`
Bad: `python3 ./scripts/validate.py -f input.json`

## Script paths

`./scripts/...` in SKILL.md is skill-relative shorthand.
Callers outside the skill directory must resolve it to an absolute path.
Use `<skill-dir>` as placeholder for the skill's base/install directory.

```bash
# From skill dir (docs shorthand):
./scripts/validate -f input.json

# From elsewhere — use absolute path; quote if path may contain spaces:
"<skill-dir>/scripts/validate" <args>
```

Prefer a stable executable name so callers do not need to guess `*.py` vs executable.
In tests and automation, resolve the script path relative to the test file — never assume working directory.

## Documenting scripts

This rule applies to SKILL.md, reference files, phase guides, and any other docs describing a script.

Describe interface only: script name, purpose, accepted flags (short form only).
Avoid internal impl (logic, loops, helpers, error handling details) — the script's own output communicates that.

Good: `./scripts/check --refs` to validate references.
Bad: `check` iterates over each ref, calls `curl` to verify, then writes failures to stderr.

## Tests

Test files in `scripts/tests/`.
One `.bats` file per script (split only for very complex scripts).
Fixture files alongside tests in `scripts/tests/` (no separate `fixtures/` subdir).

Keep scripts and tests in `$draftpath` during iteration.
`Phase:Ship` copies them to final `$installpath` alongside other skill-related files.
