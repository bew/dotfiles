---
name: write-script-nushell
description: |
  Nushell script writing guidelines: idioms, types, entry point, error handling.
  Auto-load when writing or reviewing Nushell (.nu) scripts.
metadata:
  maintainers: [bew]
---

## Goal

Write Nushell scripts using native idioms: typed parameters, structured data, and proper error handling.

NOTE: Load `write-script-generic` skill first — it defines the shared structure, naming conventions, and error-handling rules this skill builds on.

## Rules

- Always use `#!/usr/bin/env nu` as shebang.
- Define the entry point as `def main [...] { ... }` with typed, documented parameters.
- Annotate all parameters with types (e.g. `name: string`, `items: list<string>`, `count?: int`).
- Place the docstring comment directly above the `def` — nushell uses it as the command's help text.
- Use `let` for immutable locals, `mut` for mutable locals.
- Use `const` for compile-time constants.
- Use `error make { msg: "..." }` to signal errors — never echo + exit.
- Access optional env vars with `$env.VAR?` (returns `null` if unset, no crash).
- Use `$env.FILE_PWD` for the script's own directory — not a `$SCRIPT_DIR` workaround.

## Guidelines

- Prefer pipeline style (`$data | each { ... }`) over imperative loops when natural.
- Use `$in` to receive piped input inside a `def`; declare the pipeline signature
  with `: inputtype -> outputtype` for clarity.
- Prefer `let` over `mut` — reach for `mut` only when re-assignment is truly needed.
- Flags are declared as `--flag-name` parameters in the `def` signature, not parsed manually.

## Script structure

```nu
#!/usr/bin/env nu

# [optional: const declarations for compile-time constants]
const SOME_CONST = "value"

# Helper: short description of what this does
def helper-name [param: string]: nothing -> string {
    # ...
}

# Entry point: description of the script and its arguments
def main [
    required_arg: string  # what this arg means
    optional_arg?: int    # optional, defaults to null
    --flag                # boolean flag
]: nothing -> nothing {
    # ...
}
```

## Parameter style

```nu
# Good — typed, documented
def process [
    path: string       # file to process
    mode?: string      # "fast" or "careful" (default: "fast")
    --verbose          # enable verbose output
]: nothing -> nothing { ... }

# Bad — untyped, undocumented
def process [path mode] { ... }
```

## Testing

No dedicated Nushell testing skill exists yet.
Ask the user how they want tests structured before writing any.

## Error handling

```nu
# Good
if not ($path | path exists) {
    error make { msg: $"File not found: ($path)" }
}

# Bad
print $"Error: file not found"
exit 1
```
