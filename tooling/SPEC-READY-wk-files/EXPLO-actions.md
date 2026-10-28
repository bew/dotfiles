# actions — exploration

The mutation side: what `wkf do <action>` may write, on which families, and what a transition means
when the status it touches is stored differently per family — and sometimes owned by another tool.

## Findings

- The task, idea, and bug families all carry status as hand-written H1 tags, with no other tool owning
  the heading.
  On a bug, `[CONFIRMED]` belongs to the reporter or triage and the rest to `wkf`; on a task or idea,
  `[READY]` is hand-written and the rest are `wkf`'s.
  Managed specs are written by `manage-spec`, exploration status lives in a brief index, and handoffs
  have no status convention at all.
- The task family stores status as an ordered tag stack, so a transition writes a tag rather than a field,
  and removing a state means removing tags.
- The command surface settled so far is query-only; `do` is the only place a write could live, and the
  user raised it as a direction ("I think 🤔") rather than a decision.
- `manage-spec` already exposes the spec lifecycle, including directory moves, so a delegating `do` would
  be a thin wrapper over an existing tool.
- The trash destination proposed earlier (`<devtree>/.state/trash/`) depends on a resolvable devtree root,
  which is a different resolution path than the scan root (nearest git root).

## Design crux

Every mutation costs something different per family: on a task, idea, or bug it edits a convention that
only the user's global instructions define, on a spec it duplicates a lifecycle tool, on a brief it edits
another skill's hub file, and on a handoff it would invent a convention that does not exist.
`do` is therefore mostly a decision about *scope of writing*, not about syntax.

## Candidate directions

None open.

## Decisions

### (settled) `write-scope` — Mutations write task, idea, and bug files, and specs through the marker verbs only

related-to: `spec-marker-verbs` & `specs-never-abandon`

A bug is written with its own tag vocabulary; see `bug-tag-ownership`.
Handoffs, legacy specs, and briefs refuse, each naming the owner of its status.
Queries still cover every family.

### (settled) `action-set` — The action set is `claim`, `finish`, `abandon`, `undo`, `reset`, `archive`

related-to: `mutations-under-do`

No other mutation exists: no separate ready action, no draft action, no unarchive.
`started` and `finished` are accepted as aliases for `claim` and `finish`, so the older wording still runs.

### (settled) `imperative-verbs` — The verbs are imperative and uniform

related-to: `action-set`

`claim` and `finish` replaced `start` and `finished` because `finished` read as a state next to `claim`
and `abandon`; a verb table with one grammatical mood is easier to scan and to remember.

### (settled) `reset-strips-wkf-tags` — `reset` strips every tag `wkf` wrote for that kind

related-to: `wkf-tag-set` & `undo-steps-back-one-tag`

`[CLAIMED]`, `[DONE]`, `[ABANDONED]` all go on a task or idea, and `[FIXING]`, `[FIXED]`, `[WONTFIX]` on
a bug, and the heading is left as it was before the first transition.
It is the coarse reversal, and one of the two actions that reach a terminal item.

### (settled) `undo-steps-back-one-tag` — `undo` steps back one tag, for one item

related-to: `reset-strips-wkf-tags` & `reset-hands-spec-back`

It removes the leftmost tag when `wkf` owns it for that kind and leaves the next one as the current
status, so a mistaken transition is undone without losing the trail behind it.
It refuses a leftmost tag owned by `manage-spec`, and it refuses more than one id because two items
rarely share a stack and a run over several would apply an unstated number of steps.

### (settled) `undo-is-not-a-flag` — `undo` is a separate verb rather than a flag on `reset`

related-to: `reset-strips-wkf-tags` & `undo-steps-back-one-tag`

`reset` is uniform across several ids and destroys the whole trail; making its depth configurable would
put that difference behind a flag, which is exactly the kind of difference a caller must not misread.

### (settled) `reset-hands-spec-back` — `reset`, not `undo`, hands a spec back to `manage-spec`

related-to: `spec-marker-verbs` & `undo-steps-back-one-tag`

A spec carrying a `wkf` marker is refused by the lifecycle tool, and one undo only removes the topmost
marker; clearing them all is the documented way out.

### (settled) `archive-not-delete` — `archive` replaces deletion, and nothing is deleted

related-to: `archived-is-a-location`

A terminal item is moved under `<root>/.ARCHIVED/<group>/` instead of removed, so the corpus keeps its
history and a mistaken run is repaired with an ordinary `mv`.

### (settled) `archive-requires-terminal` — `archive` accepts only a `done` or `abandoned` item

related-to: `archive-not-delete` & `abandon-refusals`

Uniformly for every kind.
Anything still draft, ready, or claimed refuses, which keeps archiving from becoming the shortcut past a
status the user cares about — `abandon` remains the deliberate way to retire unfinished work.

### (settled) `archive-no-confirmation` — `archive` needs no confirmation and has no `--force`

related-to: `archive-not-delete`

The interactive gate existed because deletion destroyed bytes; a move destroys nothing, so the action
stays scriptable and a non-interactive run can file an item away.

### (settled) `archived-is-read-only` — Archived items are read-only

related-to: `archive-not-delete`

Every action refuses them, `undo` and `reset` included; recovering an item is a manual move back into the
project, which keeps the archive a boundary rather than a second working set.

### (settled) `archiving-ends-a-spec` — Archiving ends a spec's life

related-to: `archive-not-delete` & `specs-never-abandon`

`manage-spec` no longer archives anything, so a shipped spec is marked `done` by `wkf do finish` and filed
by `wkf do archive`; the tag stack inside the archived directory is the final record of its lifecycle.

### (settled) `specs-never-abandon` — Specs accept the marker verbs and `archive`, never `abandon`

related-to: `write-scope` & `spec-marker-verbs`

Retirement stays a lifecycle state written by `manage-spec`, so `wkf` never writes the tag that
`manage-spec` owns.

### (settled) `wkf-tag-set` — The tags are per-kind

related-to: `bug-tag-ownership`
coupled-with: `transitions-stack`

On a task or idea, `wkf` writes `[CLAIMED]`, `[DONE]`, and `[ABANDONED]`.
The first two are the ones the corpus and the global convention already use; `[ABANDONED]` extends that
vocabulary by one rather than inventing a parallel set.

On a bug it writes `[FIXING]`, `[FIXED]`, and `[WONTFIX]` instead.
`[CONFIRMED]` is the bug's ready tag, owned by the reporter, and never written by `wkf`.

### (settled) `bug-tag-ownership` — Bug tags are kind-scoped, and `wkf` owns its kind's set

related-to: `wkf-tag-set` & `reset-strips-wkf-tags` & `write-scope`

`claim`, `finish`, and `abandon` write `[FIXING]`, `[FIXED]`, and `[WONTFIX]` on a bug, never the task
spellings.
`[CONFIRMED]` belongs to the reporter or triage: `wkf` reads it as `ready` and never writes or removes
it.
`reset` and `undo` act only on the tags `wkf` wrote for that kind, so a hand-written `[CLAIMED]` alias
on a bug is not something they may strip.
The task tags remain readable aliases on a bug; the reverse does not hold.

### (settled) `finish-without-claim-warns` — `finish` on a never-claimed item is allowed, with a warning

related-to: `transitions-stack`

The command writes `[DONE]` alone (`[FIXED]` on a bug) and says so, so the missing claim trail is
mentioned without blocking a one-shot item.

### (settled) `transitions-stack` — Transitions stack, prepending the new tag

related-to: `repeated-transition-refused`
coupled-with: `wkf-tag-set`

`finish` on a claimed task produces `[DONE] [CLAIMED]`, which is the shape the global convention already
describes, and the leftmost tag remains the current status.
A bug stacks the same way with its own tags: `[FIXED] [FIXING] [CONFIRMED]`.

### (settled) `repeated-transition-refused` — A repeated transition is refused

related-to: `transitions-stack`

`claim` on a claimed item and `finish` on a finished one both exit non-zero, so the stack never grows a
duplicate tag and a mistake is visible rather than swallowed.

### (settled) `batched-ids-stop-on-first-refusal` — One invocation may carry several ids, applied in order

related-to: `do-result-per-id`

The first failure stops the run and reports the ids left unprocessed.

### (settled) `abandon-refusals` — `abandon` refuses an already abandoned item and a done one

related-to: `terminal-exit-only-via-undo-reset`

Both end states are terminal, so every item finishes in exactly one of them and the stack never mixes
them.

### (settled) `terminal-exit-only-via-undo-reset` — Only `undo` and `reset` leave a terminal state

related-to: `abandon-refusals` & `undo-steps-back-one-tag`

`claim` and `finish` both refuse an abandoned item, and every action but the two reversals refuses a done
one, so the terminal groups are stable unless the user explicitly steps back.

## Rejected directions

- **Task files only** — too narrow for a tool whose job is finding artefacts.
- **Tag handoffs too** — invents a convention rather than reading one.
- **Delegate every write to the owner** — specs through `manage-spec`, brief status edited in
  the index; couples `wkf` to two other tools' file formats.
- **No `do` at all** — a read-only frontend leaves the harness where it started.

## Open threads

None open.
