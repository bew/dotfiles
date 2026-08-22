# Terminology & Key Concepts (TKC)

Reference for the optional Terminology & Key Concepts section.

## When to create

Create this section when the spec introduces non-obvious or domain-specific terms
that would benefit from explicit definition near the top of the document.

Omit if the spec uses only well-known terms
and no ambiguity is likely.
The default is to omit — the Global Open Questions section tracks this decision.

## Prose style

Follows the general prose rules in <./writing-guidelines.md>.
Should read well — bullets and concise phrasing are allowed but not the default.

## Entry format

For each candidate term,
determine (via discovery with the user if not inferrable from context)
whether the term is:

- **New** — introduced by this spec.
- **Changed / replaced** — a term with an established meaning
  that this spec redefines or supersedes.
- **Important to understand** — an existing term or concept
  that the spec relies on.
  May include a reference URL (e.g. linking to a base protocol).

Each entry may carry a marker to indicate its relationship to this spec.
Markers are **not required** — use them only when they add clarity:

- `(new!)` — term is introduced by this spec.
- `(updated!)` — term has an existing meaning that this spec redefines.
  Explicitly state what part changed.
- `(replaced!)` — the old meaning is fully superseded.
- No marker — well-known or contextual term that benefits from explicit placement
  in the TKC but doesn't need a relationship label.

Example:

> **Extension Point** (new!):
> A hook in the request lifecycle where custom logic can be injected.
>
> **Connection**:
> An established TCP session between client and server.
> Used throughout this spec to refer specifically to persistent connections
> (not ephemeral request sockets).

## Short names

A term may define a short name (e.g. `ExtPoint` for `Extension Point`).
Short names reduce token count in prose and avoid horizontal overflow in code comments.
Short names are optional — always validate with user before adopting one
(judge whether it adds clarity or just obscures).
If a short name is defined, it must be used consistently throughout the spec
(not interchanged with the full name).

## Candidate terms

Any new, changed, or referenced concept introduced in this spec
is a candidate for inclusion in the TKC.
The user always decides which candidates make it in.

When preparing to ask about the TKC section (via the Global Open Questions entry),
infer candidates by scanning for:

- Distinct entities, roles, or components in the system being designed.
- Any term used in a non-standard or narrowed sense.
- Abbreviations or acronyms not defined inline.
- External protocols or systems that the spec builds on.

List the inferred candidates so the user can confirm, reject, or extend them.
