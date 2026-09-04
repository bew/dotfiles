# Module code rules

Rules for module code — files imported, required, or sourced by other code.
These extend `write-code-generic`. All generic rules still apply.

## Rules

- No top-level side effects.
  Top-level code must be declarations only: constants, class definitions, function definitions.
  Never print, write files, make network calls, or exit at module level.
- Never call `exit` (or language equivalent) from a module.
  Signal failure by raising an exception or returning an error value.
- Expose a minimal public surface.
  Only export symbols that callers need.
  Keep helpers private (prefix with `_` or equivalent).
- Never reference CLI interface surface in module code comments.
  Describe behaviour in terms of the language's types and values, not flags,
  positional arg names, or env-var names that belong to the caller's layer.

