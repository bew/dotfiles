# Python module code rules

Rules for Python module code — `.py` files imported by other modules.
These extend the generic module rules. All generic module rules still apply.

## Rules

- No shebang.
- Never call `sys.exit` from a module — raise exceptions instead.
- No top-level `#` comment or docstring on the module file.
  Library/module files are self-documented by their public API and docstrings.
- Top-level code: classes, functions, and variable/constant definitions only.
  No imperative logic at module level (no function calls, no print, no I/O).

## Guidelines

- Follow stdlib import ordering: stdlib → third-party → local.
  Separate each group with a blank line.
- Prefix internal helpers with `_` to signal they are not part of the public API.
