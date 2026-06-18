---
name: write-script-generic
description: |
  General script writing guidelines: structure, naming, error handling, and organization.
  Language-agnostic. Auto-load when writing or reviewing any script.
  Language-specific skills (write-script-bash, write-script-bats) build on top of this.
metadata:
  maintainers: [bew]
---

NOTE: This skill is a reference rule-set, not a workflow — no Steps section.

## Goal

Apply consistent structure, naming, and error-handling conventions when writing scripts.

## Rules

- Always add a top-level comment at the start of the script: short description of what it does,
  optionally how to use it (keep to 1-2 lines), and links to inspiration or upstream sources if any.
- Always split script into functions — no top-level logic outside `main`.
- Use descriptive function names with a verb (e.g. `parse_args`, `check_format`).
- Add a short comment above every function explaining its purpose or why it exists.
  One line is enough for simple helpers.
  A few lines for non-obvious ones.
- Inline comments inside function bodies must explain *why*, not *what*.
  Skip comments that restate what the code already says.
  Write them when the intent, constraint, or reason is not obvious from the code alone.
- Assign positional parameters to named local variables at the start of every function.
  Never reference bare positionals (`$1`, `$2`) in function bodies (except trivial one-liners).
- Scope variables to their function — never leak intermediate values as globals.
- Always provide an entry point: call `main` at the end of the file, forwarding all args.
- Always exit with explicit status codes — never let scripts silently succeed on failure.

## Guidelines

- Prefer `get_*` for functions that compute/return a value.
- Prefer `check_*` for validation functions.
- Prefer `parse_*` for argument/input parsing.
- Use section separators when a script has 5 or more functions.
  Not needed for smaller scripts.
- Top-level constants: SCREAMING_SNAKE_CASE, defined at top of file after header.
- Mutable globals (parsed args, state): SCREAMING_SNAKE_CASE, declared in `main` or `parse_args`.
- When capturing command output, declare the variable separately before assignment.
  This avoids swallowing exit codes.
- When a condition requires a computation or function call, extract the result to a local variable first.
  Then write a simple condition — avoid embedding calls inside `if` expressions.
- Guard against missing external dependencies at the top of the script with a short-circuit exit.
  Check before any logic runs, not inline when the tool is first used.
- Use type annotations for parameters and variables whenever the language supports it.
  Prefer explicit types over implicit ones — they serve as inline documentation.

## Standard function names

Use these names consistently across scripts:

| Name | Purpose |
|---|---|
| `main` | Entry point — called at end of file with forwarded args |
| `usage_and_exit` | Print usage/help to stderr, exit with given status |
| `print_err` | Print message to stderr |
| `cmd_*` | Subcommand handler (e.g. `cmd_build`, `cmd_deploy`) |

### Subcommands with `cmd_*`

When a script has multiple subcommands, implement each as a `cmd_<name>` function.
Dispatch in `main` with a switch/case on the first argument:

```pseudo-code
# Dispatch to subcommand handler or show usage
main(cmd, ...rest):
    case cmd:
        "build"  -> cmd_build(...rest)
        "deploy" -> cmd_deploy(...rest)
        *        -> print_err("Unknown command: " + cmd); usage_and_exit(1)
```

## Error messages

Error messages must be actionable: explain what went wrong AND how to fix it.

```pseudo-code
# Good
print_err "Error: --len requires an argument"
print_err "Example: gen-random-string --len 16"

# Good
print_err "Error: unknown rule: $rule"
print_err "Run with --help to see available rules"

# Bad
print_err "Error: invalid input"
```

## Testing

Before writing or modifying a script, ask the user:
- Are there existing tests for this script?
- Should tests be written alongside to verify the script works?

Use tests actively during development — run them after each meaningful change to verify correctness.
Do not treat testing as a post-step.

If tests are wanted and none exist, load the appropriate lang-specific testing skill before starting.
If no testing skill exists for the language, ask the user how they want tests structured before writing any.

## Script structure

```pseudo-code
[shebang]

# Short (1-2 line) description of what the script does and when to use it.

[top-level constants — if any]

print_err(...) { ... }
usage_and_exit(status) { ... }

[helper functions]

main(...args) {
    [mutable globals for parsed args — declared here]
    [main logic]
}

main(forwarded args)
```

### `usage_and_exit` contract

Takes a status code as first argument.
Prints usage to stderr.
Exits with that code.
