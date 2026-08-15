# Bash module code rules

Rules for bash module code — `.sh` files sourced by other scripts.
These extend the generic module rules. All generic module rules still apply.

## Rules

- Never add a shebang to a module file — it is sourced, not executed directly.
- Never call `exit` at the top level of a module — it would terminate the sourcing shell.
  Signal failure by returning a non-zero status from functions.
- Never use `set -euo pipefail` at the top level of a module.
  The sourcing script controls its own error handling.
- Use `.sh` extension for all module files.

## Guidelines

- `set -e` may be used inside individual functions if needed — it does not affect the sourcing shell.
- Prefix internal helper functions with `_` to signal they are not part of the public API.
- Guard against double-sourcing with a sentinel variable if the module has side-effectful
  initialization logic (e.g. setting up global state).
