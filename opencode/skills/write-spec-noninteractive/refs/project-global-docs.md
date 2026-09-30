# Project-Global Docs

A project-global doc is a project-level document that defines a concept, term, or convention
applying across the project, not just to one spec.

## Identification

By convention, project-global docs are `CONTEXT.md`, `CONTEXT-MAP.md`, `PROJECT-SPEC.md`,
and any file under `docs/**`.
This variant runs without mid-pass checkpoints —
confirm the candidate set as a deferred question in the `## Questions for you` block.

## Reference, don't restate

Reference a concept or term already defined in a project-global doc; never redefine it.
Mention it briefly so the reader can follow, then point at its doc.

Avoid restating its full definition:
> The request lifecycle is the ordered set of stages a request passes through
> from arrival to response, including routing, middleware, and error handling.

Prefer a brief mention plus a pointer:
> This spec hooks into the routing stage of the request lifecycle (see `CONTEXT.md`).

## Terminology & Key Concepts

Never redefine a term or concept already defined in a project-global doc in the spec's TKC.
Reference the doc instead — an "Important to understand" entry may point at it.

## Gaps

A gap is a concept or term the spec relies on that no project-global doc defines.

Define the concept or term inline in the spec, so the spec stays self-contained.
Then list the resolution in the `## Questions for you` block:
- **Own it** — the concept or term is specific to this spec; keep the definition spec-local.
- **Promote** — the concept or term is cross-cutting; emit a capture instruction
  for adding it to the project-global docs.

On promote, emit one capture instruction per gap.
The spec still inline-defines the concept or term and records the gap
(as an Open Question or a `FIXME:` callout) — the capture only schedules the promotion.
