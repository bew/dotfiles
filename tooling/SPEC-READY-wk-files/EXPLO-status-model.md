# status-model — exploration

How status is stored, read, and changed across the item families, and how three separate lifecycles
are exposed behind a single `--filter` flag without lying about any of them.

## Findings

- The task family uses three tags: `READY`, `CLAIMED`, `DONE`.
  A file with none of them is open, which means "open" is the absence of a tag rather than a tag.
- The same family is expected to carry more than one tag at once.
  The global convention tells an agent finishing a claimed task to prefix `[DONE]`, and to place it
  before an existing `[CLAIMED]`, so a real file can read `[DONE] [CLAIMED]`.
  Status is therefore a set with a precedence order, not a field.
- Managed specs use eight tags: `DISCOVERY`, `EXPLO`, `DRAFT`, `MAYBE-READY`, `READY`, `CLAIMED`,
  `IMPLEMENTED`, `ABANDONED`.
  Exactly one is present, it is written by `manage-spec`, and changing it usually moves the directory.
- Exploration topics use `active`, `frozen`, `revived` in the brief index.
  That vocabulary is a third one, and none of its tokens overlap the other two.
- `READY` and `CLAIMED` are shared between the task family and the spec lifecycle as tag *text*, but
  they are written by different tools and mean different things operationally.
  `DONE` is task-family only; `IMPLEMENTED` and `ABANDONED` are spec only.
- Tags are uppercase in the file; a CLI would naturally accept lowercase tokens.

## Design crux

One filter flag has to address three vocabularies that partially overlap in spelling but not in
ownership, while one of the three families stores status as an ordered set rather than a value.
Either the surface admits that shape, or the model is normalised — and normalising means either
rewriting other tools' conventions or accepting lossy reads.

## Candidate directions

- (active) **Union vocabulary, case-insensitive.** `--status` accepts every token from all three
  vocabularies. Shared tokens match every kind using them; unique tokens narrow on their own.
  No configuration, no new grammar, and the overlap is visible rather than hidden.
- (active) **Kind-scoped tokens.** Status filtering requires a kind: `--type task --status ready`, or a
  qualified form such as `task:ready`. Unambiguous, but verbose for the common "what is ready" question.
- (active) **Canonicalise the task family to a single tag.** `st` replaces rather than stacks, so status
  becomes a value everywhere and every filter is exact.
  Simplest model; destroys the claim trail the stacking convention exists to preserve.
- (active) **Query verbs drawn from the status vocabulary.** Listing is expressed as
  `wk file draft`, `wk file ready`, `wk file started`, `wk file done`, with `wk file ls` for everything.
  The set is closed and discoverable in help output, and a typo fails as an unknown command rather than
  as a filter that silently matches nothing.
- (settled) **Action namespace `do <action>`.** Mutations live under `wkf do <action> <id>`, so the grammar
  signals which commands write and the action set can grow without touching the top-level surface.
- (deferred) **Union `--status` filter, case-insensitive.** Keep `st`/`--status` as a general mechanism
  and skip the verb-per-status idea. Less discoverable, but avoids a long verb table.
- (deferred) **Common lattice with kind-specific sub-states.** Map every status onto a shared axis
  (open, active, done) and keep the precise state as a sub-field.
  Best querying story, but requires an agreed mapping and hides genuine differences between families.

## Decisions

- (settled) **The status verbs are queries, not transitions.** `wkf ready` lists; it does not mark
  anything. This removes the read/write ambiguity that otherwise makes a forgotten id harmless and a
  typo dangerous.
- (superseded) **The query vocabulary is `draft`, `ready`, `started`, `done`, `abandoned`** — `wip` was dropped in
  favour of `draft`, and `archived` is a location token rather than a group verb. Renamed in full below:
  `started` became `claimed`.
- (settled) **The query vocabulary is `draft`, `ready`, `claimed`, `done`, `abandoned`.** `started` is still
  accepted as an alias, so the older spelling keeps working, but every rendering and help line says `claimed`.
- (settled) **`claimed` is the group for `[CLAIMED]`.** The surface vocabulary and the on-disk vocabulary differ
  only in that one place; the spec documents the mapping once.
- (settled) **A spec may be claimed and finished by `wkf`.** The marker verbs prepend `[CLAIMED]` / `[DONE]`
  ahead of the `manage-spec` tag, so the spec's own tag survives as the record of what the lifecycle thinks.
  Both tools read the leftmost tag and therefore agree on the group without sharing a vocabulary.
- (settled) **`draft` is a group, not a state.** It collects every pre-ready item: an untagged task and the
  spec states `discovery`, `explo`, `draft`, and `maybe-ready`.
  Handoffs are *not* here — having no status convention, they read as `ready`, because a handoff exists to be
  picked up.
  `maybe-ready` belongs here rather than with `ready`, because a proposal not yet accepted for work is
  still draft material.
- (settled) **`ready` selects spec `[READY]` only**, since no other family has a ready state today.
- (superseded) **`done` is the only end-state name in the tool's vocabulary.** It named two on-disk states at
  the time; the lifecycle has since dropped `implemented`, so the rule survives with a simpler reason.
- (settled) **`done` is the only end-state name, and one tag produces it everywhere.** `[DONE]` is the leftmost
  tag for a shipped task and for a shipped spec, so the mapping needs no per-kind exception and `implemented`
  is never a filter or alias.
- (settled) **Exploration topics overlap two groups.** `active` and `revived` match both `draft` and `claimed`
  (in flight, not finished); `frozen` matches both `ready` and `done`.
- (settled) **A brief suppresses its topics.** When `EXPLO-BRIEF.md` exists, the brief is the single item
  for that spec's exploration and the individual `EXPLO-<topic>.md` files are not items.
  A brief whose topics mix `active` and `frozen` has no single topic-level status, so listing topics
  beside it would report a status the spec does not have.
  The brief's own status is derived from its index: any `active` topic means `draft` and `claimed`;
  all frozen means `ready` and `done`.
- (settled) **`abandoned` is a group of its own.** `--filter abandoned` selects it. Retired work is
  reachable without listing everything, and the group stays disjoint from `done`: a task ends in exactly
  one of the two end states.
- (settled) **The archive is always scanned, hidden by default, and counted in a footer.** Archived items live
  under `.ARCHIVED/<group>/`, so a bare `ls` omits them and closes with a line that both counts them and names
  the terminal items not yet archived: `3 done, 2 abandoned not yet archived; archived: 1 done, 4 abandoned`.
  The counts state what is hidden, not what exists, and the scan itself is never conditional.
- (settled) **The footer distinguishes filed from unfiled terminal work.** Archiving is the end of an item's
  life, so a terminal item still sitting in the project is outstanding housekeeping, and the footer says so
  rather than lumping it with the archive.
- (settled) **`archived` is a location filter, not a group.** `--filter archived` selects everything under
  `.ARCHIVED/`; naming a group instead (`done`, `abandoned`) reaches archived items of that status
  without listing the other archived kind.
- (settled) **A brief with an empty topic index is `draft`.** It exists but has decided nothing yet, which
  keeps it inside a pre-ready group rather than in a stateless gap.
- (settled) **An unknown `--filter` token is an error** listing the six valid tokens, so a typo fails
  loudly instead of returning an empty result.
- (superseded) **There is no `--json` flag.** Reversed in `json-output`: every subcommand takes `--json`, and
  a hidden archive is reported in the structured answer as well as in the human footer.

## Open threads

- None open. The empty-brief status, the unknown filter token, and the archive reach are all settled above.
