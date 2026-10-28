---
name: tmp-frontmatter-migration
description: |
  Load when asked to migrate, rename, or fix the name or frontmatter of task, idea, bug, or
  handoff files — one file or a whole directory, e.g. "migrate this task file",
  "drop the dates from these notes", "add the frontmatter block to these handoffs".
metadata:
  maintainers: [bew]
---

WARNING: Temporary skill.
It exists to migrate legacy carriers and is scheduled for removal.
Retire it once no dated `TASK-`/`IDEA-`/`BUG-`/`HANDOFF-` name remains and every carrier carries
the block.
The tracked note `TASK-retire-tmp-frontmatter-migration.md` beside this file states the full
condition, spec carriers included.

## Goal

One pass per carrier file — `created-at` block above the H1 and an undated `<KIND>-<slug>.md`
name, everything else untouched — and a second run changes nothing.

## Setup — resolve inputs

Resolve from the user message and prior context:

- **Target** (`$target`): one carrier file, or one directory to walk. Required.
  If absent, stop and ask the user. Never default to the working directory.
- **Carriers** (`$carriers`): when `$target` is a directory, run
  `fd --type f '^(TASK|IDEA|BUG|HANDOFF)-' "$target"` and take every file it lists.
  `fd` recurses and skips gitignored paths, so `.git` and build output stay out of the sweep.
  When `$target` is a file, `$carriers` holds that file alone.

If `$target` is a `SPEC-*` path, `SPEC.md`, or `DISCOVERY.md`: stop before writing anything.
Say spec carriers belong to `manage-spec`, and ask how to proceed.

State resolved values:

```
$target: <path>
$carriers: <count>
```

**Vars used throughout**: state each once known.
- `$target` — resolved file or directory.
- `$carriers` — carrier files in scope.
- `$kind` — `TASK`, `IDEA`, `BUG`, or `HANDOFF`, per file.
- `$created_at` — `YYYYMMDDThhmm`, per file.
- `$newpath` — the undated target path, per file.

## Step 1 — Survey

Decide per file. Write nothing yet.

1. **Read the head** — from the first line to the closing `---`.
   First line `---` means the block already exists: keep it verbatim, never rewrite or re-add it.
   A block with no closing `---`, or with no `created-at` line: abort the file as malformed and
   name it in the report.
2. **Derive `$kind`** from the filename prefix.
   Any other prefix: leave the file alone and name it in the report.
3. **Derive `$created_at`** — read it from an existing block when there is one.
   Never re-derive a value the block already holds.
   Otherwise the filename token: `YYYYMMDDThhmm` as-is, `YYYYMMDD` becomes `<date>T0000`.
   With no token and no block, take the file's modification time
   (`date -r <file> +%Y%m%dT%H%M`).
   The token is the `-`-delimited segment right after the kind prefix, as in
   `TASK-20261022T0855-parse-frontmatter.md`.
4. **Derive `$newpath`** — drop the date token from the filename.
   A name already without a token keeps its name.
   An empty slug once the token is dropped: abort the file and name it.
5. **Check collisions** — a path already occupied on disk keeps its file, whether or not that file
   is in this run.
   Among carriers competing for the same free name, order them by `created_at`.
   The earliest keeps the bare name; the others append `-2`, `-3`, … to the slug, incrementing
   until the path is unoccupied.
   Carriers that tie with each other cannot be ordered: abort the tied files, and let the bare name
   fall to the next carrier that can be ordered.
6. **Abort** a file whose first line is neither `---` nor an H1.
   Name it in the report, write nothing to it, and keep going with the rest.
7. **Flag tracked carriers** — run `git ls-files --error-unmatch -- <file>`.
   Exit `0` means tracked, exit `1` means untracked.
   Any other status leaves the file undecided: skip it and report it under `left alone` with the
   exit status.
   Ask the user about a tracked carrier in the plan, and write nothing to that file until they
   answer.

An empty `$carriers` reports zero carriers and stops: no plan, no go-ahead.
A `SPEC.md` or `DISCOVERY.md` nested under `$target` never matches the filter, so no spec carrier
is swept.
A `TASK-*` file that happens to sit inside a `SPEC-*` directory is swept like any other.

Present the plan — one line per file, action first.
Wait for the user's go-ahead before migrating.
A single carrier may proceed without the plan review when the action is only a block insert.
That shortcut excludes a carrier still awaiting a tracked answer.

## Step 2 — Migrate

NOTE: In PLAN mode, stop.
Say the migration needs BUILD mode, then wait for the user to switch and re-request.
Write nothing until then.

For each carrier *Step:Survey* kept in scope, in survey order:

1. **Insert the block** when missing — `edit` the first line, replacing it with the block followed
   by that same line.
   Block: `---`, `created-at: <$created_at>`, `---`, then a blank line.
   Never `write` a carrier.
2. **Rename** when `$newpath` differs — plain `mv`, never a suffix outside the collision rule.
   A carrier the survey flagged as tracked, once the user approves, uses `git mv`.
   An unanswered tracked question skips both items: no block, no rename.
   A declined tracked carrier skips the file entirely and is reported under `left alone`.

A file already carrying block and undated name: skip, count it as unchanged.

If a write fails (e.g. the directory vanished): report the file under `error`, say what failed, and
continue with the rest.
If a rename fails after the block was inserted: leave the block, report the file under `error` in
*Step:Report*, and continue.

## Step 3 — Report

Report one line per file, grouped by outcome:

- `renamed` — old name → new name.
- `block added` — block added, name already undated.
- `both` — block added and renamed.
- `error` — block insert or rename failed; the report line says which.
- `skipped` — tracked carrier awaiting the user's answer.
- `unchanged` — already migrated.
- `left alone` — out of scope, malformed, aborted, or declined, with the reason.

Close with the counts.
When the swept `$target` holds no dated carrier name and every carrier in it carries the block, say
so — the retirement condition may be met.

## Rules

- ALWAYS `edit` a carrier or rename it with `mv`. Never `write` one.
  A tracked carrier the user approved is the one exception, and it uses `git mv`.
- Insert the block before renaming.
  Never rename a carrier that carries no block, and never leave a renamed carrier without one.
- Never rename onto a path that already exists — `mv` must not overwrite a carrier.
- Never git-add, stage, or commit a carrier file.
  The only staging allowed is what `git mv` does on an approved tracked carrier.
  The retirement note beside this skill is tracked on explicit approval, and needs no migration.
- Never rewrite `created-at` on a file that already carries it, and never invent `depends-on`.
- Leave the H1, its status tag (`[CLAIMED]`, `[DONE]`, `[CONFIRMED]`), the loader paragraph, and
  the body untouched.
- Never migrate an exploration file (`EXPLO-*`) — outside this format.
- Never migrate a spec carrier — `manage-spec` owns those.
- One pass per file. A second run leaves every migrated file unchanged.
- Name every file you refuse to migrate, and why.
