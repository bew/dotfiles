# Python script code rules

Rules for Python script code.
These extend the generic script rules. All generic script rules still apply.

## Rules

- Always add a shebang: `#!/usr/bin/env python3`.
- Use `if __name__ == "__main__":` as the entrypoint guard.
- No top-level imperative code outside the `if __name__ == "__main__":` block.
  Top-level code is: imports, constants, class/function definitions, and the entrypoint guard.
- `main()` returns `bool` — `True` on success, `False` on failure.
  Exit via `sys.exit(0 if main() else 1)`.
- Catch exceptions at the boundary in `main`; print to stderr and return `False` on failure.
  Never let exceptions propagate out of `main` uncaught.

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


def print_err(msg: str) -> None:
    """Print msg to stderr."""
    print(msg, file=sys.stderr)


def usage_and_exit(status: int) -> None:
    """Print usage to stderr and exit with status."""
    print_err("Usage: script-name [options]")
    sys.exit(status)


# [helper functions]


def main() -> bool:
    # [parse args, call helpers]
    # Return True on success, False on failure.
    return True


if __name__ == "__main__":
    sys.exit(0 if main() else 1)
```
