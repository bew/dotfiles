# Editorial brief

## Goal

Decide what the README says before writing it.
The brief is the contract between research and draft: the draft may not add a fact the brief does not carry.
In *Review*, the brief is the audit checklist; in *Update*, scope it to the sections the change touches.

## Schema

Write this, then confirm it with the user:

Thesis: one sentence on what the package is and why a reader opens it.

Reader tasks:
- the three tasks from research, ranked.

Sections:
- each heading, its purpose, the `must` facts it carries, and its budget.

Excluded:
- each omitted fact and a one-line reason.

Open questions:
- anything research could not settle.

## Budgets

Budgets are caps, not targets.
- Purpose & scope: one to three sentences.
- Responsibilities: one bullet per capability; depth scales with package complexity — a line for a simple package, a short paragraph for a complex one.
- Architecture: one paragraph per non-obvious mechanism; three to five paragraphs is usually enough.
- Failure behaviour: one condition per bullet.
- Usage: one example per task axis.

A section that cannot fit its budget is carrying facts that belong in another section or nowhere.

## Rules

- Every `must` research finding appears in exactly one section.
- A fact marked `optional` may be excluded; say so under `Excluded`.
- A fact marked `omit` never enters the brief.
- Name the reader task each section serves.
- Do not restate a Responsibilities capability in Architecture.
- If two sections would carry the same mechanism, keep it in Architecture and cut the other mention.
- If a section has no `must` facts, cut the section.

## Worked example: codec

Research found the caller-enforced serial convention at `wezterm-client/src/client.rs:404`: serial `0` marks an unsolicited message.
That is a `must` fact, because it cannot be derived from `codec/src/lib.rs`.
The brief places it under serial correlation in Architecture.
A package-local draft missed it entirely.

Research also found per-variant metrics.
That is `optional`: no consumer decision depends on it.
The brief records it under `Excluded`, so the draft does not spend a bullet on it.

The failure surface spans three conditions: sync framing errors, async `CorruptResponse`, and invalid-PDU encode rejection.
The brief gives each its own bullet instead of one sentence with three qualifications.
