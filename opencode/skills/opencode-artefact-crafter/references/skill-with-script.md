# Building a Skill with a Script

Read this file when drafting a skill that includes one or more scripts in `scripts/`.

## Script basics

- Default to Python for new scripts (`#!/usr/bin/env python3`) unless the skill targets shell workflows.
- Add shebang, make executable (`chmod +x`)
- Run via the script directly — no interpreter prefix in usage examples.

Good: `./scripts/validate -f input.json`
Bad: `bash ./scripts/validate.sh -f input.json`

## What goes in SKILL.md vs the script

SKILL.md describes **interface only**: script name, purpose, accepted flags (short form only).
SKILL.md should avoid mentioning internal impl (logic, loops, helpers, parsing), unless specific risks to expect.
That belongs in the script itself or its inline comments.

Good: `./scripts/check --refs` to validate references.
Bad: `check` iterates over each ref, calls `curl` to verify, then writes failures to stderr.

## Tests

Test files live in `scripts/tests/`.
One `.bats` file per script (split only for very complex scripts).
Fixture files live longside tests in `scripts/tests/` (no separate `fixtures/` subdir).

During iteration, scripts and tests live in the `$draftpath`.
`Phase:ship` will copy them to final `$installpath` alongside other skill-related files.
