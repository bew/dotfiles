---
name: package-readme-editor
description: |
  Write, review, or update a package-level README.md.
  Keep it coherent on its own and accurate against the source.
  Use when asked to "write a README for <package>", "document this crate/package",
  or "review the <package> README".
  Covers authoring, review, and update modes, with mandatory subagent-based claim verification.
metadata:
  maintainers:
    - bew
---

# Package README Editor

## Goal

Produce or audit a package `README.md` that is coherent on its own and accurate against the source.
The README is the authoritative behavioural doc for the package.

## Modes

Select a mode in *Step:Recon*.
Default from README presence.

- **Author** — no README: draft one from the source.
- **Review** — README exists: audit it and report findings.
- **Update** — README exists and the user asks for a specific change: apply it, then verify.

## Step 1 — Recon

Locate the target package, detect its language, read the existing README (if any),
and select the mode.
If the target is ambiguous: stop and ask. Do not proceed to *Step:Draft*.

## Step 2 — Draft

Produce mode-specific output: write the README (*Author*/*Update*) or a findings list (*Review*).

Before writing prose:
- Read the repo's prose convention; apply semantic line breaks (one sentence per line) from the start.
  Never hard-wrap mid-sentence.
- Follow the repo's Markdown conventions.
  Never put a blank line between a lead-in line ending in `:` and its following list or code block.

Examples must be complete and correct, not merely plausible:
- Include required initialisation (e.g. scheduler setup).
- Manage returned handles per the API semantics (e.g. `.detach()` a task that must outlive the statement).

## Step 3 — Verify

Read <./refs/verification.md> for the inputs, then load and follow the `verify-claims` skill.
Reconcile the verdicts it returns.
In *Author*/*Update*, return to *Step:Draft* on any non-TRUE verdict, then re-run *Step:Verify*.
In *Review*, record the findings and stop; never loop.

## Rules

- Confirm the heading structure with the user before writing any heading.
- Never prefix a module/file name with `src/` when the file lives under `src/`; use the bare name.
- Never state a claim that verification did not return TRUE for; surface PARTIAL and UNVERIFIABLE.
- Validate claims via `verify-claims`; the main agent reconciles but never self-validates.
- Match the README/repo line-wrapping convention; do not reformat unrelated content.
- Describe behaviour as the contract, not as observation; never write "observed behaviour".
- Keep content registers separate; see <./refs/structure.md>.
- Surface conflicting verdicts from `verify-claims`; never silently pick one.

## Companion files

- Read <./refs/structure.md> before choosing headings or writing a section.
- Read <./refs/verification.md> before *Step:Verify*.
- Read <./refs/languages/rust.md> when the target is a Rust package.
