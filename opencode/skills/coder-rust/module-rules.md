# Rust module code rules

Rules for module code — `.rs` files imported via `mod` and `use`.
These extend `coder-rust` (which extends the generic module rules).
All generic module rules still apply.

## Rules

- No `fn main()` in module files.
  Module files are libraries — they expose types and functions for other code.
- Prefer `pub(crate)` over `pub` unless the symbol is genuinely part of a public API
  exposed to external crates.
- Keep helper types private.
  Prefer `struct Foo { ... }` (no `pub`) for types that are only used within the module
  or by sibling modules via `pub(crate)`.
- When a function's behaviour varies by a boolean flag, describe what happens when
  it is `true` vs `false`.
