# surface-shape — exploration

The shape of the command surface: which verbs exist, what they take, what they print, and how an item
is addressed. Status semantics are settled in `status-model`; this topic is about the ergonomics built
on top of them.

coupled-with: `topic:json-output`

## Findings

- Query filtering now has two spellings available at once: a status verb (`wk file ready`) and a flag on
  a general list verb (`wk file ls --status ready`).
  Keeping both means two code paths and two vocabularies to document.
- The four verbs are groups, so the verb form cannot express an ungrouped state such as `abandoned`.
  Some general filter must exist regardless.
- Items come in three id shapes already: a filename stem (`TASK-fix-parser`), a slug (specs), and a
  qualified pair for standalone exploration files.
  Stems are long, so an exact-match-only id is tedious to type but immune to ambiguity.
- The motivating questions are "what is ready" and "what is done", asked with no flags at all.
- A path is what a caller usually needs next, both for `show` and for scripting.
- The repo already answers "where do I put machine-readable output" with `--json` on the `devtree` CLI.
- A status-grouped listing puts folder layout out of reach: which folder an item sits in is reachable
  only through `show` or the item's `dir` and `subpath` fields, never from the listing read first.
- Folder layout is project convention, not a fixed taxonomy: tasks and handoffs sit at root or under a
  `tasks/`-style folder, a spec item owns a whole directory, a standalone brief sits where it was
  drafted. The folder set is discovered, never enumerated.
- Status grouping is load-bearing in two places: the human rendering's headed sections and the
  `--filter` grouping model. Every listing shares one item object, and `json-output` is frozen, so a
  default change reaches into it or deliberately stops short.
- Every table already carries a real status column, so a folder-grouped rendering loses no state
  information — only the headings change meaning.
- `ls` is the one verb whose name promises a flat directory listing, yet it was the verb that grouped;
  grouping sat behind a name that says nothing about grouping. `git status` versus `git ls-files` is the
  precedent: the grouped human view and the flat listing are separate verbs, and the flat one is the one
  scripts and `grep`-style habits expect.
- The walk is project-wide and cwd-independent: "invoking it from any depth inside that tree finds the
  same root". Scoping a listing to the cwd subtree is a filter over the same discovered items, so it is
  cheap — but it retires that invariant for listings, and the id portability rule ("an id means the same
  item from any directory") has to be decided separately so `do` and `show` keep working from a
  subdirectory.

## Design crux

Two ways to express the same filter — a verb per group and a flag on a listing — either both exist, and the
surface has to justify the redundancy, or one is removed and the ungrouped tail needs its own home.
Everything else here (columns, sorting, id syntax) follows from that choice.
The answer keeps both, with the verbs as sugar over the grouped view, so the real question becomes which
verb owns the grouping.

## Candidate directions

None open.

## Decisions

### (settled) `filter-replaces-status` — `--filter` replaces `--status`

related-to: `filter-replaces-base` & `query-vocabulary`

It takes a comma-separated list, and output is presented in groups of statuses rather than one flat list.

### (settled) `ls-shows-everything-in-scope` — A bare `wkf ls` shows every item in scope

related-to: `listing-scope-cwd` & `archived-is-a-location`

In scope means the invocation directory and below, or the project with `--all`.
Ungrouped tails are included; only the archived items under `.ARCHIVED/` are missing, and those are
reached by an explicit `archived` token.

### (settled) `typed-ids` — Ids are typed everywhere

`task:<name>`, `handoff:<name>`, `idea:<name>`, `bug:<name>`, `spec:<slug>`, `spec:<slug>:explo`, and
`explo:<slug>` for a brief that lives outside any spec directory.
The grammar is `<kind>:<name>[:<part>]`, which makes cross-family collisions structurally impossible.

### (settled) `id-name-drops-prefix-and-date` — The name part drops the filename prefix and the date token

related-to: `typed-ids`

A task file `TASK-foo.md` has the id `task:foo`, and so does the legacy `TASK-20261001T1110-foo.md`.
The kind token carries the type, and the date is metadata about the file rather than identity.
The date segment is optional in a name, because the timestamp lives in the file's frontmatter; when
both are present the block wins.

### (settled) `slug-uniqueness` — Slug uniqueness is a corpus invariant

related-to: `typed-ids` & `duplicate-slug-is-error`

Within one kind, no two items share a slug anywhere in the project, so an id needs no directory part and
means the same thing from any directory.
`wkf` cannot enforce the invariant at the source — it never creates files — so a duplicate is reported
as an error naming both paths and repaired by a rename by hand.
No qualified `[kind]:[dir]/[slug]` form exists.

### (settled) `brief-id-in-spec-space` — A brief inside a spec directory belongs to the spec id space

related-to: `typed-ids` & `brief-suppresses-topics`

It is `spec:<slug>:explo`, while a standalone brief uses the `explo:` kind, so the same artefact is
addressed consistently with where it lives.

### (settled) `filter-replaces-base` — `--filter` replaces the base selection of the verb it is given to

related-to: `filter-replaces-status` & `ls-positional-token`

A `+` prefix adds to that base instead.
`status` starts from the live groups — `draft`, `ready`, `claimed` — while `ls` starts from every
non-archived item, so a bare `ls` shows finished and retired work too.
On `ls`, `+` is meaningful for `archived` alone, every other token being already included.

### (settled) `grouped-sections-keep-status-column` — Headings and the status column both name the group

related-to: `two-grouping-axes`

A section heading names the group, and every row still carries the raw `STATUS` tag, so the heading
says what the rows have in common while the table says which tag put each row there.

### (settled) `show-is-a-router` — `show` is a router, never a reader

It prints id, kind, raw status, derived groups, and the joined location
(`/tooling/SPEC-DRAFT-wk-files/SPEC.md`), plus the parts present for a spec (`discovery`, `spec`,
`explo`).
Artefact content is never printed, so the tool owes no truncation policy and never reflows markdown it
did not author.
The field is plural because a brief matches two groups at once, and the status is absent for a file
that carries no tag, so neither can be a single mandatory word.

### (settled) `ls-has-no-path-flag` — `ls` has no `--path` flag

Paths belong to `show`, so `ls` keeps a single rendering and the "where is it" question has exactly one
answer.

### (settled) `separate-wkf-binary` — File-backed management ships as a separate binary, `wkf`

The tool is called `wk-files`.
`wk` stays a pure beads passthrough, so its "`init` is the single deliberate exception" rule survives
untouched and no local namespace has to be checked against future `bd` subcommands.

### (settled) `mutations-under-do` — Every mutation lives under `wkf do <action>`

related-to: `status-verbs-are-queries`

`wkf do claim`, `wkf do finish`, `wkf do abandon`, `wkf do undo`, `wkf do reset`, `wkf do archive`.
Queries stay top-level, so the grammar itself says whether a command can write, and a future mutation
joins the action set without changing the top-level surface.

### (settled) `path-wherever-id` — Every verb accepts a filesystem path wherever it accepts an id

coupled-with: `resolution-probes-filesystem`

The input forms are interchangeable, so a path just seen in a listing can be passed straight to `show`
or an action verb.

### (settled) `resolution-probes-filesystem` — Resolution probes the filesystem rather than parsing the syntax

related-to: `path-inside-walk`
coupled-with: `path-wherever-id`

An existing path inside the walk is the item; otherwise the argument is matched as an id; an argument
that is neither is refused as unknown.
Ids and paths share no marker a parser could trust, so the lookup decides instead.

### (settled) `path-inside-walk` — A path must resolve inside the walk

coupled-with: `walk-rules`

The walk defines the item set, so a path outside it is not an item the tool knows and is refused.

### (settled) `filter-and-type-compose` — Both listing verbs carry `--filter` and `--type`

coupled-with: `elsewhere-follows-selection`

`--type spec --filter ready` answers "specs awaiting work", which neither axis can express alone.

### (settled) `two-grouping-axes` — Listings group on two axes, and a flag picks the outer one

related-to: `status-vs-ls-split` & `group-order`

`--by-dir` is the default: directory headings, status sections inside.
`--by-status` flips it: status headings, directory sections inside.
The flags are alternatives, not composable, and the inner axis is always the other one.
Both levels always print, so a section holding a single group is never collapsed.
Each heading names its axis — `Dir: <label>` for a directory section, `Status: <group>` for a status
section — on both levels and both axes, so the two views never differ in shape.
A section's body sits one rail deeper than its heading: an outer heading starts at the margin, the
inner headings under it start with `│ `, and the tables under those start with `│ │ `.
Two inner sections are separated by a `├───` junction line, whose length reaches the body depth of
the section that follows.
Depth is counted in pipes rather than in spaces: indentation can be read as misalignment, while a
second bar cannot.
Outer sections are separated by a plain blank line, and the output opens and closes with one.

#### Example

Invoked from `tooling/`, the default view reads roughly:

```console
$ wkf status

Dir: Current dir
│ Status: ready
│ │ ID                               STATUS  CREATED
│ │ spec:cross-devtree-task-routing  READY   2026-10-14
├───
│ Status: draft
│ │ ID                STATUS  CREATED
│ │ task:draft-notes  -       2026-09-30

Dir: ./tooling/tasks
│ Status: claimed
│ │ ID                       STATUS   CREATED
│ │ task:extract-cli-common  CLAIMED  2026-10-01

elsewhere: 2 ready, 1 draft · not archived: 3 done · archived: 1 done, 4 abandoned

```

### (settled) `group-order` — Group order is `ready`, `claimed`, `draft`

related-to: `two-grouping-axes`

Actionable first, in-flight second, unstarted last.
`done` and `abandoned` sit after `draft` when the filter surfaces them, and the order decides the row
sequence inside any section whose heading is not the status.

### (settled) `dir-section-is-immediate-parent` — A directory section is the item's parent

related-to: `spec-groups-under-parent`

`tasks/2026/TASK-x.md` groups under `tasks/2026`; no roll-up to a top-level segment and no single-child
chain merging.

### (settled) `spec-groups-under-parent` — A spec item groups under the parent of its spec directory

related-to: `dir-section-is-immediate-parent`

`tooling/SPEC-READY-wk-files/SPEC.md` is one row under `tooling/`, because the carrier lives inside the
spec dir rather than in the parent.

### (settled) `status-vs-ls-split` — `status` owns the grouped view, `ls` is the flat table

related-to: `two-grouping-axes` & `flat-table-order`

`wkf status` renders the two-axis grouped view and owns `--by-dir` (default) and `--by-status`;
`wkf ls` prints one row per item with no headings and takes no axis flag.

### (settled) `status-verbs-are-queries` — The status verbs list, they never mark

related-to: `group-verbs-are-sugar`

`wkf ready` lists; it does not mark anything.
That removes the read/write ambiguity that otherwise makes a forgotten id harmless and a typo dangerous.

### (settled) `group-verbs-are-sugar` — The status verbs are sugar for `status`

related-to: `status-verbs-are-queries` & `status-vs-ls-split`

`wkf ready` is `wkf status --filter ready`: the short spelling exists for the questions actually asked,
the selected group belongs in the grouped view, and both forms share one lookup.

### (settled) `ls-has-no-hidden-footer` — A flat `ls` prints no closing line

related-to: `closing-line`

It lists every item in scope apart from the archive, so a count would restate rows already on screen, and
the closer belongs to the grouped view alone.

### (settled) `ls-positional-token` — `ls` takes an optional positional status token

related-to: `filter-replaces-base`

`wkf ls ready` is another spelling of `--filter ready`; the token set and the lookup are the same as the
group verbs.

### (settled) `flat-table-order` — The flat table is ordered by status, then directory, then `created-at`, then name

related-to: `status-vs-ls-split` & `frontmatter-carries-time-not-status`

With no headings left, the order is the only grouping the flat rendering can express, and it keeps
actionable rows on top.
Newest first inside a directory, and an item with no timestamp sorts last rather than dropping out.

### (settled) `structured-listings-envelope` — The structured form of both listings lives in `json-output`

related-to: `listing-envelopes-split-by-verb` & `item-object` & `topic:json-output`

The nesting mirrors the headings, and the flat table emits its rows with no closing line to model.

### (settled) `listing-scope-cwd` — Listings start at the invocation directory

related-to: `addressing-is-project-wide`

The two verbs answer "what is here", so they share the reach; the whole-project inventory stays one flag
away.

### (settled) `addressing-is-project-wide` — Ids, `show`, and `do` stay project-wide

related-to: `listing-scope-cwd`

Scope is a listing concern only, so the rule that an id means the same item from any directory survives,
and `wkf do claim task:x` works from anywhere.

### (settled) `closing-line` — A listing closes with one line of three labelled segments, in fixed order

related-to: `ls-has-no-hidden-footer` & `archived-is-a-location`
coupled-with: `listing-envelopes-split-by-verb`

`elsewhere: 2 ready, 5 draft · not archived: 1 done, 2 abandoned · archived: 1 done, 4 abandoned`.
`elsewhere` counts the selected groups outside the scope, in group order, zero counts omitted, naming no
direction so narrowing or widening the scope never makes the word lie, and never counting archived
items.
`not archived` counts terminal work still sitting in the project, `archived` the same groups under
`.ARCHIVED/`, so a terminal item still in the project and a filed one never blur.
A segment drops out when it is empty, and the line disappears when all three are.
`status` prints the line; the flat `ls` prints none, so no count ever restates a row already visible.

### (settled) `elsewhere-follows-selection` — The `elsewhere` counts follow the same selection as the table

related-to: `closing-line`
coupled-with: `filter-and-type-compose`

`--filter` and `--type` narrow them alike, so the closing line never disagrees with the rows above it.

### (settled) `directory-headings` — Directory headings read `Dir: Current dir`, `Dir: Project root`, or `Dir: ./<path>`

related-to: `two-grouping-axes`
coupled-with: `dir-root-anchored`

Every directory heading carries the `Dir: ` prefix that names its axis, so the two axes never share a
heading shape.
`Current dir` names the invocation directory, `Project root` the root (whether the cwd is there or
`--all` reached it), and `./<path>` everything else.
The leading `./` marks a path relative to the root, the same path the JSON `dir` field anchors with a
leading `/`.
Run from the project root the first heading reads `Dir: Project root`, and `--all` reaches items outside
the current directory, which the closing line otherwise only counts.

## Rejected directions

- **A verb per status group over a catch-all `ls`** — the verbs survived, but as sugar over
  `status` rather than over `ls`.
- **Verbs only, no filter flag** — the verb table grows with every state a future tool
  invents.
- **One verb plus a filter flag, no status verbs** — loses the short spelling for the two
  questions actually asked.
- **Status verbs alone, long tail unreachable** — hides abandoned work from a tool whose
  purpose is finding things.

## Open threads

None open.
