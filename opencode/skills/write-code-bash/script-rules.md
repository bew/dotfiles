# Bash script code rules

Rules for bash script code.
These extend the generic script rules. All generic script rules still apply.

## Rules

- Always use `#!/usr/bin/env bash` as shebang.
- Always add `set -euo pipefail` immediately after the script header comment.
- No file extension — script code is executable, run directly.

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
