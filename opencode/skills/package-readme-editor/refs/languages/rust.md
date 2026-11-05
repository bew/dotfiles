# Rust package checks

Run these in addition to `./scripts/mechanical-checks`.

- Manifest: `Cargo.toml`.
  - Compare `package.name` against every name used in the README;
    abbreviated names are a common defect.
  - Note `publish = false` and whether the README claims workspace prominence.
- Module-doc census: count `.rs` files under `src/` and those starting with `//!`.
  - Flag any "each/every/all file is documented" claim unless the counts match.
- Feature census: diff `[features]` keys in `Cargo.toml` against feature names in the README.
- Dependency provenance: flag any negative or absence claim about a dependency
  (what the package does not use or depend on).
- Cross-platform claims: check `[target.'cfg(...)']` tables and `build.rs`
  for platform-specific deps and steps.
