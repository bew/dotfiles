# [DRAFT] do-it-'later' task manager

## Introduction

`later` — task-stashing tool for dev who context-switches constantly.
Problem: thought appears mid-task (fix to make, thing to try, idea to spec) — interrupt or lose it.
`later` gives thought a place to land, tagged with urgency & context, without breaking flow.

Two surfaces: CLI binary (`later`, Nushell) for interactive use; OpenCode plugin (slash commands + agent tools) so agent can stash deferred work mid-task without session ending.

Deliberately narrow: captures things to do later, not project management.
Items have Level (urgency), Kind (action type), Scopes (project/context).
No due dates, no intra-level priority, no dependencies, no assignment.

Scope system makes `later` context-aware.
Each item tagged with `@scope` labels.
`later ls` shows items for current context by default; brief summary of other scopes with items — focused view, not blind to rest.

Items stored as Markdown files with YAML frontmatter, one file per item, organized by Level under `.later-tasks/`.
Human-readable, grep-friendly, VCS-diffable.
Repo can commit `.later-tasks/` to share deferred work, or gitignore for personal use.
Global Storage Dir handles items not tied to any project.

## Terminology

**Item** (new!): Single deferred task, thought, or intention.
One Markdown file with YAML frontmatter.
Has exactly one Level, one Kind, one or more Scopes, and free-text body.

**Level** (new!): Urgency tier — how soon item is intended to be acted on.
Four levels in proximity order: `next`, `soon`, `someday`, `maybe`.
`next` = "after current task"; `maybe` = "possibly never".

**Kind** (new!): Type of action item represents.
Free-form string; set of predefined canonical values + short aliases.
Examples: `todo`, `fix`, `try`, `spec`, `idea`.
Expressed as subcommand in CLI.

**Scope** (new!): `@`-prefixed label on item indicating project or context it belongs to.
Item may carry multiple Scopes.
Flat tags — no parent/child relationship.
Auto-detected from cwd at add-time; also extracted from inline `@word` tokens in item text.

**Active Scope** (new!): Scope(s) auto-derived from cwd when running `later`.
Used by `later ls` (default) to filter items relevant to current context.

**Storage Dir** (new!): Dir containing Item files organized by Level.
Two kinds: Local and Global.

**Local Storage Dir** (new!): `.later-tasks/` dir at git repo root or cwd (non-git).
Shared across all worktrees (always at git root, never per-worktree).
May be committed or gitignored.

**Global Storage Dir** (new!): User-level Storage Dir for items tagged `@global` (alias: `@glob`) or added outside any repo/dir context.
Configured via `$LATER_GLOBAL_STORAGE_DIR`; defaults to `$XDG_DATA_HOME/later-tasks/`.
Items here always shown in `later ls` here view (globally relevant by definition).

**Source** (new!): Where item was created — `cli` or `opencode`.
Stored in frontmatter for provenance; not used for filtering.

## Design Constraints

These constraints are non-negotiable — they shape every design decision in this spec.

1. **Items outlive sessions.** No session-scoped storage. Items must be readable and writable outside any specific tool (OC, shell session, editor).
2. **Plain files.** Storage uses plain text (Markdown + YAML frontmatter). No binary formats, no embedded DB. Grep works. `git diff` works.
3. **Default view is focused, not blind.** `later ls` always shows scope-filtered items by default. Other scopes always appear as a summary — never hidden entirely, never dumped in full.
4. **Fully local.** No network required for any operation. All scope detection, storage resolution, and listing is offline.
5. **Runtime TBD.** Tool must be fast for interactive use. Nushell is convenient (fits dotfiles conventions) but a compiled language (Rust, Go) may be warranted given complexity. Decision deferred — see Open Questions.

## Naming & IDs

### Item filename

Each Item is stored as a single `.md` file.
The filename encodes a timestamp and a slug derived from the item text:

```
<timestamp>-<slug>.md
```

- `<timestamp>`: `YYYYMMDDTHHmmss` in local time (e.g. `20260613T142301`)
- `<slug>`: up to 5 words from the item text, lowercased, non-alphanumeric chars replaced with `-`,
  leading/trailing `-` stripped, multiple `-` collapsed

Examples:
```
20260613T142301-fix-broken-symlink.md
20260613T143000-try-nu-table-output.md
20260613T150000-spec-later-scope-system.md
```

The filename is collision-free (timestamp resolution: 1 second) and sortable by creation time.

### Level directory names

Level dirs use the canonical Level name as-is: `next/`, `soon/`, `someday/`, `maybe/`.

### Scope token syntax

Scopes are `@`-prefixed lowercase identifiers: `@dotfiles`, `@nvim`, `@plugin`.
No nesting syntax — a sub-scope is just another flat Scope tag (e.g. both `@dotfiles` and `@nvim` on the same item).
When auto-detected from a git remote, the repo basename is used (e.g. `git@github.com:bew/dotfiles` → `@dotfiles`).
When auto-detected from a plain directory, the directory basename is used.

## Storage Layout

Items live in `.later-tasks/` dirs — one per repo/dir (Local), one global (`@global` items + fallback outside repos).
Each Storage Dir: subdir per Level containing Item files.
`@global` scope tag in item text routes item to Global Storage Dir instead of Local.
→ [storage.md](storage.md) for full layout, placement rules, storage resolution.

## Item File Format

Each Item: Markdown file with YAML frontmatter + free-text body.
Frontmatter encodes all structured metadata (level, kind, scopes, source, timestamps).
→ [format.md](format.md) for full schema and file anatomy.

## CLI API

`later` binary: Nushell script, kind-as-subcommand dispatch, level as required flag.
Subcommands: add items (`todo`, `fix`, `try`, `spec`, `idea`, `add`, ...) + list (`ls`).
All subcommands + kinds have short aliases.
→ [cli.md](cli.md) for full reference, alias table, flags, `ls` output formats.

## Scope System

Scopes auto-detected from cwd at add-time; also extracted from inline `@word` tokens in text.
`later ls` filters to Active Scope; summary line for other scopes with items.
→ [cli.md](cli.md#scope-system) for detection logic and filtering behavior.

## Integrations

Two integration points beyond CLI: Zsh keybind for quick in-context review; OpenCode plugin for slash commands + agent tools.
→ [integrations.md](integrations.md) for both.

## Alternatives & Tradeoffs

### Option A — plain text file (one line per item)

```sh
echo "next: fix broken symlink @nvim" >> ~/.later.txt
```

Advantages:
- Zero structure, zero tooling.
- `grep`/`tail`/`cat` work instantly.

Disadvantages:
- No scope filtering — all items always visible.
- No level dirs → no structured listing.
- No per-item metadata without ad-hoc parsing.
- Manual cleanup.

### Option B — todo.txt format

Standard `todo.txt` with `+project` and `@context` tokens.

Advantages:
- Existing tooling (apps, plugins, widgets).
- Portable, widely understood.

Disadvantages:
- `+project`/`@context` don't map cleanly to Level+Scope+Kind.
- Single file → no per-item editing; merge conflicts in VCS.
- No scope-aware filtering by cwd.

### Option C — OC built-in TodoWrite tool

OC's native `TodoWrite`/`TodoRead` let agent manage task list during session.

Advantages:
- Zero setup — built in to OC.
- Agent-native; no external binary.

Disadvantages:
- Session-scoped — items lost when session ends.
- No persistence across sessions or outside OC.
- Not accessible from shell or other tools.
- No levels, kinds, or scope system.

### Option D — `later` (this spec)

Advantages over A/B/C:
- Scope-aware `ls` with here/repo/all views.
- Level dirs give structured urgency without full task manager.
- Per-item files → clean VCS diffs, no merge conflicts.
- Shared across CLI, Zsh, OC — items survive sessions.

Costs vs A/B:
- Runtime dependency (Nushell or compiled binary — TBD, see Open Questions).
- More moving parts (OC plugin, Zsh widget, storage dirs, config.yaml).
- Frontmatter schema adds friction for quick one-off notes.

**Heuristic**: use `later` when scope-aware filtering or cross-session persistence matters.
Use plain text for throwaway scratchpad notes that don't need retrieval.

## Open Questions

1. Should `--no-auto-scope` flag exist to suppress cwd-based scope detection?
   Non-blocking. `@global` in text already routes to global dir; may be sufficient.

2. Scope detection inside a git worktree?
   Non-blocking. Spec uses git root → repo scope only. Worktree name may be useful as additional auto-scope, but no clear use-case yet.

3. `/later-<level>` slash commands: `--kind` flag or leading-keyword extraction?
   Non-blocking. Leading-keyword extraction ambiguous (`/later-next fix the fix` → kind=`fix`?). Explicit flag cleaner but more verbose.

4. `later status` output format — Nu table vs plain text?
   Non-blocking. Nu table filterable in pipeline; plain text better for terminals and OC output.

5. Items movable between levels (`later move <id> --when soon`)?
   Non-blocking. No use-case defined yet; editing frontmatter directly is viable workaround.

6. Zsh widget display: `zle -M` vs persistent output above prompt?
   Non-blocking. Needs experimentation at impl time.

7. **Symlink mode: subdir naming inside Global Storage Dir.**
   Blocking for symlink mode impl. When `.later-tasks/` symlinks into global dir, what's the subdir name?
   Options explored: `repos/<name>/` (explicit namespace), `<name>/` flat (conflicts with level dirs), `by-scope/<name>/` (breaks with multi-scope items).
   None fully satisfying yet. May need a dedicated `linked-repos/` namespace or a manifest file.

8. **Runtime language: Nushell vs compiled (Rust/Go)?**
   Blocking for impl start. Tool has enough complexity (scope detection, config parsing, symlink handling, multi-storage listing) that startup time and robustness matter.
   Nushell: fits dotfiles conventions, easy iteration. Rust/Go: fast, no runtime dependency.
   Decision deferred until scope of impl is clearer.

9. **In-repo file visibility problem.**
   Non-blocking, but UX concern. Items are stored in `.later-tasks/` at repo root — when inside `dotfiles/nvim/plugin/`, items for that context are physically far away (root) and only accessible via `later ls`, not by browsing.
   Possible mitigations: `later edit` to open item file, Zsh widget, symlink mode.
   No action required now but worth revisiting at impl time.

## Related files

| File | Description |
|---|---|
| [storage.md](storage.md) | Full Storage Layout: dir structure, placement rules, VCS notes |
| [format.md](format.md) | Item file format: frontmatter schema, field reference, body rules |
| [cli.md](cli.md) | CLI API: subcommands, alias table, flags, `ls` output formats, scope system |
| [integrations.md](integrations.md) | Zsh plugin (keybind widget) + OpenCode plugin (slash commands + agent tools) |
