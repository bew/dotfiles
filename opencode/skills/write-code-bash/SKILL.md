---
name: write-code-bash
description: |
  Bash code writing guidelines: shebang, strict mode, bash idioms, and full boilerplate.
  Always load when asked to draft/write/edit/refactor/review bash code files.
metadata:
  maintainers: [bew]
---

## Goal

Write bash scripts following strict-mode conventions and bash idioms, building on `write-code-generic` rules.

REQUIRES: load `write-code-generic` skill first.

In bash, **module code** is a `.sh` file sourced by other scripts (no shebang).
**Script code** is an executable run directly: no file extension, shebang + `main "$@"` at end.

If working on **module code**: read <./module-rules.md>.
If working on **script code**: read <./script-rules.md>.

## Rules

- Use `[[ ... ]]` over `[ ... ]` for all conditional expressions.
- Use `(( ... ))` over `[[ ... ]]` for numeric comparisons.
- Always quote variables: `"$var"`, `"$@"`, `"${arr[@]}"`.
- Use `function name() { ... }` style — always include the `function` keyword.
- Use `${VAR:-default}` for optional arguments and env var defaults with fallback values.
- In bash, also add *what* comments when the syntax itself is non-obvious —
  e.g. symbol-heavy expressions, unusual pipeline ordering, or constructs that read backwards.
- When a pipeline step may cause SIGPIPE (e.g. piping into `head`): temporarily disable
  `pipefail` with `set +o pipefail`, then re-enable.
  Always add a comment explaining why it is disabled.

## Function parameters

Always assign positional parameters to named local variables at the start of the function.
Never use `$1`, `$2`, etc. directly in the function body (except trivial one-liners).

```bash
# Good
function process_file() {
    local file_path="$1"
    local mode="$2"

    if [[ -f "$file_path" ]]; then
        echo "Processing $file_path in $mode mode"
    fi
}

# Bad — bare positionals used throughout body
function process_file() {
    if [[ -f "$1" ]]; then
        echo "Processing $1 in $2 mode"
    fi
}
```

## Conditions with computations

When a condition requires a computation or function call, extract the result to a local variable first.
Avoid embedding calls inside `if` expressions.

```bash
# Good — extract complex condition to separate steps, then simple if
function validate_input() {
    local input="$1"

    if check_format "$input" && check_length "$input"; then
        process_input "$input"
    fi
}

# Good — simple inline check with a single function call is fine
function main() {
    if [[ $# -gt 0 ]] && check_is_number "$1"; then
        local length="$1"
        shift
    fi
}

# Bad — multiline condition with embedded subshell logic
function validate_input() {
    local input="$1"

    if [[ -n $(check_format "$input" && \
              check_length "$input") ]]; then
        process_input "$input"
    fi
}
```

## Output capture

When capturing command output to a local variable, declare separately from the assignment.
`local` always exits 0 in bash, swallowing the real exit code otherwise:

```bash
# Good — separate declaration preserves exit code from get_charset
local charset
charset=$(get_charset "$rule")

# Bad — local always exits 0, swallowing errors
local charset=$(get_charset "$rule")
```

Check success when capturing potentially-failing output:

```bash
local result
if ! result=$(potentially_failing_cmd 2>&1); then
    echo_err "Error: cmd failed: $result"
    exit 1
fi
```

Disable pipefail for SIGPIPE-prone pipelines:

```bash
local output
# head causes SIGPIPE when it closes the pipe early
set +o pipefail
output=$(some_cmd | head -n1)
set -o pipefail
```

## Testing

The standard testing system for bash scripts in this repo is **Bats** (Bash Automated Testing System).

Load `write-code-bats` skill when writing or running tests for a bash script.

When writing a bash script, propose the companion `.bats` test file — do not wait to be asked.
