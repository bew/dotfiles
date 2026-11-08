# Verification

Delegate claim verification to the `verify-claims` skill: it derives claims from the artefact,
validates them in subagents, and returns per-claim verdicts.

## Inputs to supply

Provide its inputs from the context:
- **Artefact**: the draft (*Author*/*Update*) or the README under review (*Review*).
- **Ground truth**: the package source, its repository, and the approved brief.
- **Taxonomy**: the README check-groups below, extending its default floor.
- **Coverage oracle**: the brief's `must` findings, each with its locator.
- **Deterministic checks**: `./scripts/mechanical-checks --dir <package-dir>`.
- **Domain refs**: <./languages/rust.md> for a Rust package.

## README check-groups

Pass these groups alongside its default skeleton.
Where a group overlaps a default one, check it once with the README criteria here.

- **Existence** — every path, module, and symbol named exists as described.
- **Grouping & naming** — files are grouped correctly; package/crate names are exact.
- **Mechanism** — concurrency, direction, and control-flow claims match the actual
  types and call sites.
- **Failure behaviour** — error paths named in the README match the actual error types and
  conditions; partial-input, EOF, and would-block behaviour is stated correctly.
- **Cross-crate claims** — every crate or layer named as a consumer actually depends on the package.
  A role-based phrasing ("the mux client and server") is checked against the architecture, not enumerated.
- **Completeness** — lists claimed complete are complete; no dangling references.
  This bounds the claims made, not the size of the API surface; missing `must` facts belong to Coverage.
- **Coverage** — every `must` finding in the brief is present and accurate; every exclusion is recorded in the brief.
  Return MISSING for an absent `must` finding.
  This is the only group that can see a valuable omission.
- **Brief conformance** — the heading set matches the approved brief; no fact appears that the brief does not carry; each section respects its budget.
- **Examples** — samples include required initialisation and are semantically correct
  against the API (handles managed, no cancelled tasks), not just symbol-valid.
- **Positive facts** — flag negative or absence framing (what the package is not, or does not do), unless omission would distort the overview.
- **Inner coherence** — no section contradicts another.
- **Style & conventions** — no `src/` prefix for files under `src/`; wrapped semantic line
  breaks; no blank line before a list or code block.

## Final altitude pass

Run this as one **dedicated** subagent, launched only after *Step:Verify* returns clean.
A pass merged into the *Step:Verify* batch, or run before Verify is clean, does not satisfy this step;
post-fix re-verification does not excuse it — this pass always runs last, over the final README.
It is mandatory in *Author* and *Update*; in *Review*, record its findings and stop.

Give it the verified README, the brief, and the reader tasks.
Do not give it the verification report; it judges the text as a reader, not as a fact-checker.

Return CUT / SIMPLIFY / KEEP per section, with a one-line reason.
Flag any sentence that stacks more than two qualifications, any Architecture paragraph that restates a Responsibilities bullet, and any `must` fact that is technically present but buried.
Apply every CUT and SIMPLIFY; they are blocking, not advisory.
Run the pass once over the final README; re-run it only if a later fix changed the section structure.

## Reconciliation

- Do not edit files during verification; collect verdicts first.
- Map each FALSE/PARTIAL verdict to a concrete fix; drop or reword any UNVERIFIABLE claim.
- Prefer REMOVE over reword for a PARTIAL claim that is not a `must` finding.
  A qualification that only makes an incidental claim true is bloat.
- Treat MISSING as a defect: add the fact, or record it under the brief's exclusions.
- Treat CUT/SIMPLIFY as blocking fixes, not advisory notes; map each to a concrete removal or rewrite.
- Surface conflicting verdicts to the user; never silently pick one.
- Re-run only the check-groups a fix affects.
  A corrected fact re-runs Factual accuracy and Coverage; a removed or reworded sentence re-runs Inner coherence and Style & conventions.
- Run the full *Step:Verify* when a fix adds a claim, changes the section structure, or the user asks for a full pass.
- After an altitude cut, re-run only Coverage, Inner coherence, and Style & conventions, because cutting a claim cannot make it false.
