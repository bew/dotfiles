# Nushell script code rules

Rules for Nushell script code.
These extend the generic script rules. All generic script rules still apply.

## Rules

- Always use `#!/usr/bin/env nu` as shebang.
- Define the entry point as `def main [...] { ... }` — Nushell calls it automatically when the script is run.
- Never call `exit` inside `main` or helpers to signal failure — use `error make { msg: "..." }`.
- No file extension — script code is executable, run directly.

## Full script boilerplate

```nu
#!/usr/bin/env nu

# Short (1-2 line) description of what the script does.

# Print message to stderr.
def print-err [msg: string]: nothing -> nothing {
    print --stderr $msg
}

# Entry point: description of the script and its arguments
def main [
    required_arg: string  # what this arg means
    optional_arg?: int    # optional, defaults to null
    --flag                # boolean flag
]: nothing -> nothing {
    # Main logic
}
```
