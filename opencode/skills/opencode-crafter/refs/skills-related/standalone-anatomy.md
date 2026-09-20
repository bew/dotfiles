# Skill-Standalone Anatomy

Single-file, tool-less export of an existing skill.
Derived — never authored from scratch.

## What it is

A self-contained `SKILL.md` + provenance `README.md` + `VARIANT` marker.
Target: ad-hoc loading into tool-less chat contexts (Perplexity, ChatGPT, raw prompt).
Export-only: it lives in the skills root as a loadable skill, but is not intended
to trigger at runtime — paste it into a foreign tool manually.

## Constraints

- Single `SKILL.md` + `README.md` + `VARIANT`.
  No `refs/`, `scripts/`, `assets/`, or `templates/`.
- No OC mechanics: `write`, `edit`, `read`, `bash`, git, filesystem paths/folders,
  subagents, `skill` tool, `question` tool.
- No interactive loop: phase gates and mid-pass checkpoints removed.
  Phase names are kept — they are conceptual, not OC-specific.
- Output is inline (fenced block) — never "write to `<path>`".
- No companion command.
- No scripts: if the base has `scripts/`, refuse and ask the user how to proceed.

## Install

- `name`: `<base-name>-standalone`.
- Location: sibling of the base skill — `<base-parent>/<base-name>-standalone/`.
  Same scope as base (global or project).

## Frontmatter

Minimal: `name`, `description`, `metadata.maintainers`.
The `description` stays minimal: the standalone is not meant to trigger at runtime,
so trigger precision does not matter.

```yaml
---
name: <base-name>-standalone
description: |
  Self-contained export of `<base-name>` for ad-hoc loading into tool-less chat contexts.
  All instructions inlined — no external files.
metadata:
  maintainers: [<current-user>]
---
```

## Derivation

1. Read the base `SKILL.md` and every ref it triggers.
2. Inline each ref's content at its trigger site, in the order the base reads them.
3. Remove phase gates and mid-pass checkpoints.
4. Strip OC mechanics per the transform table below.
5. Inline any `§slug` cross-refs; ensure no dangling references remain.
6. Keep phase names and section structure — do not flatten phases.
7. Adapt `description`; write `README.md` and `VARIANT` (containing `standalone`).

## Transform table

| Base construct | Standalone replacement |
|---|---|
| `Read <./refs/x.md> for …` | Inline `x.md` content at that point |
| ``Ready to move to `Phase:X`? …`` | Remove |
| ``Use `write` for creation`` | "Output the result inline in a fenced block" |
| `<path>/<slug>/SPEC.md` | Remove path; output inline |
| `` run `scripts/foo` `` | Block — do not derive |
| `git …` | Remove |
| `skill` / subagent / `question` tool | Remove |
| Companion command trigger | Remove |
| `§slug` cross-ref | Inline target content |

## Sync (update)

The standalone is a variant of the base skill.
Updated via `Phase:PropagateChange` — only after the base-skill change is validated.

1. Semantic diff: compare the current base skill against the standalone's inlined content.
2. List divergences.
3. Mirror a divergence only if it survives the constraints above.
   - New ref → inline its content.
   - New phase gate, trigger-style change, companion command change → skip.
   - New script → refuse; ask the user how to proceed.
4. Apply targeted edits in place; re-check touched regions against the constraints.

## README format

```md
# <base-name>-standalone

Self-contained export of `<base-name>`, for ad-hoc loading into tool-less chat contexts.
All instructions inlined — no external files.

Source: `<base-name>` at `<base-parent>/`.

## Differences from `<base-name>`

| | `<base-name>` | `<base-name>-standalone` |
|---|---|---|
| File structure | `SKILL.md` + resources | Single `SKILL.md` |
| Variant marker | none | `VARIANT` (`standalone`) |
| Progressive disclosure | Loads refs on demand | All content inline |
| Interactive loop | Phase gates | None |
```

## Verification

- No `refs/`, `scripts/`, `assets/`, or `templates/` dirs.
- No OC tool names, git, filesystem paths/folders, subagents.
- No phase gates or mid-pass checkpoints.
- No dangling `./refs/` or `§slug` references.
- Output instructions are inline-output style.
- `name` matches directory name and equals `<base-name>-standalone`.
- `README.md` present with a source pointer.
- `VARIANT` file present, containing `standalone`.
