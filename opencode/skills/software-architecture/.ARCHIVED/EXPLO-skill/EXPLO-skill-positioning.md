# skill-positioning — exploration

Where the skill sits: what triggers it, what it owns versus `coder-generic`, `write-spec`, and
`design-exploration`, whether it ever persists output, and whether sibling skills point at it.

## Findings

- Draft description triggers on two situations: planning a design whose structure is open, and
  refreshing an existing design (split, re-seam, restructure).
- User rejected cross-links from `coder-generic` and `opencode-crafter`; discovery rests on the
  description alone.
- `coder-generic` owns mechanical conventions (naming, types, comments, error-handling mechanics);
  the draft assigns structural decisions to this skill.
- No threshold rule for "non-trivial" — the agent judges.

## Design crux

Can a skill that only loads by description, and that no other skill references, still be found at the
moments it matters?
Everything else in this topic depends on how much weight the description can carry.

## Candidate directions

- (active) **Description-only discovery** — the description lists concrete situations; no cross-links
  from other skills, per the user's call.
- (active) **Two-part trigger wording** — planning and refinement named as distinct triggers, so the
  skill also loads when judging existing structure rather than only when creating new code.
- (active) **No non-triviality threshold** — the agent judges depth from the pattern index.
- (deferred) **Two-way hand-off with design-exploration** — explo matures a concept then hands shape
  work here; this skill sends work back when a concept is unnamed or contested.

## Decisions

### (settled) `refinement-includes-critique` — a bare structural review loads the skill

Any request to judge existing structure is enough: "is this module shaped right", "where does the seam
go here", "why is this hard to test".
Only style-and-convention reviews stay with `coder-*` — naming, types, comment form, error-handling
mechanics.

This widens the refinement trigger beyond active restructuring.
The skill must therefore be able to critique without being asked to change anything.

### (settled) `design-note-on-agreement` — persistence needs agreement and a user-chosen location

The skill proposes a design note, the user agrees, and the user says where it lives.
No fixed path, no naming convention, no automatic file.

A design expected to outlive the session still goes to `write-spec` instead.
The distinction is whether the note is a working aid or a durable document.

### (settled) `architecture-remit` — the skill is software-architecture

The remit covers structure inside a codebase: module roles, layering questions as roles, state
ownership, seams.
The description carries the exclusions — not deployment topology, not tech selection, not performance —
because the name now attracts architecture requests generally.

## Open threads

- Where does the skill's critique stop and `write-spec` start when the review finds a design worth
  documenting?
