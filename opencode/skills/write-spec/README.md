# write-spec

Methodology for drafting technical design specs, from discovery through review.
`SKILL.md` carries the phase flow; `refs/` holds the phase instructions, the lifecycle
reference, and the spec structure and writing guidelines.

## Spec directories

A spec owns a directory whose name carries its lifecycle prefix:

- `SPEC-DRAFT-<slug>/` holds `discovery`, `explo`, `draft`, and `maybe-ready` specs
- `SPEC-READY-<slug>/` holds `ready` specs
- `SPEC-KO-<slug>/` holds `abandoned` specs

A spec directory holds three kinds of file:

- `SPEC.md` — the spec itself.
- `DISCOVERY.md` — the discovery notes gathered before drafting.
- `EXPLO-*.md` — exploration material, owned by the `design-exploration` skill.

Which file an agent reads or edits is decided by `manage-spec`, which prints `$specpath`.
Never infer it from the state name.

## Lifecycle

```mermaid
stateDiagram-v2
    [*] --> discovery: manage-spec init
    discovery --> explo
    discovery --> draft
    discovery --> abandoned
    explo --> draft: Switch to Draft
    explo --> abandoned
    draft --> explo: design reopens
    draft --> maybe-ready
    draft --> ready
    draft --> abandoned
    maybe-ready --> draft
    maybe-ready --> explo: design reopens
    maybe-ready --> ready
    maybe-ready --> abandoned
    ready --> draft
    ready --> explo: design reopens
    ready --> maybe-ready
    ready --> abandoned
    abandoned --> draft
    abandoned --> explo: design reopens
```

Every state can move to `abandoned`.
The transition table in `refs/lifecycle.md` is the authority; this diagram only shows its shape.

## Lifecycle tool

`scripts/manage-spec` owns every state change: it rewrites the H1 status tag, adds or removes
the skill-loader paragraph, and moves the directory.
The agent never moves a directory or edits the status tag itself.

`scripts/manage-spec.bats` covers the tool with `bats`.

## Headings another tool marked

A spec H1 may carry a marker another tool prepended, ahead of the status tag.
`manage-spec` refuses such a heading instead of guessing ownership: ask the user to reset the tag,
then rerun the command.
