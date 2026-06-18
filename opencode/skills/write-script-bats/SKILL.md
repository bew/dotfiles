---
name: write-script-bats
description: |
  Bats test file writing guidelines: file structure, test naming, setup conventions, and helpers.
  Auto-load when writing or reviewing .bats test files.
metadata:
  maintainers: [bew]
---

## Goal

Write well-structured Bats test files following consistent naming, setup, and assertion conventions.

NOTE: Load `write-script-generic` skill first — it defines the shared structure, naming conventions, and error-handling rules this skill builds on.
NOTE: Function bodies inside `@test` blocks and helper functions follow `write-script-bash` conventions.

## Rules

- Name test file `<script-name>.bats` — same name as the script under test.
- Always declare `bats_require_minimum_version 1.5.0` after the header comment.
- Use `SCRIPT_DIR` and `SCRIPT_PATH` globals to reference the tested script — never hardcode paths.
- `setup()` must contain only preparation shared by ALL tests.
  Test-specific setup goes inside the `@test` block itself.
- Omit `setup()` entirely if nothing is shared across all tests.
- Use `setup_file()` (runs once before all tests) for suite-wide isolation — e.g. stripping the
  environment down to essential variables so tests don't leak from the caller's env.
  Do not use `setup_file()` for per-test preparation.
- Use `--keep-empty-lines` on `run` when the script under test produces meaningful blank lines.
  Without it, bats strips trailing blank lines from `$output`.
- Test names must follow format `"topic: summary"`.
- Write `helpers` topic tests first in the file.
- Use `run -N` to assert exit code inline (e.g. `run -0`, `run -1`).
- When testing stderr output, use `--separate-stderr` flag on `run`.
  Access stderr via `$stderr`, stdout via `$output`.
- Custom assertion helpers must be prefixed `assert_`.
- Test execution wrappers must be prefixed `run_`.
- Setup helpers (beyond the shared `setup()`) must be prefixed `setup_`.

## Test topics (canonical list)

Use these topic prefixes in test names:

| Topic | Purpose |
|---|---|
| `helpers` | Tests for custom `assert_*` helpers |
| `defaults` | Default behavior without any flags |
| `cli` | Command-line argument and flag handling |
| `error` | Error handling and validation |
| `usage` | Help/usage message output |
| `edge` | Edge cases and unusual inputs |
| `integration` | Piping, chaining with other tools |

## File header

```bash
# Test suite for `<script-name>` script
#
# % Uses BATS testing system
# docs: https://bats-core.readthedocs.io/
# repo: https://github.com/bats-core/bats-core
#
# Run tests with: `bats $this_file [--filter foobar]`
```

## File structure

```bash
# [header comment]

bats_require_minimum_version 1.5.0

SCRIPT_DIR="$(dirname "$BATS_TEST_FILENAME")"
SCRIPT_PATH="$SCRIPT_DIR/<script-name>"

# Shared setup — omit entirely if nothing is shared across all tests
function setup() {
    export SOME_VAR="for-all-tests"
}

# ------------------------------------------------------------------------------
# Tests: helpers

@test "helpers: assert_length works" { ... }

# ------------------------------------------------------------------------------
# Tests: defaults

@test "defaults: generates expected output" { ... }
```

## Test examples

```bash
@test "defaults: generates 32-char string" {
    run -0 "$SCRIPT_PATH"
    [[ "${#output}" -eq 32 ]]
}

@test "cli: accepts length as positional argument" {
    run -0 "$SCRIPT_PATH" 16
    [[ "${#output}" -eq 16 ]]
}

@test "error: rejects non-numeric length" {
    run -1 --separate-stderr "$SCRIPT_PATH" abc
    [[ "$stderr" == *"Error:"* ]]
}
```

## Section separators

Group tests by topic using `# Tests: <topic>` headers:

```bash
# ------------------------------------------------------------------------------
# Tests: cli
```

## `run_script` wrapper helpers

When many tests call the same script with similar setup, define script-specific wrappers:

```bash
# Run the script expecting success; sets $output
function run_script() {
    run -0 "$SCRIPT_PATH" "$@"
}

# Run the script expecting failure; sets $output and $status
function run_script_failed() {
    run -1 "$SCRIPT_PATH" "$@"
}
```

These are script-specific — define them per `.bats` file, not as shared helpers.

## Running tests

```bash
bats script.bats              # all tests
bats script.bats -f "topic"   # tests matching pattern
```

## References

- Bats docs: https://bats-core.readthedocs.io/en/stable/writing-tests.html
