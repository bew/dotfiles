# wk-files — File-backed work items — exploration brief

## Motivation

The harness tracks work in beads, through the `wk` frontend, and simultaneously carries planning and
scoping artefacts as plain markdown: `TASK-*.md`, `HANDOFF-*.md`, and managed spec directories
holding `DISCOVERY.md`, `SPEC.md`, and `EXPLO-*.md`.
Those artefacts already encode type in their filename and status in an H1 tag, but nothing can
enumerate, filter, or transition them.
Questions like "what is ready in this project" or "which specs are still claimed" are answered by
reading filenames and titles by hand.

`wk-files` is a management surface over artefacts that already exist.
It is invoked as `wkf`.
It does not create files, scaffold templates, pick names, or invent titles.

Scope: detection, listing, filtering, reporting, status transition, and archiving of artefact
files reachable from the current project.

Out of scope: any sync between artefact files and beads issues; creation; cross-devtree scanning;
a unified `wk` surface over both backends.

Constraint that shapes everything: the beads passthrough must stay untouched, so file-backed management
ships as its own command (`wkf`) rather than merging into the existing grammar.

## Topics

- (frozen) `item-taxonomy` — which artefacts are items, how type and status are derived, and which tool owns status.
- (frozen) `status-model` — the tag stack vs a canonical tag, and how the status vocabularies surface as one `--filter`.
- (frozen) `surface-shape` — verbs, filters, ids, grouped output, and how a path is accepted where an id is.
- (frozen) `actions` — the mutation verbs: what may be written, on which families, and what a transition means.
- (frozen) `json-output` — machine-readable output for every subcommand, and what each verb emits.
