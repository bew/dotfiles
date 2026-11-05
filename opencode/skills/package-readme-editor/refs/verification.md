# Verification

Delegate claim verification to the `verify-claims` skill: it derives claims from the artefact,
validates them in subagents, and returns per-claim verdicts.

## Inputs to supply

Provide its inputs from the context:
- **Artefact**: the draft (*Author*/*Update*) or the README under review (*Review*).
- **Ground truth**: the package source and its repository.
- **Taxonomy**: the README check-groups below, extending its default floor.
- **Deterministic checks**: `./scripts/mechanical-checks --dir <package-dir>`.
- **Domain refs**: <./languages/rust.md> for a Rust package.

## README check-groups

Pass these groups alongside its default skeleton.
Where a group overlaps a default one, check it once with the README criteria here.

- **Existence** — every path, module, and symbol named exists as described.
- **Grouping & naming** — files are grouped correctly; package/crate names are exact.
- **Mechanism** — concurrency, direction, and control-flow claims match the actual
  types and call sites.
- **Completeness** — lists claimed complete are complete; no dangling references.
- **Examples** — samples include required initialisation and are semantically correct
  against the API (handles managed, no cancelled tasks), not just symbol-valid.
- **Positive facts** — flag negative or absence framing (what the package is not, or does not do).
- **Inner coherence** — no section contradicts another.
- **Style & conventions** — no `src/` prefix for files under `src/`; semantic line breaks
  (one sentence per line); no blank line before a list or code block.

## Reconciliation

- Do not edit files during verification; collect verdicts first.
- Map each FALSE/PARTIAL verdict to a concrete fix; drop or reword any UNVERIFIABLE claim.
- Surface conflicting verdicts to the user; never silently pick one.
- After fixes, re-run *Step:Verify*.
  Every check-group runs again, not only the fixed ones.
