---
name: write-code-rust
description: |
  Rust code writing guidelines: idioms, type derivation, dependency management,
  test construction, and pre-commit checks.
  Always load when asked to draft/write/edit/refactor/review Rust code —
  including `.rs` files, `Cargo.toml` dependency blocks, and Rust module refactors.
metadata:
  maintainers: [bew]
---

## Goal

Write Rust code that is idiomatic, well-annotated, and passes clippy on the first build,
building on generic conventions.

REQUIRES: load `write-code-generic` skill first.

In Rust, **module code** is any `.rs` file that is imported via `mod` and `use` — it exports
types and functions for other code to consume. Module files never contain `fn main()`.
**Script code** is the binary crate entrypoint — `main.rs` (or another file with `fn main()`
and a `[[bin]]` section in Cargo.toml).

If working on **module code**: read <./module-rules.md>.
If working on **script code**: read <./script-rules.md>.

## Rules

- Every `struct` and `enum` must derive `Debug`.
  Before writing any functions, do one sweep over all type definitions to verify this.
- Use multiline string literals for multi-line content in attribute macros and other contexts.
  Never use `\n` escapes or trailing-backslash continuation inside `#[command(...)]`, doc
  comments, or format strings that span multiple conceptual lines.
- When extracting code into a helper function that needs 4 or more data inputs,
  ask the user whether a struct would be appropriate. Do not silently group — the
  decision may depend on domain context.
- The binary crate name in `Cargo.toml` (`[package] name` or `[[bin]] name`) must match the
  command the user runs. Check this before writing any code — rename if the existing name is
  misspelled.

## Guidelines

- When building types that wrap an external API client (e.g. octocrab), explore the crate's
  model types first. Most APIs already have typed structs — do not define duplicate
  JSON-deserializable types unless the crate's types are genuinely insufficient.
- Run `cargo clippy --fix` after writing code, before the first manual review pass.
  Clippy catches many issues automatically (let chains, enum boxing, unnecessary closures,
  single-component imports, and more) — there is no need to memorise or document those
  patterns individually.

## Dependencies

- Use `cargo add` to add dependencies. Never edit `Cargo.toml` by hand for dependency
  additions unless the exact version pin matters.
- Common, well-known dependencies (`tokio`, `serde`, `clap`, `anyhow`) go first in the
  `[dependencies]` section, with no comment.
- Non-obvious dependencies — those specific to the project's domain, or with a less
  self-explanatory purpose — need a comment on the same line explaining why they are needed.
- When a dependency requires non-default features, a version pin with `=`, or a specific
  git revision, add a comment explaining the constraint:

```toml
# nix 0.29 required for --extra-experimental-features flag support
nix = "0.29"
```

## Quality checks

Run these before considering Rust code done:

1. `cargo clippy -- -D warnings` — zero warnings
2. `cargo fmt` — no formatting diffs
3. `cargo test` — all tests pass
4. `cargo build` — clean compile (no warnings from rustc either)

## Testing

The standard testing system for Rust is `#[cfg(test)] mod tests` inside each source file.

### Test input construction

Apply the test input independence rule from the generic skill:
build inputs from raw components, never round-trip through code under test.

```rust
// chrono crate assumed; substitute with time, jiff, or std::time as appropriate
// Good — input built from components independent of format_timestamp
fn make_dt(y: i32, m: u32, d: u32, h: u32, min: u32, s: u32) -> DateTime<Utc> {
    Utc.with_ymd_and_hms(y, m, d, h, min, s).single().unwrap()
}

#[test]
fn test_format_timestamp() {
    let t = make_dt(2026, 8, 25, 8, 20, 12);
    assert_eq!(format_timestamp(&t), "2026-08-25 08:20:12");
}

// Bad — round-trip through the same format string; test is tautological
fn dt(s: &str) -> DateTime<Utc> {
    NaiveDateTime::parse_from_str(s, "%Y-%m-%d %H:%M:%S").unwrap().and_utc()
}

#[test]
fn test_format_timestamp() {
    let t = dt("2026-08-25 08:20:12");
    assert_eq!(format_timestamp(&t), "2026-08-25 08:20:12");
}
```

### Foreign type construction

When a test needs a type from an external crate (e.g. `octocrab::models::issues::Comment`)
and the type is `#[non_exhaustive]` with no `Default`, construct it via JSON deserialization:

```rust
fn make_issue_comment(login: &str, body: Option<&str>, ts: &str) -> IssueComment {
    let json = serde_json::json!({
        "id": 1,
        "node_id": "n1",
        "url": "https://api.github.com/repos/o/r/issues/comments/1",
        "html_url": "https://github.com/o/r/issues/1#issuecomment-1",
        "body": body,
        "user": { "login": login, "id": 1, ... },
        "created_at": ts,
        "author_association": "NONE",
    });
    serde_json::from_value(json).unwrap()
}
```

Use `serde_json::json!()` over manual struct literals for foreign non_exhaustive types —
the JSON path is more robust against crate version bumps.
