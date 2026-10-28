# status-model — exploration

How status is stored, read, and changed across the item families, and how the separate lifecycles
are exposed behind a single `--filter` flag without lying about any of them.

## Findings

- The task family's tags are `READY`, `CLAIMED`, `DONE`.
  A file with none of them is open, which means "open" is the absence of a tag rather than a tag.
- The same family is expected to carry more than one tag at once.
  The global convention tells an agent finishing a claimed task to prefix `[DONE]`, and to place it
  before an existing `[CLAIMED]`, so a real file can read `[DONE] [CLAIMED]`.
  Status is therefore a set with a precedence order, not a field.
- Managed specs use six lifecycle tags: `DISCOVERY`, `EXPLO`, `DRAFT`, `MAYBE-READY`, `READY`,
  `ABANDONED`.
  Exactly one is present and `manage-spec` writes it, moving the directory as the state changes, while
  `wkf` prepends its own `[CLAIMED]` and `[DONE]` markers ahead of that tag.
- Exploration topics use `active`, `frozen`, `revived` in the brief index.
  That vocabulary is a third one, and none of its tokens overlap the other two.
- `READY` and `CLAIMED` are shared between the task family and the spec lifecycle as tag *text*, but
  they are written by different tools and mean different things operationally.
  `DONE` is a `wkf` marker that a spec can carry too; `ABANDONED` is spec only, written by `manage-spec`.
- The bug family carries its own four tags: `CONFIRMED`, `FIXING`, `FIXED`, `WONTFIX`, with no tag
  meaning open.
  The task tags are accepted on read as aliases, but they are never written onto a bug.
- Tags are uppercase in the file; a CLI would naturally accept lowercase tokens.

## Design crux

One filter flag has to address vocabularies that partially overlap in spelling but not in
ownership, while one of the families stores status as an ordered set rather than a value.
Either the surface admits that shape, or the model is normalised — and normalising means either
rewriting other tools' conventions or accepting lossy reads.

## Candidate directions

- (deferred) **`--status` alone, no status verbs** — one spelling to learn, at the cost of the short
  spelling for the two questions actually asked.
- (deferred) **A common lattice** — open, active, done, with kind-specific sub-states; needs an agreed
  mapping and hides the differences between families.

## Decisions

### (settled) `query-vocabulary` — The filter vocabulary is `draft`, `ready`, `claimed`, `done`, `abandoned`

related-to: `claimed-group` & `done-end-state` & `abandoned-group`

`started` is still accepted as an alias, so the older spelling keeps working, but every rendering and
help line says `claimed`.

### (settled) `claimed-group` — `claimed` is the group for `[CLAIMED]`

related-to: `query-vocabulary` & `spec-marker-verbs`

On a task or idea, the surface vocabulary and the on-disk vocabulary differ only in that one place, so
the spec documents the task mapping once.
A bug carries its own vocabulary; see `bug-vocabulary`.

### (settled) `spec-marker-verbs` — A spec may be claimed and finished by `wkf`

related-to: `claimed-group` & `done-end-state`

The marker verbs prepend `[CLAIMED]` / `[DONE]` ahead of the `manage-spec` tag, so the spec's own tag
survives as the record of what the lifecycle thinks.
Both tools read the leftmost tag and therefore agree on the group without sharing a vocabulary.

### (settled) `draft-group` — `draft` is a group, not a state

related-to: `ready-group` & `topic-groups-overlap`

It collects every pre-ready item: an untagged task, idea, or bug, and the spec states `discovery`,
`explo`, `draft`, and `maybe-ready`.
Handoffs are not here — having no status convention, they read as `ready`, because a handoff exists to
be picked up.
`maybe-ready` belongs here rather than with `ready`, because a proposal not yet accepted for work is
still draft material.

### (settled) `ready-group` — `ready` is `[READY]`, never `MAYBE-READY`

related-to: `draft-group` & `query-vocabulary`

On a spec, `ready` means the lifecycle accepted it for work, while a `MAYBE-READY` proposal stays in
`draft`.
A task or idea reaches `ready` through its own `[READY]` tag, a bug through `[CONFIRMED]`, and a
handoff is `ready` because its format defines no status at all.

### (settled) `done-end-state` — `done` is the group for shipped work, whatever tag the kind writes

related-to: `query-vocabulary` & `bug-vocabulary`

A shipped task or spec carries `[DONE]` and a fixed bug carries `[FIXED]`, so the on-disk tag is per-kind
while the group name stays one.
`implemented` is never a filter or an alias: the spec lifecycle's own tag records what the lifecycle thinks,
not what the surface reports.

### (settled) `bug-vocabulary` — A bug's tags are its own

related-to: `query-vocabulary` & `done-end-state` & `claimed-group` & `abandoned-group`

| On disk | Group |
|---------|-------|
| no tag | draft |
| `[CONFIRMED]` | ready |
| `[FIXING]` | claimed |
| `[FIXED]` | done |
| `[WONTFIX]` | abandoned |

An untagged bug is open and untriaged.
`[CONFIRMED]` is the ready state, written by the reporter or triage rather than by `wkf`.
`[FIXING]`, `[FIXED]`, and `[WONTFIX]` are the `wkf`-owned transitions for `claim`, `finish`, and
`abandon`.
The task tags are accepted as read-only aliases — `[READY]`≡`[CONFIRMED]`, `[CLAIMED]`≡`[FIXING]`,
`[DONE]`≡`[FIXED]`, `[ABANDONED]`≡`[WONTFIX]` — so a hand-tagged bug still reports correctly.
`wkf` never writes an alias onto a bug, and `reset`/`undo` remove only the tags it wrote for that kind.

### (settled) `topic-groups-overlap` — Exploration topics match two groups each

related-to: `draft-group`
coupled-with: `brief-suppresses-topics`

`active` and `revived` match both `draft` and `claimed` (in flight, not finished); `frozen` matches both
`ready` and `done`.

### (settled) `brief-suppresses-topics` — A brief suppresses the topics it indexes

related-to: `empty-brief-is-draft`
coupled-with: `topic-groups-overlap`

When `EXPLO-BRIEF.md` exists, the brief is the single item for that spec's exploration and the
individual `EXPLO-<topic>.md` files are not items.
A brief whose topics mix `active` and `frozen` has no single topic-level status, so listing topics
beside it would report a status the spec does not have.
The brief's own status is derived from its index: any active topic means `draft` and `claimed`; all
frozen means `ready` and `done`.

### (settled) `abandoned-group` — `abandoned` is a group of its own

related-to: `query-vocabulary` & `archived-is-a-location`

`--filter abandoned` selects it.
Retired work is reachable without listing everything, and the group stays disjoint from `done`: an item
ends in exactly one of the two end states.

### (settled) `archived-is-a-location` — `archived` is a location, not a group

related-to: `closing-line` & `listing-envelopes-split-by-verb` & `walk-rules`

Archived items live under `.ARCHIVED/<group>/`, the walk always reaches them, and `--filter archived`
selects everything there.
A status token such as `done` never reaches archived items: the archive stays outside the corpus a
group filter addresses until the archive itself is asked for.

### (settled) `empty-brief-is-draft` — A brief with an empty topic index is `draft`

related-to: `brief-suppresses-topics`

It exists but has decided nothing yet, which keeps it inside a pre-ready group rather than in a
stateless gap.

### (settled) `unknown-filter-token` — An unknown `--filter` token is an error

The message lists the six valid tokens, so a typo fails loudly instead of returning an empty result.

## Rejected directions

- **A case-insensitive `--status` union** — costs more than the overlap it explains.
- **A kind beside every status token** — `--type task --status ready` makes the common
  question costlier than the ambiguity it removes.
- **A single replacing `st` tag** — buys exact filters by destroying the claim trail the
  stacking convention exists to keep.

## Open threads

None open.
The empty-brief status, the unknown filter token, and the archive reach are all settled above.
