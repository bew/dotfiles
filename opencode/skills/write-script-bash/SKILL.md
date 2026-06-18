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
- When a pipeline step may cause SIGPIPE (e.g. piping into `head`): temporarily disable
  `pipefail` with `set +o pipefail`, then re-enable.
  Always add a comment explaining why it is disabled.

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

## Section separators

Syntax for grouping sections (see `write-script-generic` for when to use them):

```bash
# ------------------------------------------------------------------------------
# Section Name
```
