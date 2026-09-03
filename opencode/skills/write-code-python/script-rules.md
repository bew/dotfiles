# Python script code rules

Rules for Python script code.
These extend the generic script rules. All generic script rules still apply.

## Rules

- Always add a shebang: `#!/usr/bin/env python3`.
- Use `if __name__ == "__main__":` as the entrypoint guard.
- No top-level imperative code outside the `if __name__ == "__main__":` block.
  Top-level code is: imports, constants, class/function definitions, and the entrypoint guard.
- Define a `ScriptError(Exception)` class at the top of the script, right after imports/constants.
- Raise `ScriptError` (or a subclass) from any function that hits an error the script should report.
- `main()` returns `bool` — `True` on success, `False` on failure.
  Exit via `sys.exit(0 if main() else 1)`.
- In `main`, wrap the dispatch in `try`/`except ScriptError` (plus any distinct concrete
  exceptions the handlers raise, e.g. `OSError`, `json.JSONDecodeError`); on catch, print to
  stderr and return `False`.
- The `try` body must never raise a type outside the caught set — e.g. raise `ScriptError`
  for unknown commands rather than `ValueError`.

## File header

Add a top-level `#` comment immediately after the shebang — one line describing what the script does.

```python
#!/usr/bin/env python3
# Generate a random string of given length and print it to stdout.
```

## Script structure

```python
#!/usr/bin/env python3
# One-line description of what this script does.

import sys
# [other stdlib imports]
# [third-party imports]

# [top-level constants — SCREAMING_SNAKE_CASE]


class ScriptError(Exception):
    """Raised when the script encounters an error."""


def print_err(msg: str) -> None:
    """Print msg to stderr."""
    print(msg, file=sys.stderr)


def usage_and_exit(status: int) -> None:
    """Print usage to stderr and exit with status."""
    print_err("Usage: script-name [options]")
    sys.exit(status)


# [helper functions — raise ScriptError on failure]


def main() -> bool:
    args = parse_args()
    ...
    # [call helpers / match args.command]
    ...
    return True


if __name__ == "__main__":
    try:
        sys.exit(0 if main() else 1)
    except ScriptError as exc:
        print_err(f"ERROR: {exc}")
        sys.exit(1)
```

## CLI subcommand parsing

- Use `argparse.add_subparsers()` for multi-command CLIs.
  (Never use positional-only commands nor `choices` with `nargs="?"`)
  (Never use `parse_known_args()` as a workaround for subcommand arguments)
- Each subcommand must dispatch to a dedicated `cmd_<name>()` function.
  Never inline subcommand logic in the dispatch block.

```python
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()

    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("refresh")

    hook_cmd = sub.add_parser("hook")
    hook_cmd.add_argument("lang", choices=["zsh"], help="shell language")

    return parser.parse_args()


def cmd_refresh() -> None:
    ...


def cmd_hook(args: argparse.Namespace) -> None:
    ...


def main() -> bool:
    args = parse_args()
    ...
    match args.command:
        case "refresh":
            cmd_refresh()
        case "hook":
            cmd_hook(args)
        case _:
            raise ScriptError(f"Unknown command: {args.command}")
    ...
    return True
```
