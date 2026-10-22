# json-output — exploration

Machine-readable output for every subcommand: which verb emits what, how hidden state is represented, and
what a script can rely on without parsing a table.

## Findings

- An earlier round settled that `--json` would not exist at all, on the grounds that scripting should wait
  for a surface designed for it. That decision is reversed by the user's request for `--json` on every
  subcommand, which makes the output shape part of the design rather than an afterthought.
- Three verbs produce three different shapes of answer: `ls` produces a collection plus a hidden count,
  `show` produces one item, and `do` produces one outcome per id it was given.
- The human rendering already commits to headed sections and a footer that states what is hidden. A JSON
  rendering has to keep that information, or the two renderings disagree about the corpus.
- The existing `devtree` CLI in this repo answers the same question with `--json`, so the flag name and the
  general expectation are already established in the project.
- A path is available on every item as data, even though `ls` never prints it. That gives JSON a natural
  place for the field that the table refuses to show.

## Design crux

JSON forces every verb to name its answer explicitly. A table can hide the difference between "no items" and
"items hidden by the archive rule"; a structured answer cannot, so the hidden state has to be modelled
rather than implied by a footer line.

## Candidate directions

- (active) **Object envelope per verb.** `ls` emits items plus hidden counts, `show` emits one object, `do`
  emits one result per id. Each shape states only what that verb knows.
- (active) **Bare arrays.** Collections everywhere, with hidden counts dropped or smuggled in as a pseudo
  item. Easiest to pipe, but loses the footer fact and makes `show` and `do` inconsistent with `ls`.
- (active) **One uniform envelope.** Every verb emits items, hidden, and errors, even when two of the three
  are empty. One shape to parse, at the cost of noise on `show`.

## Decisions

- (settled) **`--json` exists on every subcommand.** The flag is uniform, so a script learns it once.
- (settled) **Each verb emits an object envelope describing its own answer**, not a bare array and not one
  uniform shape. `ls` carries its items and its hidden counts, `show` a single item, and `do` a result per
  id, so no verb reports a field it has no answer for.

- (settled) **Errors are JSON too**, printed as an object naming the id and the reason, alongside a non-zero
  exit. One reader handles both outcomes and the exit code stays the only success signal.
- (settled) **Field names are provisional for v1.** The spec states the shape without promising stability, so
  the surface can still be renamed once it is in use.
- (settled) **`do --json` reports a result per input id**, in input order: applied ids carry their old and new
  status, refused ids carry the reason, and ids after a halt are marked unprocessed. The array length always
  matches the number of ids given.
- (settled) **Item fields are `id`, `kind`, `status`, `groups`, and `path`**, plus `date` on a dated artefact and
  `parts` on a spec. `status` is the raw leftmost tag and is null when the file carries none (a handoff, a
  standalone brief), and `groups` is a list because a brief matches two groups at once — the pair keeps the
  output honest instead of collapsing either fact.
- (settled) **`ls --json` emits `items` plus `hidden`**, and `hidden` splits `project` from `archived`, each
  carrying `done` and `abandoned` counts. That is the human footer's distinction in structured form, so a script
  can see that terminal work is still unfiled.
- (settled) **`do --json` names the action alongside the outcome.** A result carries `id`, `action`, `outcome`
  (`applied`, `refused`, `unprocessed`), `from`, `to`, and the destination `path` for `archive`; the action names
  follow the renamed verbs (`claim`, `finish`, `abandon`, `undo`, `reset`, `archive`).

## Open threads

None open.
