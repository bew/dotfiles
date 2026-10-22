# actions — exploration

The mutation side: what `wkf do <action>` may write, on which families, and what a transition means
when the status it touches is stored differently per family — and sometimes owned by another tool.

## Findings

- Of the four families, only the task family's status is both hand-written and unowned.
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

Every mutation costs something different per family: on a task it edits a convention that only the user's
global instructions define, on a spec it duplicates a lifecycle tool, on a brief it edits another skill's
hub file, and on a handoff it would invent a convention that does not exist.
`do` is therefore mostly a decision about *scope of writing*, not about syntax.

## Candidate directions

- (active) **Write tasks only.** `do` accepts task ids and refuses every other family with a message naming
  the owner (`manage-spec` for specs, the brief for explorations, "no status convention" for handoffs).
  Smallest truthful surface; queries still cover all families.
- (active) **Write tasks and handoffs.** Treat a handoff like a task and introduce the same tags, which
  creates a convention rather than reading one.
- (active) **Delegate where an owner exists.** Tasks are edited directly, specs shell out to `manage-spec`,
  and brief status is updated in the index. One command for everything, at the cost of coupling `wk` to two
  other tools' file formats.
- (active) **No `do` in v1.** Ship queries only; mutations stay manual until the query surface is in use.
  Defensible, and it keeps the spec small, but it leaves the harness with a read-only frontend.

## Decisions

- (settled) **Mutations write tasks and, for the marker verbs only, specs.** Handoffs, legacy specs, and
  briefs refuse, each naming the owner of its status. Queries still cover every family.
  See the later `claim`/`finish`/`undo`/`reset` decisions below — this entry replaces the earlier tasks-only
  rule.
- (superseded) **The action verbs live under `do`**: `wkf do start`, `wkf do finished`, `wkf do abandon`,
  `wkf do rm`. Kept in spirit — every mutation still lives under `do` — with the verb set renamed below.
- (settled) **The action set is `claim`, `finish`, `abandon`, `undo`, `reset`, `archive`.** No other mutation
  exists: no separate ready action, no draft action, no unarchive. `started` and `finished` are accepted as
  aliases for `claim` and `finish`, so the older wording still runs.
- (settled) **The verbs are imperative and uniform.** `claim` and `finish` replaced `start` and `finished`
  because `finished` read as a state next to `claim` and `abandon`; a verb table with one grammatical mood is
  easier to scan and to remember.
- (settled) **`reset` strips every tag `wkf` wrote** — `[CLAIMED]`, `[DONE]`, `[ABANDONED]` — and leaves the
  heading as it was before the first transition. It is the coarse reversal, and one of the two actions that
  reach a terminal item.
- (settled) **`undo` steps back one tag, for one item.** It removes the leftmost tag when `wkf` owns it and
  leaves the next one as the current status, so a mistaken transition is undone without losing the trail behind
  it. It refuses a leftmost tag owned by `manage-spec`, and it refuses more than one id because two items rarely
  share a stack and a run over several would apply an unstated number of steps.
- (settled) **`undo` is a separate verb rather than a flag on `reset`.** `reset` is uniform across several ids
  and destroys the whole trail; making its depth configurable would put that difference behind a flag, which is
  exactly the kind of difference a caller must not misread.
- (settled) **`reset`, not `undo`, hands a spec back to `manage-spec`.** A spec carrying a `wkf` marker is
  refused by the lifecycle tool, and one undo only removes the topmost marker; clearing them all is the
  documented way out.
- (settled) **`rm` is replaced by `archive`, and nothing is deleted.** The command was renamed and its effect
  reversed: a terminal item is moved under `<root>/.ARCHIVED/<group>/` instead of removed, so the corpus keeps
  its history and a mistaken run is repaired with an ordinary `mv`.
- (settled) **`archive` accepts only a `done` or `abandoned` item**, uniformly for every kind. Anything still
  draft, ready, or claimed refuses, which keeps archiving from becoming the shortcut past a status the user
  cares about — `abandon` remains the deliberate way to retire unfinished work.
- (settled) **`archive` needs no confirmation and has no `--force`.** The interactive gate existed because `rm`
  destroyed bytes; a move destroys nothing, so the action stays scriptable and a non-interactive run can file an
  item away.
- (settled) **Archived items are read-only.** Every action refuses them, `undo` and `reset` included; recovering
  an item is a manual move back into the project, which keeps the archive a boundary rather than a second working
  set.
- (settled) **Archiving ends a spec's life.** `manage-spec` no longer archives anything, so a shipped spec is
  marked `done` by `wkf do finish` and filed by `wkf do archive`; the tag stack inside the archived directory is
  the final record of its lifecycle.
- (settled) **Specs accept `claim`, `finish`, `undo`, `reset`, and `archive`, and never `abandon`.** Retirement
  stays a lifecycle state written by `manage-spec`, so `wkf` never writes the tag that `manage-spec` owns.
- (settled) **The tags are `[CLAIMED]`, `[DONE]`, `[ABANDONED]`.** The first two are the ones the corpus and
  the global convention already use; `[ABANDONED]` extends that vocabulary by one rather than inventing a
  parallel set.
- (settled) **`finish` on a never-claimed item is allowed, with a warning.** The command writes `[DONE]`
  alone and says so, so the missing claim trail is mentioned without blocking a one-shot task.
- (settled) **Transitions stack, prepending the new tag.** `finish` on a claimed task produces
  `[DONE] [CLAIMED]`, which is the shape the global convention already describes, and the leftmost tag
  remains the current status.
- (superseded) **`rm` deletes the file.** Replaced by `archive`: the corpus keeps its history, and the archive
  location is the walk root, so no devtree-root dependency was needed after all.
- (superseded) **`rm` only accepts a task that is done or abandoned.** Kept as the eligibility rule and
  generalised to every kind; the effect is a move rather than a deletion.
- (superseded) **`rm` requires an interactive confirmation prompt.** Removed with the deletion: a move needs no
  gate, and the action stays usable from a script.
- (settled) **A repeated transition is refused.** `claim` on a claimed item and `finish` on a finished
  one both exit non-zero, so the stack never grows a duplicate tag and a mistake is visible rather than
  swallowed.
- (settled) **One invocation may carry several ids**, applied in order; the first failure stops the run and
  reports the ids left unprocessed.
- (settled) **`abandon` refuses an already abandoned task and a done one.** Both end states are terminal, so
  every task finishes in exactly one of them and the stack never mixes them.
- (settled) **Only `undo` and `reset` leave a terminal state.** `claim` and `finish` both refuse an abandoned
  item, and every action but the two reversals refuses a done one, so the terminal groups are stable unless the
  user explicitly steps back.
- (settled) **`abandoned` is a filter group.** `wkf ls --filter abandoned` lists retired tasks, so an
  abandoned item is reachable without showing everything.
