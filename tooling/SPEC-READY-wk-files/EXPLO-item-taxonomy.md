# item-taxonomy — exploration

What counts as a file item, how its kind and status are derived, and which tool owns that status.
The spec's verb set cannot be chosen until this is settled: filtering, transition, and removal all
presuppose a stable item identity and a single readable status per item.

## Findings

- `manage-spec` owns the H1 status tag and the directory name of a managed spec, and moves the
  directory as the state changes.
  States: `discovery`, `explo`, `draft`, `maybe-ready`, `ready`, `abandoned`.
- Three prefixes carry those states: `SPEC-DRAFT-<slug>/` for `discovery`, `explo`, `draft`, and
  `maybe-ready`; `SPEC-READY-<slug>/` for `ready`; `SPEC-KO-<slug>/` for `abandoned`.
  Four states share the draft prefix, so the directory name cannot name the state.
  Status therefore has to be read from the H1 tag, never inferred from the path.
- The carrier file changes with state: `DISCOVERY.md` while in `discovery` or `explo`, `SPEC.md` once
  the spec reaches `draft` or beyond.
  An item's path is therefore not stable across a status transition that `wk file` is not even
  performing — another tool moves the file underneath it.
- A spec is claimed and finished through `wkf`-owned `[CLAIMED]` and `[DONE]` markers, prepended ahead
  of the tag `manage-spec` wrote rather than replacing it.
  Both tools read the leftmost tag; `manage-spec` refuses to move a spec carrying a `wkf` marker, and
  `wkf do reset` is what strips the markers and hands the spec back.
- Exploration topics record their status in `EXPLO-BRIEF.md`'s topic index in `dedicated` mode.
  Per-file H1 status tags exist only in `adhoc` mode.
  So an `EXPLO-<topic>.md` file does not carry its own status in the layout this project uses.
- Task and handoff files carry `[READY]`, `[CLAIMED]`, `[DONE]` prefixes on the H1.
  No prefix means open, and the global convention allows stacking (`[DONE] [CLAIMED]`), which makes
  "the status" a leftmost-tag decision rather than a single field.
- Legacy specs live in `_SPECS/<slug>/`; `manage-spec migrate` moves them out, and `migrate` is
  deliberately absent from `--help`.
- The lifecycle no longer archives anything: `abandoned` keeps its `SPEC-KO-<slug>/` directory in
  place, and filing is `wkf do archive`, which moves a terminal item to `.ARCHIVED/<group>/` under the
  walk root.
  An archived spec is out of `manage-spec`'s reach for good.
- Beads remains the other backend and is untouched by any of this.

## Design crux

The artefact corpus has two different status authorities — the H1 tag for tasks, handoffs, and
managed specs, and the brief index for exploration topics — plus one family whose carrier filename
moves as its status changes.
`wk file` must present one readable status per item without becoming a second writer of state that
`manage-spec` and the exploration skill already own.

## Candidate directions

- (active) **Read-through adapter over existing conventions.** Parse H1 tags for tasks, handoffs, and
  managed specs; parse `EXPLO-BRIEF.md` for exploration-topic status; expose one status vocabulary at
  the surface. Writes stay limited to task-family H1 tags, with managed specs and exploits reporting
  status only.
- (active) **Task-family only.** Items are `TASK-*` and `HANDOFF-*`; specs, explorations, and archives
  are out of the item set entirely. Smallest surface, no cross-tool ownership problem, but the
  motivating questions about specs stay unanswered.
- (active) **Ignore the brief index.** Treat an exploration file's status as whatever its own H1 says,
  which in `dedicated` mode means every topic reads as open or unknown.
  Simple, and honest about what the file itself carries, but reports a status the owning skill does
  not consider authoritative.
- (deferred) **Single metadata format.** Introduce one machine-readable status slot (front-matter) across
  every family and harmonise `manage-spec` with it. Removes the multi-authority problem permanently,
  at the cost of a migration and of invalidating hand-authored files that have no front-matter.

## Decisions

- (settled) **All four families are items in v1**: `TASK-*`, `HANDOFF-*`, spec directories, and
  `EXPLO-<topic>.md` files.
- (settled) **One item per spec directory, carrier-aware.** `DISCOVERY.md` is not a separate item; it is
  the spec's carrier while the spec is in `discovery` or `explo`. The reported path is whichever
  carrier exists, so an item survives the `DISCOVERY.md` → `SPEC.md` rename instead of disappearing.
- (superseded) **Exploration topics take their status from the brief index** in `EXPLO-BRIEF.md`.
  Refined in `status-model`: when a brief exists, the brief itself is the item and its topics are not
  separate items, because a mixed brief has no single topic-level status.
- (settled) **Legacy `_SPECS/<slug>/` is detected for listing**, with status read from its hand-written
  H1 tag. Without this the command is useless on the repo's current corpus, which is entirely legacy.
- (settled) **`.ARCHIVED/` is scanned but excluded from the default listing.** Archived items are finished work
  in a separate bucket: discovery always sees them, a bare `ls` hides them behind a footer count, and an
  explicit `--filter archived` — or a group token — lists them.
- (settled) **Task and handoff files are matched anywhere under the walk.** The walk starts at the nearest git
  root and descends recursively, skipping `.git/`, dot-directories, and paths matched by `.gitignore`;
  `.ARCHIVED/` is the single dot-directory exemption, because the archive is scanned but hidden.
- (superseded) **Writes are limited to task-family H1 tags.** Managed specs, legacy specs, and exploration
  topics reported status without accepting transitions. Specs now accept the marker verbs (`claim`, `finish`,
  `undo`, `reset`, `archive`); legacy specs and exploration topics still refuse everything.
- (settled) **A slug present in both layouts is a hard error.** Both items keep the bare slug as id, and
  any verb taking that id fails listing both paths. Nothing is silently preferred; the fix is to finish
  the migration.

## Open threads

Nothing unresolved in this topic.
The duplicate-layout condition is expected during a partial migration, and the error carries the
resolution: run `manage-spec migrate` for the legacy directory.
