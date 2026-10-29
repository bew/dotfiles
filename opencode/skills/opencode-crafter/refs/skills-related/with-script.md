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

A skill script runs on the user's machine, not inside a project environment.
Constraints:
- Standard library only.
- No dependency install at run time.
- No virtualenv.
- No packaging metadata.

A third-party import turns a skill into a setup task for whoever installs it.

Test tooling is the exception: `bats` and `pytest` run on the developer's machine,
never invoked by the script itself.

Skill scripts run unattended.
No stdin question, no pager, no editor, no progress spinner.
Refuse the operation and name the way forward in the message.

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

The documented path is a contract: reference files and tests quote `scripts/<name>` verbatim.
The executable keeps its name and its directory for the life of the skill.
Implementation may move into a package beside it.

## Behaviour at run time

The caller is an agent that reads stdout and repeats values into its next step.
Print every value the caller must reuse as a stable `key = value` line.
One per line, in a deterministic order.
No colour, no decoration.
A run that changed nothing says so, instead of printing nothing.

Report what this run changed, not a dump of the tree.
That corrects the agent's own picture instead of redrawing it.

Name the two failure regimes in the docs.
One refuses before anything is written.
The other stops after part of the change landed, and prints the repair command to stderr.
An agent not told otherwise runs the same command again.

Change only paths the caller names.
Never infer a path to modify from the working directory or from the script's own location.
Reading the skill's own files is fine — resolve them from the script's own location.
Refuse to sweep unrelated work along with the intended change.
No one reviews a stray deletion before it happens.

Exit status is a branch signal: `0` did the work, `1` refused or failed part-way, `2` bad usage.

## Python skill scripts

Start every Python skill script as one executable file plus its `.bats` end-to-end suite.
Move its body into a `scripts/lib/` package only when it outgrows one file and the user agrees to
restructure it — read <./with-script-python-split.md> for that layout.

## Documenting scripts

This rule applies to SKILL.md, reference files, phase guides, and any other docs describing a script.

Describe the interface only: script name, purpose, accepted flags (short form only), the stdout keys,
the exit statuses, and the two failure regimes.
Avoid internal impl (logic, loops, helpers, per-error messaging) — the script's own output communicates that.

Good: `./scripts/check --refs` to validate references.
Bad: `check` iterates over each ref, calls `curl` to verify, then writes failures to stderr.

## Tests

The `.bats` suite sits alongside its script in `scripts/`.

If additional files are needed (e.g. fixture files), place them in `scripts/test-fixtures/`.
One `.bats` file per script (split only for very complex scripts).
It drives the entry point end to end and asserts stdout, exit status, and the files left on disk.

A `scripts/lib/` split also carries a pytest suite — see
<./with-script-python-split.md>.

Test files and fixtures are internal QA artefacts — not part of the skill's documented interface.
Never reference them from `SKILL.md`, reference files, phase guides, or any other docs.

Keep scripts and tests in `$draftpath` during iteration.
`Phase:Ship` copies them to final `$installpath` alongside other skill-related files.
