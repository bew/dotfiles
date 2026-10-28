# [READY] wk-files — File-backed work items

## Introduction

A devtree project accumulates planning material as plain markdown.

Task notes sit at the project root as `TASK-<slug>.md`, idea notes and bug reports as `IDEA-<slug>.md` and `BUG-<slug>.md`, handoff documents as `HANDOFF-<slug>.md`, and larger pieces of work live in spec directories seeded and moved by `manage-spec`, each holding a `DISCOVERY.md`, a `SPEC.md`, and one `EXPLO-<topic>.md` per exploration topic.

A date segment in a capture name, as in `TASK-20261001T1110-fix-parser.md`, is the legacy form that older files still carry; the timestamp now lives in the file's frontmatter.

Every one of those files declares what it is in its filename and where it stands in the first line of its H1 heading.

Nothing reads those declarations.

Answering "what is ready in this project" or "which specs are still claimed" means listing directory entries and reading headings by hand, and an agent asked to pick up the next piece of work does the same thing with less patience.

The harness already has a frontend for the other half of the problem: `wk` wraps `bd`, so beads issues are listable, filterable, and addressable from a command line.

File-backed artefacts have no equivalent surface.

`wk-files` is that surface.
It is invoked as `wkf`.

It manages artefacts that already exist: it enumerates them, filters them by the state they are in, shows where each one lives, and applies the small set of transitions the conventions already describe.

It never creates files, scaffolds templates, chooses names, or invents titles.
Starting work stays the act of writing a file, by hand or by a skill that knows the template.

The two backends stay separate on purpose.
`wk` keeps wrapping `bd` and stays unaware of this addition, so file-backed management ships as a command of its own instead of a namespace inside the beads frontend.
A unified surface over both stores is a plausible future, and deliberately not this spec.

Scope is one project at a time: the tree of the project reachable from the current directory.
A listing starts where the caller stands and widens to the project root on request, while an id names its item from anywhere in the project.
Cross-devtree listing, and any synchronisation between the two stores, are out of scope.

## Naming & IDs

The kinds are `task`, `handoff`, `idea`, `bug`, `spec`, and `explo`.
An id names one item: `[kind]:[name]` or `[kind]:[name]:[part]`.

The walk is the scan an item comes from: it starts at the nearest git root and descends recursively.
Placement / Scope defines exactly what it skips.

| Kind | Artefact | Id |
|------|----------|-----|
| `task` | `TASK-<slug>.md` anywhere under the walk | `task:fix-parser` |
| `handoff` | `HANDOFF-<slug>.md` anywhere under the walk | `handoff:beads-shared-server` |
| `idea` | `IDEA-<slug>.md` anywhere under the walk | `idea:ask-for-each-mode` |
| `bug` | `BUG-<slug>.md` anywhere under the walk | `bug:parser-drops-eof` |
| `spec` | `SPEC-DRAFT-<slug>/`, `SPEC-READY-<slug>/`, `SPEC-KO-<slug>/`, or legacy `_SPECS/<slug>/` | `spec:wk-files` |
| `spec` | that spec's `EXPLO-BRIEF.md` | `spec:wk-files:explo` |
| `explo` | a standalone `EXPLO-<slug>.md` outside any spec directory | `explo:devtree-hook` |

The name drops three things: the kind prefix, an optional leading date or timestamp token, and the `.md` suffix.
`TASK-fix-parser.md` is `task:fix-parser`, and so is the legacy `TASK-20261001T1110-fix-parser.md`: the kind token already carries the type, and a date is metadata rather than identity.

The timestamp comes from the `created-at` field of the frontmatter block a capture opens with, falling back to a leading date token in a legacy name.
Parse `20261001T1110` and `20260920` down to the calendar day, discard the time, and expose it on `show`.
When a legacy name and a block disagree, the block wins; the filename token is read only when the block is absent.

The timestamp orders rows, but never decides a status or a section: rows sort by status, then by directory, then by `created-at` newest first, then by name.
An item with neither a block nor a date token sorts after the others in its directory, keeping name order among its peers.

A spec id is its slug and survives everything the lifecycle does to it — the `DISCOVERY.md` to `SPEC.md` carrier change, and the directory moves between the draft, ready, and retired prefixes.
Path, carrier, and status change; the id does not.

Arguments resolve against the filesystem, not against syntax.
An argument is a path when it points at an existing file inside the walk, and an id when it matches exactly one discovered item; either form is accepted by every verb that takes an item.

```pseudocode
resolve(arg):
    path_hit = arg is an existing file inside the walk
    id_hit   = arg matches exactly one discovered item
    dups     = more than one item of the same kind reduces to the same slug
    if path_hit and id_hit and different items -> ambiguous error, naming both
    if path_hit -> that item
    if dups     -> duplicate-slug error, naming every colliding path
    if id_hit   -> that item
    if ":" in arg -> unknown id error
    else          -> file not found error
```

An argument outside the walk is never an item, however it is spelled.

An id is portable within one project: it means the same item from any directory of that project, because a slug belongs to exactly one item of its kind there.
Across projects it means nothing — two repos can each own `task:fix-parser`, and a command run in the wrong project resolves the wrong item or none at all.

Slug uniqueness is a corpus invariant, not a lookup strategy: within one kind, no two items share a slug, wherever they sit in the tree.
`wkf` never creates files, so it cannot enforce the invariant at the source; what it can do is refuse to paper over a violation, which is why a duplicate is an error rather than something the id syntax works around.
A duplicate reaches the user as an error naming every colliding path, and the repair is a rename by hand — e.g. two `SPEC-<slug>/` directories, or a slug present in both `_SPECS/<slug>/` and `SPEC-DRAFT-<slug>/`, which `manage-spec migrate` resolves.

It is fatal only where it can affect the answer.
A `--type` filter that excludes the colliding kind, or a query that never names those items, runs normally; an unfiltered listing, or any id resolving to the shared slug, fails instead of returning an answer it cannot name honestly.
So a listing never prints two rows under one id, and a corpus with a duplicate stays usable everywhere the duplicate is irrelevant.

## Interface / How to use

`wkf` exposes the listing verbs and the item verbs at the top level, and every mutation under `do`.

The listings answer different questions: `status` curates and groups, `ls` lists everything outside the archive.

```console
$ wkf --help
Usage: wkf <command> [options]

COMMANDS:
  status                 grouped listing, the default view
  ls                     flat listing, archived excluded
  draft|ready|claimed|done|abandoned
                         list one status group (status --filter sugar)
  show <id|path>         report one item
  do <action> <id|path>  apply a mutation

OPTIONS:
  --by-dir               group by directory first (status default)
  --by-status            group by status first (status only)
  --filter <tokens>      draft, ready, claimed, done, abandoned, archived; prefix `+` to add
  --type <kinds>         comma-separated: task, handoff, idea, bug, spec, explo
  --all                  list from the project root instead of the current directory
  --json                 machine-readable output (any command)

actions: claim, finish, abandon, undo, reset, archive
```

Both listings show the invocation directory and everything below it, and `--all` widens that to the whole project.
The item commands ignore the current directory, so an id or a path names the same item from anywhere in the project.
Scope is a listing concern; see Placement / Scope for the tree itself.

### `status`

Bare `wkf status` answers "what is where": it groups by directory, and each directory holds its items under status headings.

Both levels always print, even when a directory holds a single group, so a heading never hides the shape of the answer.
Every heading names its axis, `Dir: <label>` for a directory section and `Status: <group>` for a status section, on both levels and on both axes.
A section's body sits one rail deeper than its heading: an outer heading starts at the margin, the inner headings under it start with `│ `, and the tables under those start with `│ │ `.
Two inner sections are separated by a `├───` junction line, whose length reaches the body depth of the section that follows.
Outer sections are separated by a blank line, and the output opens and closes with one.

```console
$ wkf status

Dir: Current dir
│ Status: ready
│ │ ID                               STATUS  CREATED
│ │ spec:cross-devtree-task-routing  READY   2026-10-14
│ │ task:promote-devtree-tooling     READY   2026-09-30
├───
│ Status: claimed
│ │ ID               STATUS   CREATED
│ │ task:fix-parser  CLAIMED  2026-10-05
├───
│ Status: draft
│ │ ID                STATUS  CREATED
│ │ task:draft-notes  -       2026-09-30

Dir: ./tooling
│ Status: claimed
│ │ ID             STATUS   CREATED
│ │ spec:wk-files  CLAIMED  -

elsewhere: 2 ready, 5 draft · not archived: 3 done, 2 abandoned · archived: 1 done, 4 abandoned

```

The default selection is the live groups: `draft`, `ready`, and `claimed`.

`--by-dir` is the default axis and `--by-status` swaps them:
```console
$ wkf status --by-status

Status: ready
│ Dir: Current dir
│ │ ID                               STATUS  CREATED
│ │ spec:cross-devtree-task-routing  READY   2026-10-14
│ │ task:promote-devtree-tooling     READY   2026-09-30

Status: claimed
│ Dir: Current dir
│ │ ID               STATUS   CREATED
│ │ task:fix-parser  CLAIMED  2026-10-05
├───
│ Dir: ./tooling
│ │ ID             STATUS   CREATED
│ │ spec:wk-files  CLAIMED  -

Status: draft
│ Dir: Current dir
│ │ ID                STATUS  CREATED
│ │ task:draft-notes  -       2026-09-30

```

A status section keeps the same order whether it is outer or inner: `ready`, `claimed`, `draft`, then `done` and `abandoned` when a filter selects them.
The order does not depend on which axis is outer, so the two views agree row for row.

A directory section is the item's immediate parent directory, with no roll-up: no merging a chain of single-child directories, and a spec groups under the parent of its spec directory, so `tooling/SPEC-DRAFT-wk-files/SPEC.md` sits under `tooling`.
Directory sections appear in ascending order of their root-anchored path, so a listing reads top-down through the tree.

A directory heading reads `Dir: ` followed by the directory named with as little decoration as possible: `Current dir` for the directory `wkf` was invoked in, `Project root` for the root (when the current directory is the root, or when `--all` reached it), and `./<path>` for every other directory, the leading `./` marking it as a path below the root.

The status column carries the raw tag, never a group name, so a row says which tag put it in its section.

### `ls`

`ls` answers "what is there" with one flat table and no headings.

It has no default selection: every item in scope appears, terminal work included, so a row is either present or excluded by an explicit token.
The only thing it leaves out is the archive, which `--filter archived` reaches like any other selection.

```console
$ wkf ls
ID                               STATUS   DIR       CREATED
spec:cross-devtree-task-routing  READY    /         2026-10-14
task:promote-devtree-tooling     READY    /         2026-09-30
task:fix-parser                  CLAIMED  /         2026-10-05
spec:wk-files                    CLAIMED  /tooling  -
task:draft-notes                 -        /         2026-09-30
task:old-thing                   DONE     /         2026-08-11
```

Rows sort by status in group order, then by directory, then by `created-at` newest first, then by name.
Reading the table top to bottom therefore walks the same sequence `status` uses, with the headings removed and the directory promoted into its own column.

`ls` takes one optional positional token naming a group, which is `--filter` with that value:
```console
$ wkf ls ready          # same as: wkf ls --filter ready
```

### Closers

`status` closes with one line of labelled segments, in a fixed order, carrying only the segments that apply to it:

```console
elsewhere: 2 ready, 5 draft · not archived: 3 done, 2 abandoned · archived: 1 done, 4 abandoned
```

`elsewhere` counts what the scope excludes — the items above the invocation directory — per selected group, in
the section order, omitting groups with nothing there.
It is scope information, not a hidden state: those items exist and a wider run would show them.
Archived work is never part of it.

`not archived` counts the terminal items still in the project, so the segment's job is reminding that
archiving is outstanding.

`archived` counts the work already filed under `.ARCHIVED/`, in the same two groups, so the archive stays
visible without ever being listed.

A segment with nothing to count is dropped, and the line disappears when all three are empty.
A flat `ls` prints no closer at all: it lists every non-archived item in scope, so a count would restate rows already on screen.

### Filters

`--filter` takes a comma-separated list of tokens and prints only what they select.
It works the same way on both listings; the only difference is how the result is presented.
An unknown token exits non-zero and lists the valid ones.

```console
$ wkf status --filter ready,claimed
$ wkf ls --filter ready,claimed
$ wkf ready   # same as: wkf status --filter ready
```

The tokens are `draft`, `ready`, `claimed`, `done`, `abandoned`, and `archived`.
Every token but `archived` names a status group; `archived` is a location filter selecting everything under `.ARCHIVED/`, done and abandoned items alike.
No listing reaches the archive unless a token selects it, so archived items never appear as rows on their own, in tables or in JSON.
The closing line counts them; it never lists them.
`started` is accepted as an alias for `claimed`, so output and filters read the same whether a caller learned the older vocabulary or the current one.

There is no `implemented` token: no artefact carries that state any more, and `done` is the only name for a shipped item.

A plain list replaces the base selection, so `--filter done` shows finished work and nothing else.
The base differs by verb — the live groups for `status`, every non-archived item for `ls` — and prefixing a token with `+` adds to it instead:
```console
$ wkf status --filter +done          # live groups + done items
$ wkf status --filter +archived      # live groups + archived items
$ wkf ls --filter +archived          # everything + archived items
```

`--type` takes a comma-separated list of kinds — `task`, `handoff`, `idea`, `bug`, `spec`, `explo` — and narrows by what an
item is rather than by where it stands.
The two filters compose, so `wkf status --type spec --filter ready` is "specs awaiting work".
The selection is computed once and drives the whole answer, including the `elsewhere` counts: narrowing by type never
leaves a count describing items the tables cannot show.

```console
$ wkf ls --type spec
$ wkf status --type task,handoff
```

The group verbs exist for the questions actually asked; they are sugar over one lookup, not a second code path.

`--json` is accepted by every command — see Output & Scripting.

### `show`

`show` reports one item and never prints its content.
It answers where the item is and what state it is in, so a caller can open the file itself.

```console
$ wkf show task:fix-parser
id:      task:fix-parser
kind:    task
status:  CLAIMED
groups:  claimed
created: 2026-10-05
path:    /TASK-fix-parser.md
```

`depends-on` follows `created` when the block names one:
```console
$ wkf show task:wire-up
id:         task:wire-up
kind:       task
status:     READY
groups:     ready
created:    2026-09-20
depends-on: task:deep-modules
path:       /TASK-wire-up.md
```

A spec carries neither field and lists the parts it holds instead:
```console
$ wkf show spec:wk-files
id:      spec:wk-files
kind:    spec
status:  DRAFT
groups:  draft
parts:   explo, spec
path:    /tooling/SPEC-DRAFT-wk-files/SPEC.md
```

`status` is the raw leftmost tag and prints `-` when the artefact carries none; `groups` is a list because a brief matches two groups at once, and a handoff has a group without ever having a tag.

`depends-on` is echoed as the file writes it, and `wkf` neither resolves nor enforces it.

`parts` names the artefacts present in the spec directory — `discovery`, `spec`, `explo` — so the caller sees what exists without a second listing.
The path points at the carrier in use, printed as one root-anchored location; the structured form splits that same location into a directory and the remainder below it.

### `do`

Every mutation is a `do` action, applied to one or more items in the order given.

```console
$ wkf do claim task:fix-parser
task:fix-parser: CLAIMED (was -)

$ wkf do claim spec:beads-shared-server
spec:beads-shared-server: CLAIMED (was -)

$ wkf do finish task:fix-parser task:other task:rest
task:fix-parser: DONE (was CLAIMED)
task:other: refused: already done
1 id not processed: task:rest
```

The first refusal stops the run; ids that did not run are named as unprocessed.

`undo` steps back one tag, and `reset` clears every tag `wkf` wrote.
The difference is depth: `undo` reverses the transition just made, `reset` returns the heading to how it looked before the first one.

```console
$ wkf do undo task:fix-parser
task:fix-parser: CLAIMED (was DONE)
```

`undo` takes exactly one item, because two items rarely share a stack and a run over several would apply an unstated number of steps.
`reset` takes several like every other action.

```console
$ wkf do reset spec:wk-files
spec:wk-files: READY (was CLAIMED)
```

Both reversals reach an item in a terminal state, and no other action does.
A spec carrying a `wkf` marker stays outside `manage-spec`'s reach until a `reset` clears every marker, so `reset` — not `undo` — is what hands the spec back to the lifecycle tool.

`archive` files a terminal item away, and deletes nothing:
```console
$ wkf do archive task:old-thing
task:old-thing: archived to /.ARCHIVED/done/ (was DONE)
```

`started` and `finished` are accepted as aliases for `claim` and `finish`.

See Write Invariants for what each action may touch.

## Status Model

Separate vocabularies feed one set of groups.
The file owner writes the tag; `wkf` only maps it.

| Kind | On disk | Group |
|------|---------|-------|
| task, idea | no tag | draft |
| task, idea | `[READY]` | ready |
| task, idea | `[CLAIMED]` | claimed |
| task, idea | `[DONE]` | done |
| task, idea | `[ABANDONED]` | abandoned |
| bug | no tag | draft |
| bug | `[CONFIRMED]` | ready |
| bug | `[FIXING]` | claimed |
| bug | `[FIXED]` | done |
| bug | `[WONTFIX]` | abandoned |
| handoff | no status convention at all | ready |
| spec | `DISCOVERY`, `EXPLO`, `DRAFT`, `MAYBE-READY` | draft |
| spec | `READY` | ready |
| spec | `[CLAIMED]` prepended by `wkf`, ahead of the spec tag | claimed |
| spec | `[DONE]` prepended by `wkf`, ahead of the spec tag | done |
| spec | `ABANDONED`, written by `manage-spec` | abandoned |

A handoff is always `ready`: the format defines no status, and a handoff exists to be picked up, so the
absence of a tag means waiting for work rather than unfinished material.

`maybe-ready` belongs to `draft` rather than `ready`, because a proposal not yet accepted for work is still
draft material.

### Bug vocabulary

A bug reports something broken, so its tags name the repair rather than the generic work states.

| On disk | Group | Task alias |
|---------|-------|------------|
| no tag | draft | — |
| `[CONFIRMED]` | ready | `[READY]` |
| `[FIXING]` | claimed | `[CLAIMED]` |
| `[FIXED]` | done | `[DONE]` |
| `[WONTFIX]` | abandoned | `[ABANDONED]` |

An untagged bug is open and untriaged: it has been reported, not accepted for work.
`[CONFIRMED]` means someone reproduced or otherwise accepted it, and like `[READY]` it belongs to the
reporter or triage rather than to `wkf`.

`wkf` writes only the bug tags: `claim` prepends `[FIXING]`, `finish` `[FIXED]`, and `abandon`
`[WONTFIX]`.
It accepts the task tags on read as aliases, so a bug a human tagged `[CLAIMED]` still reports as
claimed, but no action ever writes that spelling onto a bug.
The reverse does not hold: `[FIXING]` and its siblings are not status tags on a task or an idea.

Ownership stays kind-scoped.
`reset` and `undo` remove only the tags `wkf` wrote for that kind — the bug tags on a bug, the task
tags on a task or an idea — and never touch `[CONFIRMED]`, which no action owns.

### Two writers, one heading

A spec's heading has two authors, and they stack rather than compete.

`manage-spec` owns the spec tag and writes it where it already is.
`wkf` owns `[CLAIMED]` and `[DONE]`, and prepends them, so the spec's own tag survives underneath as the record of what the lifecycle thinks:
```md
# [DONE] [CLAIMED] [READY] wk-files — File-backed work items
```

Both tools read the leftmost tag, so both agree on the group without either one rewriting the other's vocabulary.
`manage-spec` refuses to act on a spec carrying a `wkf` marker, because a state move would rewrite a heading it does not own; `wkf do reset` is what clears the marker and hands the spec back.
That refusal is the whole reason the marker is legal: two writers never touch the same heading at the same time.

### Reading a stacked tag

A heading can carry several tags, and the **leftmost is the current status**.

```md
# [DONE] [CLAIMED] Old task that was started then finished
```

That file is `done`.
The stack is the claim trail, not a set to be re-evaluated, and reading it right-to-left would report work
as in progress after it finished.

A heading with no recognised tag is `draft`, not an error: the tag is a convention, and a file that has not
adopted it yet is simply unstarted.

### Exploration material

A standalone `EXPLO-<slug>.md` is `draft`: it carries no index and no tag, so nothing says it is ready or in flight, and it reports as unstarted material like any other untagged file.

Inside a spec directory, `EXPLO-BRIEF.md` is the item and its topics are not.
A brief's status is derived from its topic index: any `active` or `revived` topic means `draft` and `claimed`; all `frozen` means `ready` and `done`; an empty index means `draft`.

Topics match two groups at once because they answer two questions.
`active` and `revived` mean in flight, so they match `draft` and `claimed`; `frozen` means both settled and
finished, so it matches `ready` and `done`.

### Groups and location

The groups are `draft`, `ready`, `claimed`, `done`, and `abandoned`.
`archived` is not a group: it selects by where an item lives (`.ARCHIVED/`), not by what state it is in.

The tool's vocabulary has one name per end state, which is `done`, whatever tag produced it.
A task or idea reaches it by `[DONE]`, a bug by `[FIXED]`, and a spec by the `[DONE]` marker `wkf` prepends.
Abandonment works the same way: `[ABANDONED]` on a task or idea, `[WONTFIX]` on a bug.
The tag spelling varies by kind, but the group does not, so no second end-state name exists.

## Write Invariants

### What may be written

Tasks, ideas, and bugs accept every action.
Specs accept `claim`, `finish`, `undo`, `reset`, and `archive`, the actions that add or remove a `wkf`-owned marker without rewriting the tag `manage-spec` wrote.

Specs never accept `abandon`: retirement is a lifecycle state, `manage-spec abandoned` writes it, and the directory then stays where it is until the item is archived.
Naming `manage-spec` rather than writing an abandonment tag keeps the spec's own vocabulary single-authored.

Handoffs define no status, legacy specs are on their way out, and exploration status lives in a brief index owned by the exploration workflow, so each refuses every action.
Each refusal names the owner rather than failing silently.

### Transitions

A transition prepends a tag and leaves the existing ones in place.
On a task or idea `claim` writes `[CLAIMED]`, `finish` writes `[DONE]`, and `abandon` writes
`[ABANDONED]`; on a bug the same actions write `[FIXING]`, `[FIXED]`, and `[WONTFIX]`.

```md
# [READY] Fix the parser                 # wkf do claim
# [CLAIMED] [READY] Fix the parser       # wkf do finish
# [DONE] [CLAIMED] [READY] Fix the parser
```

A spec follows the same shape, with its `manage-spec` tag at the bottom of the stack and untouched.

`reset` is not a transition but a removal: it drops every tag `wkf` wrote for that kind — `[CLAIMED]`,
`[DONE]`, `[ABANDONED]` on a task or idea; `[FIXING]`, `[FIXED]`, `[WONTFIX]` on a bug — and leaves
whatever was underneath.

```md
# [DONE] [CLAIMED] [READY] wk-files — File-backed work items   # wkf do reset
# [READY] wk-files — File-backed work items
```

`undo` is the same removal one step deep: it drops the leftmost tag when `wkf` owns it for that kind, leaving the next one in its place.

```md
# [DONE] [CLAIMED] [READY] wk-files — File-backed work items   # wkf do undo
# [CLAIMED] [READY] wk-files — File-backed work items
```

Neither reversal touches a tag it did not write, so the tag `manage-spec` owns is never removed, only uncovered.

The stack is history: the leftmost tag is the current status, and the ones after it record how the item got
there.
Only the heading line is touched; the body is never rewritten.

### Refusals

An action refuses rather than no-ops, and a refusal exits non-zero.

- `claim` refuses an item already claimed, done, or abandoned.
- `finish` refuses an item already done or abandoned.
- `abandon` refuses an item already abandoned or done.
- `finish` on a never-claimed item is allowed, and warns that the claim trail is missing.
- `reset` refuses an item carrying no `wkf` tag for its kind, since there is nothing to clear.
- `undo` refuses an item whose leftmost tag is not `wkf`-owned, naming the owner of the tag that is there, so a spec's lifecycle tag is never removed by the wrong tool.
- `undo` refuses more than one id as a usage error rather than acting on the first.
- Every action refuses an archived item: the archive is read-only, and getting something back out is a manual move.
- Nothing leaves `done` or `abandoned` except through `undo` or `reset`, which are the deliberate reversals; no other action reopens a terminal item.

### Archiving

`archive` accepts a terminal item — `done` or `abandoned` — and moves it under the walk root, to `<root>/.ARCHIVED/<group>/`.
A task, idea, or bug moves as its file; a spec moves with its directory and its tags untouched, so the whole artefact travels together.

Nothing is deleted, so there is no confirmation prompt and no `--force`.
An item still `draft`, `ready`, or `claimed` refuses, which keeps archiving from becoming the shortcut past a status the user cares about; `abandon` remains the deliberate way to retire work that will not be finished.

Archiving is the end of a spec's life: the directory leaves the project layout, `manage-spec` no longer sees it, and the archived tag stack is the final record of what happened.
For a claimed spec that shipped, `finish` is what makes it a `done` item, and `archive` is what files it.
Because nothing is destroyed, a mistaken archive is repaired by moving the file or directory back by hand; there is no unarchive action.

### Batching

One invocation may carry several items, applied in order.
The first refusal stops the run and the output names the items left unprocessed, so a partial run is always
reported as partial.

## Output & Scripting

Every command takes `--json`, and each verb answers with an object shaped for its own question rather than one uniform envelope.
Field names are provisional for v1: the shape is stated so scripts can be written against it, and may be renamed once the surface has been used.

An item appears in the same shape everywhere:
```json
{
  "id": "task:fix-parser",
  "kind": "task",
  "status": "CLAIMED",
  "groups": ["claimed"],
  "created": "2026-10-05",
  "depends-on": ["task:deep-modules"],
  "dir": "/",
  "subpath": "TASK-fix-parser.md"
}
```

`status` is the raw leftmost tag, `null` when the artefact carries none, and `groups` is always a list because a brief matches two groups at once.
`dir` is the directory holding the item, anchored at the project root: `/` for one at the root, `/tasks` for a directory below it.
`subpath` is what sits below `dir` — the filename for a task, the spec directory and its carrier for a spec — so `dir` plus `/` plus `subpath` is the full location and neither field repeats the other.
They are not halves of a naive split: a spec's `dir` is the parent of its spec directory, while the spec directory itself sits inside `subpath`.
The directory heading labels `Current dir` and `Project root` are presentation for `dir`, so they never reach a script.
A spec additionally carries `parts`; a brief carries no `created`, and any item carries `depends-on` only when the file names one.

### `ls --json`

```json
{ "items": [] }
```

The list is the whole answer: `ls` hides nothing, so no closing facts travel beside it.
Each item carries its `dir` and `subpath`, so a client can sort or regroup the table without re-deriving paths.

### `status --json`

The grouped answer nests in the order it prints, one shape per axis, and adds the facts its human closing line reports.

By directory, the default:
```json
{
  "dirs": [
    {
      "dir": "/",
      "statuses": [
        { "status": "ready", "items": [] },
        { "status": "claimed", "items": [] },
        { "status": "draft", "items": [] }
      ]
    },
    { "dir": "/tooling", "statuses": [ { "status": "claimed", "items": [] } ] }
  ],
  "hidden": {
    "project": { "done": 3, "abandoned": 2 },
    "archived": { "done": 1, "abandoned": 4 }
  },
  "elsewhere": [ { "status": "ready", "count": 2 }, { "status": "draft", "count": 5 } ]
}
```

`--by-status` swaps the two levels and nothing else:
```json
{
  "statuses": [
    { "status": "ready", "dirs": [ { "dir": "/", "items": [] } ] },
    { "status": "claimed", "dirs": [ { "dir": "/", "items": [] }, { "dir": "/tooling", "items": [] } ] },
    { "status": "draft", "dirs": [ { "dir": "/", "items": [] } ] }
  ],
  "hidden": {
    "project": { "done": 3, "abandoned": 2 },
    "archived": { "done": 1, "abandoned": 4 }
  },
  "elsewhere": [ { "status": "ready", "count": 2 }, { "status": "draft", "count": 5 } ]
}
```

Both nesting arrays keep the printed order, and a group with no items is not emitted.

`hidden` is the closing line's second and third segments in structured form: `project` counts the terminal items the selection left in the project, `archived` counts the same under `.ARCHIVED/`, and each half keeps `done` and `abandoned` apart.

`elsewhere` is the first segment: the out-of-scope counts as `status` and `count` pairs, in section order, omitting groups with nothing there, and empty when the scope already covers the project.
It exists because a script running in a subdirectory otherwise has no way to know that the project holds more work than the answer shows.

`ls --json` carries neither key: it lists every item in scope, so there is no hidden state to report, and the archive it excludes is a destination the caller asks for rather than a count to chase.

### `show --json`

One item object, with no wrapper.

### `do --json`

```json
{
  "results": [
    {
      "id": "task:fix-parser",
      "action": "claim",
      "outcome": "applied",
      "from": null,
      "to": "CLAIMED"
    },
    {
      "id": "task:other",
      "action": "claim",
      "outcome": "refused",
      "from": "DONE",
      "reason": "already done"
    },
    {
      "id": "task:rest",
      "action": "claim",
      "outcome": "unprocessed"
    }
  ]
}
```

`archive` adds the destination as the same `dir` and `subpath` pair an item carries, and `undo` and `reset` report the tag they uncovered as `to`.
The array length always matches the number of ids given, so a caller pairs inputs and results by position and never has to infer where a run stopped.

### Errors

An error is an object with a non-zero exit, whatever the verb:
```json
{ "error": { "kind": "ambiguous", "id": "task:fix-parser", "message": "two items share this name" } }
```

`kind` is one of `unknown-id`, `not-found`, `ambiguous`, `duplicate-slug`, `invalid-filter`, `invalid-argument`, or `refused`.
`ambiguous` covers one argument readable both as a path and as a different item's id; `duplicate-slug` covers two items of one kind sharing a slug, and its message lists both paths.
A caller reads the exit code for success and the object for the reason, and no verb mixes an error object into `items` or `results`.

## Placement / Scope

`wkf` manages one project: the tree rooted at the nearest git root above the current directory.
Invoking it from any depth inside that tree finds the same root, and every path it prints is anchored at that root.
A second project means a second invocation, not a wider walk.

### Listing scope

A listing starts where the caller stands: `status` and `ls` show the invocation directory and everything below it.
Bare `wkf status` in a subdirectory answers "what is here", which is the question a caller standing there is asking, and the `elsewhere` segment says how much sits elsewhere so the narrower answer is never mistaken for the whole project.

`--all` widens the listing to the project root, and is the only way to see the rest of the tree without changing directory.
It changes scope alone: the walk, the ids, and the filters are the same either way.

Addressing is project-wide in every case.
An id resolves against the whole project, and `show` and `do` accept an id or a path from any directory, so `wkf do claim task:fix-parser` works from a nested directory the listing would not have shown.
Scope belongs to the listing question, not to the item space: an item does not stop existing because the caller stands somewhere else.

The walk is a recursive descent from that root, and it defines the item set: an artefact the walk does not reach does not exist as far as `wkf` is concerned.
It is independent of the current directory, which keeps the item set — and with it slug uniqueness — identical for everyone in the project.

It skips `.git/`, every directory whose name begins with a dot, and every path git reports as ignored.
`.ARCHIVED/` is the single dot-directory the walk enters, because archived items are still items — the closing line counts them rather than listing them, and `--filter archived` has to find them.
The exemption is by name at the location archiving writes to, not a licence to descend into any dotted directory that happens to exist.

A nested repository is a boundary: a directory holding its own `.git` belongs to another project, so the walk does not enter it.
A child devtree is reached by invoking `wkf` there, which keeps one run to one project and keeps every printed path unprefixed; descending would need a prefix rule in every id and path, and would let two trees disagree about what a duplicate slug means.
Symlinks are not followed, which keeps a link cycle from turning a listing into a hang.
There is no depth limit, and the walk is as deep as the project.

No git root above the current directory means no project, and `wkf` refuses with a message saying so.
Guessing a root from the current directory would drop the ignore rules the walk relies on, and silently widen a walk that the user never asked for.

An artefact becomes an item only when its name is one of the recognised forms: `TASK-<slug>.md`, `HANDOFF-<slug>.md`, `IDEA-<slug>.md`, `BUG-<slug>.md`, each also matching with a legacy date segment before the slug, or a standalone `EXPLO-<slug>.md` anywhere under the walk; a spec directory named `SPEC-DRAFT-<slug>/`, `SPEC-READY-<slug>/`, `SPEC-KO-<slug>/`, or legacy `_SPECS/<slug>/`.
Everything else the walk passes is content: notes, READMEs, and the files inside a spec directory that are not its carrier.

Arguments resolve by probing the filesystem, never by syntax — the algorithm is in Naming & IDs.
A path counts only when it lands inside the walk, and a path naming a spec's `DISCOVERY.md`, its `SPEC.md`, or the spec directory itself resolves to the spec item, because the carrier is a part rather than an item of its own.

Slug uniqueness spans the whole project, and the walk is what makes a violation visible: two items of one kind that reduce to the same name in different directories are a duplicate, reported with every colliding path whenever an answer would depend on naming them.
`wkf` resolves nothing around it — no shortened, qualified, or directory-scoped id exists — so the repair is a rename of the file or directory, done by hand.
Within one directory the case cannot arise, because the filesystem already forbids two identical filenames.

Location and state stay separate on purpose: an item moves between spec directory prefixes as `manage-spec` changes its tag, and `wkf` follows it by re-reading the walk rather than by remembering a path.
The walk is therefore stateless — nothing is cached between invocations, and a file moved by hand is picked up on the next run at its new place.

## Alternatives & Tradeoffs

Two alternatives were weighed and lost.

Folding the file surface into the beads frontend as one `wk` command with a file mode would give one grammar and one help text, but it would force a bead-shaped vocabulary onto artefacts whose status is a heading tag, and a file rule could then reach into the passthrough.
One listing verb with filters, instead of `status` and `ls`, would shrink the surface to a single command, but it cannot keep "what is here" and "what did I do here" apart without turning them into options on a verb whose name promises neither.

The design keeps a separate command, two listing verbs, and headings as the only status carrier.

## Related artifacts

This spec was drafted inside the harness repo (`devtree-harness`), and the entries prefixed with it still live there; everything else is named relative to wherever this spec is read.

`devtree-harness:SPEC-READY-wk-beads-wrappers/SPEC.md` — the beads frontend the file surface ships beside, defining the `wk`/`wkg`/`wkt` trio and the rule that `bd` is never typed directly; it fixes the surface `wkf` deliberately does not extend.

`devtree-harness:SPEC-READY-task-scopes/SPEC.md` — the `:scope` grammar the beads side uses to disambiguate a routed id, which is the counterpart of `wkf`'s typed `[kind]:[name]` id and its repo-wide uniqueness rule.

`devtree-harness:SPEC-READY-cross-devtree-task-routing/SPEC.md` — how the beads frontend reaches work outside the current devtree, which is exactly the reach `wkf` leaves out of scope in favour of one project per run.

`devtree-harness:SPEC-READY-devtree-daemons/SPEC.md` — the `<devtree>/.state/` convention for machine state, worth knowing because `wkf` keeps no state at all and files archived work under `.ARCHIVED/` inside the project rather than out of tree.

`devtree-harness:SPEC-DRAFT-beads-out-of-tree-storage/SPEC.md` — the pattern of storing beads workspaces outside the project repo, the alternative `wkf` does not need, since its store is the markdown files already committed to the project.

`~/.config/opencode/skills/write-spec/scripts/manage-spec` and its `refs/lifecycle.md` — the owner of spec lifecycle, defining the six states, the draft/ready/retired directory prefixes, and the refusal of a `[CLAIMED]` or `[DONE]` marker that `reset` exists to lift.
