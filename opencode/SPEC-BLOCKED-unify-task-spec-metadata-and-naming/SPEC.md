# [BLOCKED] Basic frontmatter for tasks and specs

> IMPORTANT: Before any drafting/planning/editing of this spec,
> agents MUST load one of the spec-writing skills first.

> **BLOCKER**: This spec depends on the `wkf` tool being available, working, and supporting this block format.
> Until that holds, the format is unvalidated and nothing below counts as settled.

## Introduction

The goal is one naming scheme shared by tasks and specs, where a name is an identity that survives status changes.
`TASK-<slug>.md` and `SPEC-<slug>/` are the only valid shapes, and state lives in the H1 tag rather than in the name.
A name therefore means the same thing to a human, a reference, and a tool, and it keeps meaning it for the whole life of the artefact.

Task and spec artefacts in this repo declare themselves through their names and their headings.
A task file is named `TASK-<timestamp>-<slug>.md` and carries its state as an H1 tag such as `[CLAIMED]`.
Those naming and tagging conventions are project-global and live in `AGENTS.md`.
A spec's identity is the slug in its directory name, and its state is the H1 tag that `manage-spec` owns, as documented in `refs/lifecycle.md` of the `write-spec` skill.
The directory name also carries a state prefix, so advancing a spec renames its directory and invalidates every path that pointed at it.

That encoding is human-first, and it reads well for a person scrolling a directory.
It is a poor carrier for facts a tool has to query.
The creation timestamp exists only as a filename token, so it is lost the moment the file is renamed.
The status tag is a visual marker rather than a value under a stable key.

Dependency relationships have no representation at all.
A task that cannot start until a spec is ready, or a spec that builds on another spec, says so in prose or says nothing.
No command can answer "what is blocked" or "what can I start now", and an agent picking up work reads every candidate file to find out.

This spec defines a minimal block, written as YAML-like frontmatter, for the two facts worth making machine-readable now: when an artefact was created, and what it depends on.
The block stays deliberately small.
It carries no status, type, title, or ownership, because each of those already has an authority in the filename, the H1 tag, or `manage-spec`, and a second authority drifts.

Scope is tasks and specs.
Handoffs and exploration files stay out until the format has proven itself on those two families.

The design is inspired by the `wkf` work in the `devtree-harness` repo, which addresses work items as `[kind]:[slug]` and records a single frontmatter format as a deferred direction.

## Naming & IDs

An artefact that adopts the block drops the date or datetime token from its name.
`TASK-20261022T0855-parse-frontmatter.md` becomes `TASK-parse-frontmatter.md`.

The kind prefix stays and is the whole prefix: `TASK-` for a task file, `SPEC-` for a spec directory.
Nothing else sits between that prefix and the slug, so `SPEC-DRAFT-` and `SPEC-READY-` are not valid.

The reason is single ownership.
A name is an identity, a timestamp is metadata, and the block makes the timestamp queryable.
Keeping both carriers means two values that can disagree with no way to tell which is right.

State prefixes leave for the same reason.
`SPEC-DRAFT-<slug>/` becomes `SPEC-<slug>/`, and the H1 tag carries state alone.
A directory that renames itself on every transition drags every reference, path, and open buffer along with it, and the name stops being usable as an address.

Dropping the token also makes the name and the reference the same string.
The slug is the bare name: the filename without its kind prefix and `.md` suffix, lowercase, hyphen-separated.
The address is `<kind>:<slug>`, which is exactly what a `depends-on` reference spells.

```
TASK-do-something-interesting.md → task:do-something-interesting
SPEC-task-scopes/                → spec:task-scopes
```

Specs carry no date, but their directory name does carry state, so adoption there drops the state prefix and adds the block.
A state-prefixed directory is valid only while unmigrated, on the same terms as a dated task name.
`DISCOVERY.md` and `SPEC.md` keep their names.

Handoffs and exploration files keep their dated names, because they do not carry the block in this version.

Adoption is one atomic step: insert the block and rename the file together.
A dated name is valid only while the artefact is unmigrated, and a block on a dated file is an error.
Migration is rolling, happening on each write rather than in one sweep, so the corpus converges instead of flipping in a single commit.

When two dated names collapse to the same slug, the earliest `created-at` keeps the bare slug and each later one takes a numeric suffix in `created-at` order: `fix-parser`, `fix-parser-2`, `fix-parser-3`.
A suffix assigned at adoption is permanent.

## Interface / How to use

### The block

The block is a YAML-like mapping fenced by `---` on a line of its own.
The opening fence is the first line of the file, the closing fence is the next line that is exactly `---`, and nothing precedes the opening fence.

```yaml
---
created-at: 20261022T0855
depends-on: spec:task-scopes
---
```

Two keys are defined: `created-at` and `depends-on`.
`created-at` is required; `depends-on` is omitted when there is nothing to depend on.
Writers emit `created-at` first and `depends-on` second; readers accept either order.

A key with no value is a malformed line, not an empty field.
There is no way to spell "no dependencies" other than leaving the key out.

### `created-at`

The value is a timestamp in the compact form `YYYYMMDDThhmm`: eight digits, a literal `T`, four digits.
It is 13 characters wide, local time, at minute precision, with no seconds and no timezone offset.

`20261022T0855` means 22 October 2026, 08:55 local time.

The shape is inherited from the timestamp token task filenames use today.
Adoption moves the value out of the name and into this field unchanged, so no timestamp is reinterpreted on the way.
Keeping the width fixed also lets the values sort lexicographically.

The field is the sole carrier of creation time once an artefact has the block.
The name no longer holds a date, so there is nothing to drift against (see Naming & IDs).

```md
---
created-at: 20261022T0855
depends-on: spec:task-scopes
---

# Write the frontmatter parser
```

### `depends-on`

The value is a sequence of references on a single line, separated by ` & `: one space, an ampersand, one space.
Each reference is `<kind>:<slug>`, and the only kinds are `task` and `spec`.
Anything else is invalid, whether unknown or a family this format does not cover yet.

```yaml
depends-on: spec:task-scopes & task:parse-frontmatter
```

- No commas, brackets, quotes, or line folding.
- A bare space is not a separator, so ` & ` is the only thing that splits references.
- The slug is the bare name: no `TASK-` prefix and no `.md` suffix.
  `task:parse-frontmatter` refers to `TASK-parse-frontmatter.md`.
- A slug may contain hyphens but neither `:` nor whitespace.
  References are therefore unambiguous without quoting.
- Order is not significant to readers.
  Writers sort by kind, then slug, so repeated edits produce stable diffs.
- A repeated reference is the same edge; duplicates carry no additional meaning.
- An artefact must not list itself; a self-reference is a one-node cycle (see Dependency Semantics).

A spec carries the block on its carrier file, above the H1:

```md
---
created-at: 20261022T0855
depends-on: spec:task-scopes
---

# [READY] Task scopes
```

## Dependency Semantics

`depends-on` records a wait, not a link.
`A depends-on B` means A must not be considered startable until B is finished.

The edge is carried only by the dependent.
B holds no reference back to A, and the block never spells a reverse relation such as "blocks" or "related".
Any reverse view is derived by scanning the corpus, so adding a dependency edits exactly one file.

Only the edge is recorded here.
Whether a target counts as finished is decided by the status authority that already owns it: the H1 tags documented in `AGENTS.md` for tasks, and the lifecycle in `refs/lifecycle.md` for specs.
This block never duplicates that state.

Readiness is transitive.
An artefact is startable when every reference is finished and every transitive reference behind them is finished too.

References resolve within the referring artefact's project root: the nearest git root above it.
A reference outside that root counts as missing, even when an artefact with that slug exists elsewhere.

An edge that cannot be satisfied is an error.
That covers a reference to no artefact at all, and a reference to an abandoned one: a missing slug is usually a typo, and abandonment is terminal without being completion.
The block itself remains valid text, but any operation that would treat the dependent as startable fails and names the offending reference.
Nothing is silently blocked, skipped, or started, and no extra metadata records the condition.

A cycle satisfies nothing.
Every member of the cycle is permanently unstartable, and a reader fails with the cycle rather than picking an arbitrary entry point.

The order siblings appear in carries no execution order.
`depends-on: task:a & task:b` says both are needed, not that `a` runs first.

## Ownership & Placement

The block belongs to the artefact file itself, never to a sidecar or an index.
Reading one file tells that file's whole story, and nothing can go stale when it is copied or moved.

For a task, that file is the task file.
For a spec, it is the carrier file the item reports: `DISCOVERY.md` while the spec is in `discovery` or `explo`, then `SPEC.md` from `draft` onward.

That carrier change is the one place the block has to be moved by something other than a human.
`manage-spec` seeds `DISCOVERY.md` at `init`, creates `SPEC.md` on promotion to `draft`, and owns the H1 tag and loader paragraph in both.
It therefore also carries the block across, and it must find the H1 *after* the block rather than on the first line.
It also stops encoding state in the directory name: `SPEC-<slug>/` stays fixed while the tag moves through the lifecycle.
Promotion copies the block into `SPEC.md` and removes it from `DISCOVERY.md`; both files never carry one at the same time.
Rewriting a tag, adding or removing the loader, and moving the directory all leave the block untouched.

Ownership of the content splits by field.

`created-at` is written once, at adoption, and never rewritten.
A creation time is not a value that gets corrected on every save, and there is nothing left to derive it from once the name has lost its date.

`depends-on` is maintained by whoever does the work, human or agent, and edited whenever the wait changes.

No tool regenerates the block.
A regenerator would discard `depends-on` edits, and would invent a `created-at` for artefacts that predate adoption.

State stays out of scope.
The H1 tag remains the authority for a task's status and `manage-spec` remains the authority for a spec's, per `AGENTS.md` and `refs/lifecycle.md`.
No reader may cache status into this block.

## Adoption tooling

The format needs a vehicle.
The corpus is dated and blockless today, and the skills that create tasks and specs know nothing about these fields.

That vehicle is a temporary skill under `opencode/skills/`, named with a `tmp-` prefix: `tmp-frontmatter-migration`.

Temporary is structural, not cosmetic.

- Its `SKILL.md` opens with a banner stating that it exists to migrate and is scheduled for removal.
- It appears in no index, README, or `DIR_AGENTS.md` listing.
- Its description exists only so the runtime can trigger it, and is not documentation.

It must run whenever a task file or a spec carrier file is created or updated.
Nothing fires it automatically: a skill loads because the agent chooses to load it, not because a file changed.
The requirement therefore lands on agents through `AGENTS.md`, which states that such a write goes through this skill.
It never applies to reads, and it leaves handoffs and explorations alone.

One pass over an artefact does the following:

- inserts the block when missing, above the H1;
- fills `created-at` from the filename's timestamp token when one is present, otherwise from current local time;
- renames the file to drop the date token, or the directory to drop its state prefix, suffixing the slug on collision (see Naming & IDs);
- preserves `depends-on` verbatim when present, and never invents a dependency.

The H1 tag, the loader paragraph, and the body are left untouched.

The pass is idempotent: running it twice changes nothing.
That is what makes it safe to trigger on every write.

When it cannot decide, it aborts without writing and names the file.
An unparsable existing block, a collision it cannot resolve, and a spec carrier it cannot identify are all abort cases.
A half-migrated artefact is worse than an unmigrated one.

The skill ships with a `TASK-*` note that records the retirement condition rather than a date: no dated task or spec name remains, and every artefact carries a block.
That note is what eventually deletes the skill, not a calendar reminder nobody reads.

Removal is gated on the artefacts' producers rather than on the corpus.
`task-capture-handoff` and `write-spec init` must emit the block in the files they create, and `manage-spec` must preserve it through promotion and renames.
Once they do, the temporary skill has nothing left to repair, and deleting it leaves no gap.
Until they do, it is the only thing holding the format in place.

## Parsing & Failure Modes

The block is YAML-like, not YAML.
It borrows the fence and the `key: value` shape because both read well, but the format is defined by the rules below alone, not by the YAML specification.
Parsing needs nothing advanced: split off the first line, split each inner line at its first colon followed by a space, then split `depends-on` on the ampersand separator.
No YAML library is involved, and none should be, because a real parser would accept quoted scalars, lists, and nested maps that this format does not define.

Reading rules:

- The opening `---` must be the first line of the file, with no leading blank line and no byte-order mark.
  A reader tolerates a trailing carriage return but writers emit LF.
- The block ends at the next line that is exactly `---`.
- Each line inside is `key: value`: a lowercase kebab-case key, one colon, one space, then a non-empty value.
- Tabs, blank lines, and comment lines are not allowed inside the block.
- A key may appear only once.

Keys other than the two defined ones are tolerated.
Readers ignore them, and the migration pass preserves them verbatim, so a later field can appear without breaking anything that shipped earlier.

An artefact with no opening fence is unmigrated, not malformed.
A reader that needs metadata reports it as unmigrated and does not reconstruct a timestamp from the filename.
That is the state the migration pass exists to remove.

An artefact whose block breaks any rule above is malformed, and this is where the two states must not be conflated.
A malformed block is an error, not an unmigrated artefact.
Callers fail and name the file, the line, and the offending key.
Falling back to "no metadata" would turn a typo into silent data loss.

The failure cases are distinguishable and each has one report:

| Condition | Report |
| --- | --- |
| no block | unmigrated |
| unterminated block | malformed: unterminated |
| line not `key: value` | malformed: line N |
| duplicate key | malformed: duplicate key |
| `created-at` off the 13-character shape | malformed: created-at |
| `depends-on` with an empty value | malformed: depends-on |
| references joined by a bare space | malformed: depends-on |
| kind outside `task` and `spec` | error: unknown kind |
| dependency cycle, including a self-reference | error: cycle |
| reference to a missing or abandoned artefact | error: unsatisfiable |

Values are never coerced.
`2026-10-22T08:55` is not read as a timestamp and `20261022T0855Z` is not trimmed into shape.
Both are malformed `created-at` values.

Repair is not a reader's job.
A reader reports; only a deliberate human or agent edit rewrites a block, and only the migration pass rewrites one automatically.

## Related artifacts

- `SPEC-DRAFT-wk-files/` in the `devtree-harness` repo is the source of the addressing scheme.
  Its item taxonomy defines `[kind]:[slug]` and records a single metadata format as a deferred direction; this spec is that direction, narrowed to two fields and two families.
- `opencode/AGENTS.md` owns task and handoff naming, the `[CLAIMED]`/`[DONE]` tags, and the session lifecycle this format must not duplicate.
- `opencode/skills/write-spec/refs/lifecycle.md` owns spec states and the carrier preference the spec block must follow.
  Its state-prefixed directory names (`SPEC-DRAFT-`, `SPEC-READY-`) must become plain `SPEC-<slug>/`, so the doc itself needs updating.
- `opencode/skills/write-spec/scripts/manage-spec` is the tool that must stop anchoring the H1 on the first line.
- `opencode/skills/task-capture-handoff/` creates task files, so it must emit the block for the migration skill to be removable.
- `./DISCOVERY.md` records the inputs and constraints this spec was drafted from.

## Global Open Questions

**Terminology & Key Concepts** (TKC) — Whether this section is needed for this spec.
Non-blocking. Refer to spec-writing skill for guidance.
