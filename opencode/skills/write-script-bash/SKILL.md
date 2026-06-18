---
name: write-script-bash
description: |
  Bash script writing guidelines: shebang, strict mode, bash idioms, and full boilerplate.
  Auto-load when writing or reviewing bash scripts.
  Loads write-script-generic for language-agnostic rules.
metadata:
  maintainers: [bew]
---

## Goal

Write bash scripts following strict-mode conventions and bash idioms, building on `write-script-generic` rules.

NOTE: Load `write-script-generic` skill first — it defines the shared structure, naming conventions, and error-handling rules this skill builds on.

## Rules

- Always use `#!/usr/bin/env bash` as shebang.
- Always add `set -euo pipefail` immediately after the script header comment.
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

Separate variable declaration (bash-specific: `local` always exits 0, swallowing the real exit code):

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


## Full script boilerplate

```bash
#!/usr/bin/env bash

# Short (1-2 line) description of the script.

set -euo pipefail

# Print message to stderr.
# Uses "$*" (not "$@") — joins all arguments into one string, which is correct for a message helper.
function echo_err() {
    echo >&2 "$*"
}

# Print usage to stderr and exit with given status
function usage_and_exit() {
    local status="$1"
    cat >&2 <<'EOF'
Usage: script-name ARGS...

Description of the script.

EXAMPLES:
  script-name example1    - What this does
  script-name example2    - What this does
EOF
    exit "$status"
}

# Entry point
function main() {
    if [[ $# -eq 0 ]]; then
        usage_and_exit 1
    fi

    # Main logic
}

main "$@"
```

## Testing

The standard testing system for bash scripts in this repo is **Bats** (Bash Automated Testing System).

Load `write-script-bats` skill when writing or running tests for a bash script.
