# wk file — File-backed work items

## Inputs

**Name** — `wk file — File-backed work items`.
**Slug** — `wk-file-commands`.
**Problem** — the harness carries planning and scoping artefacts as plain markdown at project root (`TASK-*.md`, `HANDOFF-*.md`, managed spec directories with `SPEC.md`/`DISCOVERY.md`, `EXPLO-*.md`).
Type is encoded in the filename and status in the H1 tag, but nothing can enumerate, filter, or transition them.
Beads covers a different store, so "what is open / ready / claimed / done here" is answered by reading files by hand, for the human and for agents.
**Inspirations** — beads' query ergonomics (`list`/`ready`/`show`), the `manage-spec` lifecycle tool and its state vocabulary, the existing ad-hoc naming conventions in this repo, and the earlier session that settled the two-backend direction.

## Constraints stated by the user

- **Management only, never creation.** `wk file` manages artefact files that already exist; it does not scaffold templates, pick names, or create files.
- **Two backends.** The beads passthrough stays untouched; file-backed items are reached through a namespaced `file` family.
  A single unified surface is a possible future, not this spec.
- **New spec path format.** Specs live in `SPEC-DRAFT-<slug>/` / `SPEC-READY-<slug>/` / `SPEC-KO-<slug>/`, seeded and moved by `manage-spec`; `_SPECS/` is the legacy layout and migrates out.
  Retiring a spec keeps its `SPEC-KO-<slug>/` directory in place, and filing an archived one under `.ARCHIVED/<group>/` belongs to `wkf`, not to the lifecycle tool.
- Spec status is owned by `manage-spec`, which keeps the H1 tag and directory name in step.

## Project-global docs

No `CONTEXT.md`, `CONTEXT-MAP.md`, or `PROJECT-SPEC.md` exists in the devtree-harness repo this spec was drafted in.
Candidate set: that repo's `README.md` (devtree, devtree root, harness packages, human-first constraint) and its `docs/**` (`beads-init-complaints.md`, `beads-refs/`).
Confirmed with the user as the set to reference rather than restate.

## Gaps

- "File item", "kind", and "status tag" have no project-global definition; they would be spec-local unless promoted to `README.md`.
- The `[READY]`/`[CLAIMED]`/`[DONE]` title-tag convention currently lives in the user's global `AGENTS.md`, not in this repo.
- Whether a test corpus or fixture is expected is unknown.

