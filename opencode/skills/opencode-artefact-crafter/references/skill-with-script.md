# Building a Skill with a Script

## Script basics

- Default to Python for new scripts (`#!/usr/bin/env python3`) unless skill targets shell workflows.
- Add shebang, make executable (`chmod +x`).
- Run script directly — no interpreter prefix in usage examples.

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

## What goes in SKILL.md vs the script

Describe interface only: script name, purpose, accepted flags (short form only).
Avoid internal impl (logic, loops, helpers, parsing) unless specific risks expected.
Put that in the script itself or inline comments.

Good: `./scripts/check --refs` to validate references.
Bad: `check` iterates over each ref, calls `curl` to verify, then writes failures to stderr.

## Tests

Test files in `scripts/tests/`.
One `.bats` file per script (split only for very complex scripts).
Fixture files alongside tests in `scripts/tests/` (no separate `fixtures/` subdir).

Keep scripts and tests in `$draftpath` during iteration.
`Phase:ship` copies them to final `$installpath` alongside other skill-related files.
