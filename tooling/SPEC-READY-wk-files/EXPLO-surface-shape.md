# surface-shape — exploration

The shape of the command surface: which verbs exist, what they take, what they print, and how an item
is addressed. Status semantics are settled in `status-model`; this topic is about the ergonomics built
on top of them.

## Findings

- Query filtering now has two spellings available at once: a status verb (`wk file ready`) and a flag on
  a general list verb (`wk file ls --status ready`).
  Keeping both means two code paths and two vocabularies to document.
- The four verbs are groups, so the verb form cannot express an ungrouped state such as `abandoned`.
  Some general filter must exist regardless.
- Items come in three id shapes already: a filename stem (`TASK-20261001T1110-…`), a slug (specs), and a
  qualified pair for standalone exploration files.
  Stems are long, so an exact-match-only id is tedious to type but immune to ambiguity.
- The motivating questions are "what is ready" and "what is done", asked with no flags at all.
- A path is what a caller usually needs next, both for `show` and for scripting.
- The repo already answers "where do I put machine-readable output" with `--json` on the `devtree` CLI.

## Design crux

Two ways to express the same filter — a verb per group and a flag on `ls` — either both exist, and the
surface has to justify the redundancy, or one is removed and the ungrouped tail needs its own home.
Everything else here (columns, sorting, id syntax) follows from that choice.

## Candidate directions

- (active) **Verbs for groups, `ls` for everything.** The four verbs are the common queries with no flags;
  `ls` prints every item and takes `--type` plus `--status` for the long tail.
  Redundant on purpose: the verb is the shortcut, the flag is the escape hatch.
- (active) **Verbs only, `ls` minimal.** Drop `--status` entirely. `ls` takes `--type` only, and ungrouped
  states become their own verbs (`wk file abandoned`). Uniform grammar, but the verb table grows with
  every state a future tool invents.
- (active) **One verb and flags only.** `wk file ls --status ready`, no status verbs. Smallest surface and
  trivially extensible; loses the short spelling for the two questions that are actually asked.
- (deferred) **Status verbs as the only surface**, with the long tail intentionally unreachable.
  Simplest to explain, but hides `abandoned` specs from a tool whose purpose is finding things.

## Decisions

- (settled) **`--filter` replaces `--status`.** It takes a comma-separated list, and output is presented in
  groups of statuses rather than one flat list.
- (settled) **A bare `wkf ls` shows everything in the project**, ungrouped tails included, except the
  archived items under `.ARCHIVED/`, which a footer counts rather than lists.
- (settled) **The group verbs survive as sugar.** `wkf ready` is `wkf ls --filter ready`; the short
  spelling exists for the questions actually asked, and both are backed by one lookup.
- (settled) **Ids are typed everywhere**: `task:<name>`, `handoff:<name>`, `spec:<slug>`,
  `spec:<slug>:explo`, and `explo:<slug>` for a brief that lives outside any spec directory.
  The grammar is `<kind>:<name>[:<part>]`, which makes cross-family collisions structurally impossible.
- (settled) **The name part drops the filename prefix and the date token.** A task file
  `TASK-20261001T1110-foo.md` has the id `task:foo`; the kind token carries the type, and the date is
  metadata about the file rather than identity.
- (settled) **Slug uniqueness is a corpus invariant.** Within one kind, no two items share a slug
  anywhere in the project, so an id needs no directory part and means the same thing from any
  directory. `wkf` cannot enforce the invariant at the source — it never creates files — so a duplicate
  is reported as an error naming both paths and repaired by a rename by hand. No qualified
  `[kind]:[dir]/[slug]` form exists.
- (settled) **A brief inside a spec directory belongs to the spec id space**, as `spec:<slug>:explo`, while
  a standalone brief uses the `explo:` kind. The same artefact is therefore addressed consistently with
  where it lives.
- (settled) **`--filter` replaces the default set unless a token is prefixed with `+`.** Bare `ls` shows
  `draft`, `ready`, and `claimed`; `--filter done` shows only finished work; `--filter +done` adds it to the
  default set.
- (settled) **The tokens are `draft`, `ready`, `claimed`, `done`, `abandoned`, `archived`.** The last is a
  location filter for `.ARCHIVED/`, not a status group; `implemented` is not a token, because the lifecycle no
  longer has that state; `started` is accepted as an alias for `claimed`.
- (settled) **The footer separates filed from unfiled terminal work**: the `done` and `abandoned` items still in
  the project but not yet archived, then the same two categories under `.ARCHIVED/`, so one line says both
  whether anything was left out and what archiving is still outstanding.
- (settled) **Grouped output is headed sections with a table under each**, and the table still carries the
  real status column, so a row shows both its group and the exact state it came from.
- (superseded) **There is no `--json` flag.** Reversed in `json-output`: the flag exists on every
  subcommand, with a per-verb envelope.

- (settled) **`show` is a router, never a reader.** It prints id, kind, raw status, derived groups, and path,
  plus the parts present for a spec (`discovery`, `spec`, `explo`). Artefact content is never printed, so the
  tool owes no truncation policy and never reflows markdown it did not author.
  The field is plural because a brief matches two groups at once, and the status is absent for a file that
  carries no tag, so neither can be a single mandatory word.
- (settled) **`ls` has no `--path` flag.** Paths belong to `show`, so `ls` keeps a single rendering and the
  "where is it" question has exactly one answer.
- (settled) **File-backed management ships as a separate binary, `wkf`.** The tool is called `wk-files`.
  `wk` stays a pure beads passthrough, so its "`init` is the single deliberate exception" rule survives
  untouched and no local namespace has to be checked against future `bd` subcommands.
- (settled) **Every mutation lives under `wkf do <action>`**, permanently: `wkf do claim`, `wkf do finish`,
  `wkf do abandon`, `wkf do undo`, `wkf do reset`, `wkf do archive`. Queries stay top-level, so the grammar
  itself says whether a command can write, and a future mutation joins the action set without changing the
  top-level surface.
- (settled) **Every verb accepts a filesystem path wherever it accepts an id.** The input forms are
  interchangeable, so a path just seen in a listing can be passed straight to `show` or an action verb.
- (superseded) **Syntax decides between an id and a path.** Reversed while writing the spec: an id is
  `kind:`-prefixed while a path contains slashes, but neither carries a marker a parser can trust, so
  resolution now probes the filesystem — an existing file is a path, a matching discovered item is an id.
- (settled) **A path must resolve inside the walk.** The walk defines the item set, so a path outside it is
  not an item the tool knows and is refused.

- (settled) **`ls` carries both a `--filter` and a `--type`**, and the two compose: `--type spec --filter ready`
  answers "specs awaiting work", which neither axis can express alone.
