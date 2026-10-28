# item-taxonomy — exploration

What counts as a file item, how its kind and status are derived, and which tool owns that status.
The spec's verb set cannot be chosen until this is settled: filtering, transition, and removal all
presuppose a stable item identity and a single readable status per item.

## Findings

- `manage-spec` owns the H1 status tag and the directory name of a managed spec, and moves the
  directory as the state changes.
  States: `discovery`, `explo`, `draft`, `maybe-ready`, `ready`, `abandoned`.
- Prefixes carry those states: `SPEC-DRAFT-<slug>/` for `discovery`, `explo`, `draft`, and
  `maybe-ready`; `SPEC-READY-<slug>/` for `ready`; `SPEC-KO-<slug>/` for `abandoned`.
  Four states share the draft prefix, so a `SPEC-DRAFT-` directory cannot say which of them it
  holds.
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
- `IDEA-<slug>.md` files exist beside the task and handoff families and are named in the same
  global convention, which keeps them out of git.
  The ones this repo carries all have a plain H1, so an untagged idea is the normal case rather than
  an accident.
- `BUG-<slug>.md` files join the same families, carrying a bug vocabulary — `[CONFIRMED]`,
  `[FIXING]`, `[FIXED]`, `[WONTFIX]` — whose states map one for one onto the task groups.
  A bug is a reported defect rather than deferred work, so the tag names the repair, not the generic
  work state.
- A capture opens with a frontmatter block above its H1, carrying `created-at: YYYYMMDDThhmm` and,
  where the file names one, `depends-on:`.
  The writers emit it and the migration skill backfills it.
  Spec carriers carry none, and `manage-spec` is the tool that would own adding it there.
- Legacy captures still spell the date into the filename, as `TASK-20261001T1110-<slug>.md` or
  `TASK-20260920-<slug>.md`.
  Both forms name the same kind, so the date segment is optional when reading, and the corpus
  converges on the undated form as files get touched.
- Legacy specs live in `_SPECS/<slug>/`; `manage-spec migrate` moves them out, and `migrate` is
  deliberately absent from `--help`.
- The lifecycle no longer archives anything: `abandoned` keeps its `SPEC-KO-<slug>/` directory in
  place, and filing is `wkf do archive`, which moves a terminal item to `.ARCHIVED/<group>/` under the
  walk root.
  An archived spec is out of `manage-spec`'s reach for good.
- Beads remains the other backend and is untouched by any of this.

## Design crux

The artefact corpus has two different status authorities — the H1 tag for tasks, ideas, bugs, handoffs,
and managed specs, and the brief index for exploration topics — plus one family whose carrier filename
moves as its status changes.
`wk file` must present one readable status per item without becoming a second writer of state that
`manage-spec` and the exploration skill already own.
The frontmatter block settles where a timestamp comes from, not where status comes from: the H1 tag
stays the authority.

## Candidate directions

- (deferred) **Front-matter slot** — one machine-readable field per family removes the multi-authority
  problem permanently.
  Captures already carry the block, while spec carriers and hand-written files may not, so the cost
  that remains is a second migration for the families that lack it.

## Decisions

### (settled) `item-families` — Every artefact family under the walk is an item

`TASK-*`, `HANDOFF-*`, `IDEA-*`, `BUG-*`, spec directories, and `EXPLO-<topic>.md` files.

An idea is a file family the harness already writes, listed in the global conventions beside tasks and
handoffs, and it carries the same tag vocabulary.
Leaving it out would make `wkf` blind to a kind the surrounding tooling already treats as an artefact.
A bug is the same shape of file with its own vocabulary; folding it into the task family would lose
the distinction between deferred work and a reported defect.

### (settled) `bug-family` — Bugs are their own kind with their own tag vocabulary

related-to: `item-families`

`BUG-<slug>.md` files are items of kind `bug`, beside tasks, ideas, and handoffs, with the legacy
dated name accepted on read.
Their tags are `[CONFIRMED]`, `[FIXING]`, `[FIXED]`, and `[WONTFIX]`; the task tags are accepted on
read as aliases.
One vocabulary per kind keeps every write unambiguous: `claim` on a bug means `[FIXING]`, never
`[CLAIMED]`, and a fixed bug reads `[FIXED]` on disk rather than borrowing a task's `[DONE]`.

### (settled) `frontmatter-carries-time-not-status` — The block supplies the timestamp, the H1 keeps the status

related-to: `item-families`

`created-at:` is the only field `wkf` reads, and it orders rows within a directory: status, then
directory, then newest first, then name.
An item with no block sorts last in its directory, and that is not an error, because spec carriers
carry none.
`depends-on:` is echoed on `show` and resolved by nothing.
Status stays on the H1 tag, since the block is written once at capture and never updated.
Moving status into the block is conceivable later; nothing in `wkf` reads it that way today.

### (settled) `one-item-per-spec-carrier-aware` — One item per spec directory, carrier-aware

related-to: `item-families`

`DISCOVERY.md` is not a separate item; it is the spec's carrier while the spec is in `discovery` or
`explo`.
The reported location is whichever carrier exists, so an item survives the `DISCOVERY.md` →
`SPEC.md` rename instead of disappearing.

### (settled) `legacy-specs-listed` — Legacy `_SPECS/<slug>/` is detected for listing

related-to: `one-item-per-spec-carrier-aware`

Status is read from its hand-written H1 tag.
Without this the command is useless on the repo's current corpus, which is entirely legacy.

### (settled) `walk-rules` — Item files are matched anywhere under the walk

related-to: `archived-is-a-location`
coupled-with: `path-inside-walk`

The walk starts at the nearest git root and descends recursively, skipping `.git/`, dot-directories, and
paths matched by `.gitignore`.
`.ARCHIVED/` is the single dot-directory exemption, because discovery must reach the archive even when no
listing shows it.

### (settled) `duplicate-slug-is-error` — A slug present in both layouts is a hard error

related-to: `slug-uniqueness` & `legacy-specs-listed`

Both items keep the bare slug as id, and any verb taking that id fails listing both paths.
Nothing is silently preferred; the fix is to finish the migration.

## Rejected directions

- **Task-family-only items** — `TASK-*` and `HANDOFF-*` alone leave the motivating questions
  about specs unanswered.
- **Topic H1 as authority** — read each topic's own status instead of the brief index; it
  reports a status the owning skill does not consider authoritative.

## Open threads

Nothing unresolved in this topic.
The duplicate-layout condition is expected during a partial migration, and the error carries the
resolution: run `manage-spec migrate` for the legacy directory.
