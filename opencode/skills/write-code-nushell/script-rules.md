# Nushell script code rules

Rules for Nushell script code.
These extend the generic script rules. All generic script rules still apply.

## Rules

- Always use `#!/usr/bin/env nu` as shebang.
- Define the entry point as `def main [...] { ... }` — Nushell calls it automatically
  when the script is run.
- No file extension — script code is executable, run directly.

## Error handling

- Signal anticipated errors with a `fail` helper: define it once in the script,
  then call it at every error site in `main` and helpers.
- Don't use `error make` — it raises a catchable error and prints an error trace
  that is not useful for script users. Reserve it for module code
  (files `use`d/`source`d as libraries).
- A script and every helper it defines use `fail` for errors.
  The script's job is to terminate with a clean message.
  Reusability does not change this: a reusable helper inside a script is still script code.

## Full script boilerplate

```nu
#!/usr/bin/env nu

# Short (1-2 line) description of what the script does.

# Print error message & exit now
def fail [msg: string]: nothing -> nothing {
    print --stderr $"!! ERROR: ($msg)"
    exit 1
}

def main [
    required_arg: string  # what this arg means
    optional_arg?: int    # optional, defaults to null
    --flag                # boolean flag
]: nothing -> nothing {
    # Main logic
}
```
