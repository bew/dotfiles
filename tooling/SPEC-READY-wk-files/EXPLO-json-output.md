# json-output — exploration

Machine-readable output for every subcommand: which verb emits what, how hidden state is represented, and
what a script can rely on without parsing a table.

coupled-with: `topic:surface-shape`

## Findings

- An earlier round settled that `--json` would not exist at all, on the grounds that scripting should wait
  for a surface designed for it. That decision is reversed by the user's request for `--json` on every
  subcommand, which makes the output shape part of the design rather than an afterthought.
- Three verbs produce three different shapes of answer: `ls` produces a flat collection, `status` a nested one
  carrying the closing facts, `show` one item, and `do` one outcome per id it was given.
- The grouped human rendering commits to headed sections and a closing line that states what sits outside
  the listing. A JSON rendering has to keep that information, or the two renderings disagree about the
  corpus.
- The existing `devtree` CLI in this repo answers the same question with `--json`, so the flag name and the
  general expectation are already established in the project.
- A location is available on every item as data, even though the tables print only its directory. That gives
  JSON a natural place for the field the table refuses to show.

## Design crux

JSON forces every verb to name its answer explicitly. A table can hide the difference between "no items" and
"items hidden by the archive rule"; a structured answer cannot, so the hidden state has to be modelled
rather than implied by a footer line.

## Candidate directions

None open.

## Decisions

### (settled) `json-on-every-verb` — `--json` exists on every subcommand

The flag is uniform, so a script learns it once.

### (settled) `per-verb-envelope` — Each verb emits an object envelope describing its own answer

related-to: `json-on-every-verb` & `listing-envelopes-split-by-verb`

Not a bare array and not one uniform shape.
`ls` carries its items, `show` a single item, `status` its nesting with the closing facts, and `do` a
result per id, so no verb reports a field it has no answer for.

### (settled) `errors-as-json` — Errors are JSON too

Printed as an object naming the id and the reason, alongside a non-zero exit.
One reader handles both outcomes and the exit code stays the only success signal.

### (settled) `provisional-field-names` — Field names are provisional for v1

The spec states the shape without promising stability, so the surface can still be renamed once it is in
use.

### (settled) `do-result-per-id` — `do --json` reports a result per input id

related-to: `do-result-names-action`

In input order: applied ids carry their old and new status, refused ids carry the reason, and ids after a
halt are marked unprocessed.
The array length always matches the number of ids given.

### (settled) `item-object` — The item object is one shape, shared by every verb that prints an item

related-to: `dir-root-anchored` & `listing-envelopes-split-by-verb` & `topic:status-model`

`id`, `kind`, `status`, `groups`, `created`, `depends-on`, `dir`, and `subpath`, plus `parts` on a spec.
`created` is the calendar day from the file's `created-at`, and `depends-on` appears only when the
frontmatter names one.
The same object appears in `ls --json` `items`, inside the `status --json` nesting, and alone from
`show --json`.
`dir` is the root-anchored directory (`/tooling`, `/` at the root) and `subpath` is what sits below it
(`TASK-foo.md`, `SPEC-DRAFT-wk-files/SPEC.md`), so `dir` + `/` + `subpath` is the full location and no
field repeats it.
The split is also what lets a spec keep its own rule: its `dir` is the parent of the spec directory, while
the directory itself lives in `subpath` — a remainder that is sometimes a bare filename and sometimes a
directory plus one, which is why the field is not called a name.
`status` is still the raw leftmost tag and null when absent, and `groups` is still a list for a brief
matching two groups at once.

### (settled) `listing-envelopes-split-by-verb` — The listing envelopes split by verb

related-to: `per-verb-envelope` & `item-object`
coupled-with: `closing-line`

Each states what its verb knows.
`ls --json` carries `{items}`, each item with `dir`: a flat listing hides nothing but the archive, and the
archive is a destination the caller asks for, so the envelope carries no closing facts.
`status --json` nests `dir → status → items` (or `status → dir → items`) and adds `hidden` (`project` and
`archived`, each `done` + `abandoned`) and `elsewhere`, the per-status counts of selected items outside the
scope.
Closing facts stopped being human-only once the closing line became the only place where archived and
out-of-scope work is visible at all.

### (settled) `do-result-names-action` — `do --json` names the action alongside the outcome

related-to: `do-result-per-id`

A result carries `id`, `action`, `outcome` (`applied`, `refused`, `unprocessed`), `from`, `to`, and the
destination path for `archive`; the action names follow the verbs (`claim`, `finish`, `abandon`, `undo`,
`reset`, `archive`).

### (settled) `dir-root-anchored` — `dir` is a first-class item field anchored at the project root

related-to: `item-object`
coupled-with: `directory-headings`

It reads `/` for an item sitting at the root and `/tasks/2026` for one below it, so the same item carries
the same string from any directory and both verbs agree.
Headings are presentation instead.

## Rejected directions

- **Bare arrays** — drop the closing facts and make `show` and `do` inconsistent with the
  listings.
- **One uniform envelope** — items, hidden facts, and errors on every verb; trades noise on
  `show` for one shape to parse.

## Open threads

None open.
