# Rust script code rules

Rules for script code — binary crate entrypoints (files with `fn main()`).
These extend `coder-rust` (which extends the generic script rules).
All generic script rules still apply.

## Entrypoint

Rust binary crates have a single `fn main()` — no forwarding needed.
The file is conventionally `src/main.rs`.
Additional binaries use `src/bin/*.rs` with `[[bin]]` sections in Cargo.toml.

## Error handling

- Use `anyhow::Result<T>` for fallible functions in the binary.
- `fn main() -> anyhow::Result<()>` — propagate errors with `?`.
- Use `.context("...")` from anyhow to add context to errors.
- Error output is handled by anyhow — no explicit stderr printing needed.

## CLI parsing

Use `clap` with derive macros.
The `#[command(about)]` doc comment on the struct becomes the `--help` description.

- The top-level file comment is 1-2 lines summarising what the binary does.
  Do not duplicate usage instructions — those belong in clap's `after_help`.
- `after_help` uses a native multiline string literal for examples:

```rust
#[command(
    about,
    after_help = r#"
EXAMPLES:
  gh-pr-comments 123
  gh-pr-comments owner/repo:123 --unresolved
"#
)]
```

## Args struct

Place CLI-visible doc comments on `Args` struct fields (clap uses them for `--help`).
Do not duplicate these descriptions in the module-level header comment.

## Test utilities

When `main.rs` contains test helpers used by `#[cfg(test)]` modules in sibling files,
extract them into a test-only module or keep them in the file that exercises them.
Do not add `#[cfg(test)] pub fn` to main.rs purely for other modules — use a shared
test-utilities crate or inline the helpers where needed.
