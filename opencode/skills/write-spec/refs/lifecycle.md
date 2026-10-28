# Spec Lifecycle

`manage-spec` owns every state change: it rewrites the H1 status tag,
adds or removes the skill-loader paragraph, and moves the directory.
Never move a spec directory or edit its status tag by hand.

## States and directories

| State | Tag | Directory |
|---|---|---|
| `discovery` | `DISCOVERY` | `SPEC-DRAFT-<slug>/` |
| `explo` | `EXPLO` | `SPEC-DRAFT-<slug>/` |
| `draft` | `DRAFT` | `SPEC-DRAFT-<slug>/` |
| `maybe-ready` | `MAYBE-READY` | `SPEC-DRAFT-<slug>/` |
| `ready` | `READY` | `SPEC-READY-<slug>/` |
| `abandoned` | `ABANDONED` | `SPEC-KO-<slug>/` |

Several states share a directory: the prefix splits work-in-progress, ready material, and retired
material.
Because four states share `SPEC-DRAFT-<slug>/`, the directory name cannot name those states —
the tag decides.

## Transitions

| From | Allowed targets |
|---|---|
| `discovery` | `explo`, `draft` |
| `explo` | `draft` |
| `draft` | `explo`, `maybe-ready`, `ready` |
| `maybe-ready` | `draft`, `explo`, `ready` |
| `ready` | `draft`, `explo`, `maybe-ready` |
| `abandoned` | `draft`, `explo` |

Every state may move to `abandoned`; it is the one universal target and is therefore left
out of the table.

`discovery` may go straight to `draft`; the only other way out is `explo`.
No transition targets `discovery` — `init` creates it, and a spec never returns to it.
`DISCOVERY.md` stays editable from every later state, so discovery notes can still be corrected
or extended after promotion.

`maybe-ready`, `ready`, and `abandoned` may also drop straight back to `explo` when the central
design question reopens; every other demotion goes through `draft`.

`explo` → `draft` needs the user's explicit `Switch to Draft` answer to the
`design-exploration` `Phase:Wrap` exit question.
A frozen topic index or a settled-looking exploration never substitutes for that answer.
This gate is skill-enforced; `manage-spec` moves `explo` → `draft` without checking it.

`manage-spec` refuses anything outside this table plus the universal `abandoned` target.

## Usage

`init` runs in the project directory being spec'd; every other command runs from inside the spec
directory, where the script infers the spec from the cwd:
```sh
<skill-dir>/scripts/manage-spec init <slug> [<title>]
<skill-dir>/scripts/manage-spec <state> [--fix]
<skill-dir>/scripts/manage-spec rename <slug-or-title> [<title>] [--fix]
<skill-dir>/scripts/manage-spec rebase <new-base>
```

`<state>` is one of the state names above, so `manage-spec ready` moves the spec to `ready`.

`init` creates `SPEC-DRAFT-<slug>/` in the `discovery` state and always seeds `DISCOVERY.md`
with the `[DISCOVERY]` H1, the loader paragraph, and the title (defaulting to the slug).
It prints `$slug`, `$specdir`, `$specpath`, then the next file to write.
When the design needs no exploration, `manage-spec draft` promotes a `discovery` spec
straight away.

`rename` keeps the current state.
A single-word argument is a new slug; a spaced argument is a new H1 title.
Passing a slug plus a title changes both.
A title must be more than one word, otherwise it would read as a slug.

`rebase` moves the spec directory under another base directory, keeping its state and every file.
`<new-base>` is resolved against the project root, must already exist, and must sit inside the
project; its parent directory is what changes, never the spec's own name.

Every documented command that leaves the spec somewhere else prints the `Session vars` the caller
now has to use, and they are relative to the base directory the spec lives in — not necessarily
the repo root.
`rebase` changes that base for every later command, so the scope of slug uniqueness moves with it:
a spec rebased into `specs/` becomes `specs/SPEC-KO-<slug>/` when abandoned, and its slug only
collides with slugs under `specs/`.
`migrate` is the exception: it prints the new location and state only.
Take the values from that output; do not derive them yourself.
`$specpath` is the file to read and edit; its name can change while `$specdir` stays put.
`Session vars: unchanged` means the values did not move, whether because the state shares its
directory or because the state was already current.

After a command that moves the spec, the current working directory is gone.
`cd` from the project root into the printed `$specdir` before running the next command.

## Legacy layouts

Specs written before this layout live in `_WIP_SPECS/<slug>/` or `_SPECS/<slug>/`.
Migrate them rather than leaving them there or writing a `SPEC.md` by hand:
```sh
<skill-dir>/scripts/manage-spec migrate <legacy-dir>
```
It reads the H1 tag to pick the target state, defaults a tagless spec to `draft`, and moves the
directory.
It also renames `EXPLORATION-BRIEF.md` / `EXPLORATION-<topic>.md` to `EXPLO-*`, and rewrites
references to those old filenames inside the moved files.
A collision with an existing `EXPLO-*` file aborts before anything is renamed.
A legacy directory with no `SPEC.md` seeds `DISCOVERY.md` and enters `explo`.
`migrate` is absent from `--help` on purpose: it drains the old layout, it is not a daily command.

## Guards

- **H1 tag outside the vocabulary**: refuse, naming the tag.
  A marker another tool prepended is called out as such: stop and ask the user to reset the tag,
  never strip the marker yourself.
- **Directory name vs H1 tag disagree**: refuse, printing both paths.
  The H1 tag wins, and `--fix` repairs the directory name by deriving it from the tag.
  `--fix` works on every state command and on `rename`; `rebase` and `migrate` do not take it.
  Combined with a transition, the repair runs first, then the state change.
  `manage-spec <current-state> --fix` repairs without changing the state.
- **Target directory already exists**: refuse, always — merging two specs is a manual decision.
- **Staged changes**: never block a move.
  `manage-spec` has no dirty-index guard; a `git mv` simply stages the rename alongside the
  unrelated staged changes.

If a move fails after the tag was rewritten, the script says so and prints both paths;
the spec then sits in a directory that disagrees with its tag until
`manage-spec <target-state> --fix` (or `rename <new-slug> --fix`) repairs it.

## After a transition

1. Take the printed `Session vars` as the session's `$slug`, `$specdir`, `$specpath`.
   `Session vars: unchanged` means they keep their current values.
2. Never edit the H1 tag or the loader paragraph afterwards: the script already did.

Use `rename` rather than a manual `mv` when the name or slug changes mid-spec
(temporary name replaced, concept renamed, etc.).

## Explorations

Exploration files live inside `$specdir` and are not managed by `manage-spec`:
`EXPLO-BRIEF.md` as the hub, plus one `EXPLO-<topic>.md` per topic.
The `design-exploration` skill owns their content and lifecycle.

`DISCOVERY.md` is the opposite: `manage-spec` seeds it and owns its H1 and loader block.
Everything below its loader paragraph is free-form discovery material.
In the `explo` state the loader gains a pointer saying the `design-exploration` skill owns the
work until promotion.
