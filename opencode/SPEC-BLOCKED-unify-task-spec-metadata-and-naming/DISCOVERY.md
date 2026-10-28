# Basic frontmatter for tasks and specs

## Inputs

**Name** — `Basic frontmatter for tasks and specs`.
**Slug** — `unify-task-spec-metadata-and-naming`.
**Problem** — task, idea, bug, and spec artefacts carry no machine-readable metadata block.
Type lives in the filename, status in the H1 tag, and the creation timestamp is one of the filename tokens, so anything that needs "when was this created" or "what does this depend on" parses names and headings, or cannot answer at all.
Dependency edges in particular have no representation today: a task that waits on a spec, or a spec that waits on another spec, expresses that only in prose.
**Inspirations** — the `wkf` work in `~/self/my-projects/devtree-harness` (`SPEC-DRAFT-wk-files/`), whose `EXPLO-item-taxonomy.md` records "single metadata format (front-matter)" as a deferred direction and whose id vocabulary is `[kind]:[name]`.
Also the filename timestamp convention (`TASK-20261022T0855-<slug>.md`) and the `HANDOFF-` date convention this repo already uses.

## Constraints stated by the user

- **Two fields only, for now**: `created-at` and `depends-on`. This is deliberately a *basic* frontmatter, not the full metadata model.
- **`created-at` format**: `20261022T0855` — the same `YYYYMMDDThhmm` shape the task filename prefix uses. No timezone, no separators.
- **`depends-on` format**: `<kind>:<slug>` values, several on one line separated by ` & `, e.g. `depends-on: spec:foo & task:bar`.
- **Families in scope**: `TASK-*`, `IDEA-*`, `BUG-*` files and specs. Handoffs and `EXPLO-*` files are out of scope.
- **`depends-on` kinds**: `task`, `idea`, `bug`, and `spec` only; any other kind is invalid.
- **Adoption renames the file**: once an artefact carries the block, its name loses the date/datetime token.
  The timestamp lives only in `created-at`, never in both places.
- **Migration is mandatory**: dated names are invalid after the change; the corpus is renamed in one pass.
- **Slug collisions**: the earliest `created-at` keeps the bare slug, later ones take `-2`, `-3`, … permanently.
- **No blocked field**: an artefact that depends on an abandoned target is a hard error at use, not a recorded state.
  The block stays at two keys.
- **Reference scope**: `depends-on` resolves inside the referring artefact's project root (nearest git root).
- **Adoption is automated by a temporary skill**: named with a `tmp-` prefix, undocumented,
  triggered on any task, idea, bug, or spec creation or update, rewriting the artefact into the new format.
  It is meant to disappear once the corpus has migrated, so it ships with a task recording its removal.
- **Unified status-free naming**: `TASK-<slug>.md`, `IDEA-<slug>.md`, `BUG-<slug>.md`, and `SPEC-<slug>/`
  are the only valid shapes.
  Task, idea, and bug names lose the date token, and spec directories lose the state prefix
  (`SPEC-DRAFT-`, `SPEC-READY-` — both wrong).
  State lives in the H1 tag alone, so nothing is renamed when work advances.
- **Validity is gated on `wkf`**: the spec is not valid until the `wkf` tool is available, working, and supports this block format.
  Recorded at the top of the spec as a blocker.
- **Target repo**: `dotfiles/opencode` — the current working directory, not `devtree-harness`.

## Project-global docs

No `CONTEXT.md`, `CONTEXT-MAP.md`, or `PROJECT-SPEC.md` exists in this repo.
Candidate set: `opencode/AGENTS.md` (session lifecycle, `TASK-*`/`HANDOFF-*` handling), `opencode/DIR_AGENTS.md` (directory layout), `opencode/MY_AI_STUFF.md` (artefact catalogue).
The spec-writing lifecycle itself is documented in the `write-spec` skill's `refs/lifecycle.md` and `refs/spec-structure.md`, which the spec references rather than restates.
Awaiting user confirmation of this set.

## Gaps

- **`depends-on` kind vocabulary**: `wkf` uses `task`, `handoff`, `idea`, `bug`, `spec`, `explo`. With tasks, ideas, bugs, and specs carrying frontmatter, it is undecided whether a dependency may still name a `handoff` or `explo`.
- **Who writes it**: whether `manage-spec` seeds and maintains the block for specs, or the block is hand-written and the tooling only reads it. This decides whether `created-at` is trustworthy.
- **Where the block sits for specs**: the spec *directory* holds a carrier file that changes (`DISCOVERY.md` → `SPEC.md`), so a block on the carrier must be carried across that rename.
- **Relationship to existing descriptors**: whether frontmatter duplicates the filename timestamp and the H1 status tag, or gradually supersedes them. Status is explicitly *not* a field here.
- **Existing artefacts**: whether the corpus is migrated, and by what.
- **Parsing strictness**: whether a malformed or absent block is an error, or the file is simply treated as having no metadata.
