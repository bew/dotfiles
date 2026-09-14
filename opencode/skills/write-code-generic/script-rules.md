# Script code rules

Reference for script code rules. Load this when working on script code — a file
with a shebang, a `main` entry point, or a language-level entrypoint guard.

These rules extend `write-code-generic`. All generic rules still apply.

## What makes script code

Script code is a standalone executable entrypoint — run directly, not imported.
Signals: shebang line, a `main` function called at end of file, or a language-level
entrypoint guard.

Script code is NOT a library, module, or helper file that is sourced/imported by other code.
They are module code — read <./module-rules.md> instead.

## Rules

- Always add a top-level comment at the start of a script entrypoint file: short description of what it does,
  optionally how to use it (keep to 1-2 lines), and links to inspiration or upstream sources if any.
- Always split code into functions — no top-level logic outside `main`.
- Always provide an entry point: call `main` at the end of the file, forwarding all args.
- Always exit with error message to stderr and an error status code (usually `1`).
  Never let scripts silently succeed on failure.

## Guidelines

- Mutable globals (parsed args, state): SCREAMING_SNAKE_CASE, declared in `main` or `parse_args`.
- Guard against missing external dependencies at the top of the script with a short-circuit exit.
  Check before any logic runs, not inline when the tool is first used.

## Standard function names

Use these names consistently across scripts:

| Name | Purpose |
|---|---|
| `main` | Entry point — called at end of file with forwarded args |
| `fail` | Print formatted error to stderr and exit 1 |
| `usage_and_exit` | Print usage/help to stderr, exit with given status |
| `print_err` | Print message to stderr |
| `cmd_*` | Subcommand handler (e.g. `cmd_build`, `cmd_deploy`) |

### `fail` vs `usage_and_exit` vs `print_err`

Use `fail` for operational errors — something went wrong and the script cannot continue:
missing file, invalid input, network failure, assertion, external tool returned non-zero.
The main message explains what went wrong, with optional guidance.

Use `usage_and_exit` for usage guidance — the user asked for help, passed wrong flags,
omitted required args, or the script otherwise wants to show how to use it.

Use `print_err` when need multiple stderr messages
(e.g. batch validation reporting several errors at once).

### `fail` contract

Common form only has a single parameter, the operational error message.

For medium/complex scripts or if user requests it explicitely, an alternative form can have 1+
additional detail/guidance lines to be printed on their own line, indented to align after the `!! `
prefix (3 spaces indent).

A single param is usually enough for most programs, only make a version supporting multiple lines
if user asks for it.

Example expected error outputs:
```text
!! ERROR: --limit must be a positive integer, got 'abc'.
```
```text
!! ERROR: missing input file 'data.csv'
   Specify an input with --input.
```
- First line always gets the `!! ERROR:` prefix.
- Detail lines restart with a small alignment indent — no extra prefix.
- `fail` exits 1 after printing all lines.

### `usage_and_exit` contract

Takes a status code as first argument.
Prints usage to stderr.
Exits with that code.

The file-level header comment is an overview only — a short description of what the script does.
All actual usage details (arguments, flags, examples) belong in this usage function.

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
# Good — single-line operational error
fail("--len requires an argument")

# Good — concrete operational error with guidance
fail("unknown rule: $rule", "Use --help to see available rules", ...)

# Good — usage guidance (single call, exits immediately)
usage_and_exit(0)

# Bad — too abstract / not actionable
fail("invalid input")
```

## Testing

Before writing or modifying a script, ask the user:
- Are there existing tests for this script?
- Should tests be written alongside to verify the script works?

Also applies when rewriting a script in a different language — treat it as a new write.

Use tests actively during development — run them after each meaningful change to verify correctness.
Do not treat testing as a post-step.

If tests are wanted and none exist, load the appropriate lang-specific testing skill before starting.
If no testing skill exists for the language, ask the user how they want tests structured before writing any.

Test inputs must use values that are independent of the code under test.
Construct them from raw components or deserialize from a static fixture.
Never call the function you are testing to produce its own input — this only
proves the function is self-consistent, not correct.

For example, do not construct a datetime by parsing a string with the same
format specifier that `format_timestamp` outputs.
Build the input from year/month/day/.. components instead.

## Script structure

```pseudo-code
[shebang]

# Short (1-2 line) description of what the script does and when to use it.

[top-level constants — if any]

print_err(...) { ... }
fail(msg) { ... }
usage_and_exit(status) { ... }

[helper functions]

main(...args) {
    [mutable globals for parsed args — declared here]
    [main logic]
}

main(forwarded args)
```
