# demo-crate

Demonstration package used by the mechanical-checks test suite.

## Layout

- `main.rs` — binary entry point.
- `lib.rs` — library root.
- `docs/guide.md` — usage guide.
- `Cargo.toml` — manifest.

## Should be skipped

- URL: `https://example.com/a/b`
- Command: `cargo build --release`
- Glob: `src/*.rs`
- Feature: `window/wayland`

```
inside-fence.rs
```
