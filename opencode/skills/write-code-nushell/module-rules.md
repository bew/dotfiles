# Nushell module code rules

Rules for Nushell module code — `.nu` files loaded via `use` or `source` by other code.
These extend the generic module rules. All generic module rules still apply.

## Rules

- Never add a shebang to a module file — it is loaded, not executed directly.
- Never call `exit` at the top level or inside exported defs — it would terminate the calling shell.
  Signal failure with `error make { msg: "..." }`.
- Use `export def` to expose public commands; plain `def` is private to the module.
- No top-level imperative code — only `const`, `def`, and `export def` declarations.
- Use `.nu` extension for all module files.

## Guidelines

- Prefix internal helpers with `_` or use plain (non-exported) `def` to signal they are not public API.
- Group related exported commands together; put helpers after them.
