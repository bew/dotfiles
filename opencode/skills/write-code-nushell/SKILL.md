---
name: write-code-nushell
description: |
  Nushell code writing guidelines: idioms, types, entry point, error handling.
  Always load when asked to draft/write/edit/refactor/review Nushell (.nu) code files.
metadata:
  maintainers: [bew]
---

## Goal

Write Nushell code using native idioms: typed parameters, structured data, and proper error handling.

REQUIRES: load `write-code-generic` skill first.

In Nushell, **module code** is any `.nu` file loaded via `use` or `source` by other code — no shebang,
uses `export def` to expose public commands.
**Script code** is a file run directly: has a shebang (`#!/usr/bin/env nu`) and defines `def main [...]`.

If working on **module code**: read <./module-rules.md>.
If working on **script code**: read <./script-rules.md>.

## Rules

- Annotate all parameters with types (e.g. `name: string`, `items: list<string>`, `count?: int`).
- Place the docstring comment directly above the `def` — nushell uses it as the command's help text.
- Use `let` for immutable locals, `mut` for mutable locals.
- Use `const` for compile-time constants.
- Use `error make { msg: "..." }` to signal errors — never `print` + `exit`.
- Access optional env vars with `$env.VAR?` (returns `null` if unset, no crash).
- Use `$env.FILE_PWD` for the file's own directory — not a `$SCRIPT_DIR` workaround.

## Guidelines

- Prefer pipeline style (`$data | each { ... }`) over imperative loops when natural.
- Use `$in` to receive piped input inside a `def`; declare the pipeline signature
  with `: inputtype -> outputtype` for clarity.
- Prefer `let` over `mut` — reach for `mut` only when re-assignment is truly needed.
- Flags are declared as `--flag-name` parameters in the `def` signature, not parsed manually.

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

## Testing

No dedicated Nushell testing skill exists yet.
Ask the user how they want tests structured before writing any.
