---
name: package-readme-editor
description: |
  Write, review, or update a package-level README.md.
  Keep it coherent on its own and accurate against the source.
  Use when asked to "write a README for <package>", "document this crate/package",
  or "review the <package> README".
  Covers research-first authoring, review, and update modes, with mandatory subagent-based claim verification.
  Altitude is a mandatory final pass, separate from claim verification.
metadata:
  maintainers:
    - bew
---

# Package README Editor

## Goal

Produce or audit a package `README.md` that is coherent on its own and accurate against the source.
The README is the package's overview and navigation entry point; the source remains the authority for detail.
Accuracy is necessary but not sufficient: the README must also select what its reader needs.

## Modes

Select a mode in *Step:Recon*.
Default from README presence.

- **Author** — no README: research, brief, draft, verify, then run the altitude pass.
- **Review** — README exists: research the source, build the brief as an audit checklist, report findings, and include the altitude pass findings; never rewrite.
- **Update** — README exists and the user asks for a specific change: research the affected source surface, brief the change, apply it, verify, then run the altitude pass.

## Step 1 — Recon

Locate the target package, detect its language, read the existing README (if any),
and select the mode.
Identify the candidate ground truth: the package source, its tests, and the call sites in its consumers.
Name those paths for *Step:Research*.
If the target is ambiguous: stop and ask. Do not proceed to *Step:Research*.

## Step 2 — Research

Build a cited fact base and a coverage oracle before drafting or auditing.
Do not write README prose in this step.

Read <./refs/research.md> and run its question set against the ground truth.
For a package with three or fewer source files, one research subagent is enough.
For a larger package, split the questions across two or three parallel subagents:
purpose and consumers; mechanism and invariants; failure surface and usage.

Every finding carries a `file:line` locator and a rank: `must`, `optional`, or `omit`.
The set of `must` findings is the coverage oracle used in *Step:Verify*.
Drop any finding that cannot be cited.

## Step 3 — Brief

Turn the research findings into an editorial brief before writing headings or auditing the current structure.
Read <./refs/brief.md> for the schema.

The brief fixes:
- the thesis, in one sentence;
- the heading set and the purpose of each section;
- the `must` facts each section carries, and its fact budget;
- the facts deliberately excluded, with a one-line reason.

Confirm the heading set and the brief with the user.
A section left out is information the reader will not get; say what it omits.
In *Review*, the brief is the audit checklist; do not propose a new heading set unless the user asks for a restructure.
In *Update*, scope the brief to the sections the change touches.

## Step 4 — Draft

Produce mode-specific output: write the README (*Author*/*Update*) or a findings list (*Review*).

Render the brief; do not re-derive facts from the source.
If drafting reveals a fact missing from the brief, return to *Step:Brief* and update it first.

Before writing prose:
- Read the repo's prose convention; apply wrapped semantic line breaks from the start.
  Never hard-wrap mid-sentence.
- Follow the repo's Markdown conventions.
  Never put a blank line between a lead-in line ending in `:` and its following list or code block.
- State one fact per sentence.
  If a sentence needs a second qualification to stay true, split it or drop the weaker fact.
- Keep Responsibilities an index of capabilities.
  Architecture carries the mechanism; it never restates a Responsibilities bullet.

Examples must be complete and correct, not merely plausible:
- Include required initialisation (e.g. scheduler setup).
- Manage returned handles per the API semantics (e.g. `.detach()` a task that must outlive the statement).
- Show one specific, common task per example.
- When there is more than one example, each must differ on an axis: normal path vs error path, sync vs async, producer vs consumer, setup vs steady state.
  Two examples that differ only in payload type are one example.
- Prefer adapting an existing test that exercises the common path; a test is known-correct and already carries the required initialisation.
  A test chosen for edge-case coverage is a poor example.
- When the package has no tests, adapt a usage from one of its consumers.
  If neither exists, report the gap instead of inventing an example.

## Step 5 — Verify

Read <./refs/verification.md> for the inputs, then load and follow the `verify-claims` skill.
Pass the brief's `must` findings as the coverage oracle.
Reconcile the verdicts it returns.
In *Author*/*Update*, return to *Step:Draft* on any non-TRUE or MISSING verdict, then re-run the affected check-groups; run a full *Step:Verify* only when a fix adds a claim or the user asks for one.
In *Review*, record the findings and stop; never loop.

## Step 6 — Altitude

Follow <./refs/verification.md> § Final altitude pass.
Run one **dedicated** altitude subagent, launched only after *Step:Verify* returns clean.
A pass merged into the *Step:Verify* batch, or run before Verify is clean, does not satisfy this step.
Post-fix re-verification does not excuse it either: this pass always runs last, over the final README.
This pass is mandatory in *Author* and *Update*; in *Review*, record its findings and stop.

Give it the verified README, the brief, and the reader tasks.
Do not give it the verification report; it judges the text as a reader, not as a fact-checker.

Apply every CUT and SIMPLIFY; they are blocking, not advisory.
Cutting a claim never makes it false, so re-run only Coverage, Inner coherence, and Style & conventions after the pass.
If a rewrite adds a new claim or the user asks for a full pass, re-enter *Step:Verify* in full.
Run the pass once over the final README; re-run it only if a later fix changed the section structure.

## Rules

- Confirm the heading structure with the user before writing any heading.
  When offering section choices, state what each choice omits: a section left out is information the reader will not get.
- Never prefix a module/file name with `src/` when the file lives under `src/`; use the bare name.
- Never state a claim that verification did not return TRUE for; surface PARTIAL and UNVERIFIABLE.
- Prefer removing a non-essential claim over qualifying it.
  A claim that needs a second clause to be true is usually not carrying its weight in an overview.
- Validate claims via `verify-claims`; the main agent reconciles but never self-validates.
- Verify proportionally: re-run only the check-groups a fix affects.
  Run a full pass when a fix adds a claim or changes structure, or when the user asks for one.
- Match the README/repo line-wrapping convention; do not reformat unrelated content.
- Describe behaviour as the contract, not as observation; never write "observed behaviour".
- Keep content registers separate; see <./refs/structure.md>.
- Surface conflicting verdicts from `verify-claims`; never silently pick one.
- Write for a maintainer or agent who wants an overview and can read the sources for detail.
  Include a mechanism only when it helps that reader understand what the package does.
  Leave incidental internals to source comments or API documentation.
- Prioritise invariants, caller-enforced conventions, and failure conditions.
  Treat metrics, logging, and internal structure as optional unless a consumer observes them.
- Omission is allowed only for facts the brief ranks `optional` or `omit`; a missing `must` fact is a defect.
  An overview may skip detail, but every included claim must be accurate.
- Prefer public API names.
  Name a crate-private helper only when it explains behaviour visible outside the crate.
- Write each Responsibilities bullet from the caller's point of view: the capability, not a symbol, is the subject.
- Keep public symbols out of Responsibilities, except when a symbol is central to the capability its bullet names.
  There it may stand as an inline anchor.
  A symbol is never the bullet's subject and never a bare list.
- When the repo's existing READMEs conflict with a skill convention, surface the conflict to the user
  and follow their choice for the whole document.
- In *Review*, report content that can be removed or simplified, not only inaccuracies.

## Companion files

- Read <./refs/structure.md> before choosing headings or writing a section.
- Read <./refs/research.md> before *Step:Research*.
- Read <./refs/brief.md> before *Step:Brief*.
- Read <./refs/verification.md> before *Step:Verify*.
- Read <./refs/languages/rust.md> when the target is a Rust package.
