# Building a Skill with a Script

## Script basics

- Default to Python for new scripts (`#!/usr/bin/env python3`) unless skill targets shell workflows.
- Add shebang, make executable (`chmod +x`).
- Run script directly — no interpreter prefix in usage examples.

Good: `./scripts/validate -f input.json`
Bad: `python3 ./scripts/validate.py -f input.json`

## What goes in SKILL.md vs the script

SKILL.md describes **interface only**: script name, purpose, accepted flags (short form only).
Avoid mentioning internal impl (logic, loops, helpers, parsing) unless specific risks expected.
That belongs in script itself or inline comments.

Good: `./scripts/check --refs` to validate references.
Bad: `check` iterates over each ref, calls `curl` to verify, then writes failures to stderr.

## Tests

Test files in `scripts/tests/`.
One `.bats` file per script (split only for very complex scripts).
Fixture files alongside tests in `scripts/tests/` (no separate `fixtures/` subdir).

During iteration, scripts and tests live in the `$draftpath`.
`Phase:ship` will copy them to final `$installpath` alongside other skill-related files.
