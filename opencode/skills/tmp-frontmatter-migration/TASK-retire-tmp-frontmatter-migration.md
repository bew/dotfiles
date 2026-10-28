---
created-at: 20261028T1207
---

# Retire `tmp-frontmatter-migration` once no dated carrier name remains

The temporary skill `tmp-frontmatter-migration` exists to clear the legacy backlog described in
`opencode/SPEC-BLOCKED-unify-task-spec-metadata-and-naming/SPEC.md`.

## Why the skill exists

The spec asks every task, idea, bug, handoff, and spec carrier to carry a `created-at` block and an
undated name.
Its writers (`work-capture-handoff`, `handoff`, `handoff-standalone`) emit both.
Its adoption trigger in `AGENTS.md`, and its spec-carrier handling in `manage-spec`, do not exist
yet.
Until they do, this skill performs the migration pass by hand.

## Retirement condition

Delete the skill when all three hold:

- no `{TASK,IDEA,BUG,HANDOFF}-<date>-<slug>.md` name remains in this repo
- every carrier in those four families carries the `created-at` block
- spec carriers are migrated by `manage-spec`, so nothing is left for a standalone pass

The condition is checkable, not a date: a date rots, a condition stays true or false.

## Deviation from the git guardrail

`AGENTS.md` forbids tracking `TASK-*` files. This note is tracked on explicit user approval, so the
retirement condition survives in the repo rather than only in one working tree.

## Artefacts

- `opencode/skills/tmp-frontmatter-migration/SKILL.md` — the skill to delete.
- `opencode/SPEC-BLOCKED-unify-task-spec-metadata-and-naming/SPEC.md` — the spec that defines it.
- `opencode/AGENTS.md` — adoption trigger that does not exist yet.
