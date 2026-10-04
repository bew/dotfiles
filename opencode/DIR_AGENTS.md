# opencode/ — agent instructions

This directory is the global OpenCode config (`~/.config/opencode`, symlinked to
this repo's `opencode/`). It defines the skills, agents, commands, plugins, and
settings that apply to every OpenCode session on this machine.

## Read first

- `README.md` — overview of this config dir and its local plugin dependencies.
- `MY_AI_STUFF.md` — catalogue of every skill, agent, command, and plugin, with a
  dependency graph for the complex ones.

## Maintenance

Whenever you add, remove, or rename a skill, command, or agent, update
`MY_AI_STUFF.md` to match: its entry description and the dependency-graph edges.
A catalogue that drifts from reality is worse than none.

## MY_AI_STUFF.md format

### Grouping and entries

- Entries are grouped by topic (Crafting OC artefacts, Coding, Specs & planning,
  Commits, Handoff & session, Writing & issues), then unmatched entries fall under
  `## Other Skills`, `## Other Commands`, and `## Other Plugins`.
  Omit an `Other …` group when it would be empty.
- Each entry is ``- <Type> `<name>` — <one-line description>``, where `<Type>` is
  Skill / Agent / Command / Plugin.
- A command that only loads a skill and adds no behavior has no description — its
  whole entry is ``**triggers `skill`**``.
  A command that adds behavior (e.g. a default scope) keeps a short description.
- Annotate a skill's name with `(multi-phased)` and/or `(has script)` when true.

### Sub-blocks

- Put a blank line before each sub-block under an entry: capability bullets,
  `Used for …` / `Used explicitly by …`, and `Variants:`.
- `Used explicitly by …` names the phase/step and why when the artefact is a
  dependency of another one; some artefacts are auto-loaded instead.
- `Used for …` is required when an artefact is used by exactly one skill.
- `Variants:` holds nested `*` bullets for derived skills; variants do not get their
  own top-level entries.

### Ordering

- Order entries most-important first; put a leaf below everything that uses it
  explicitly (e.g. a helper skill below its consumer).
- List `coder-*` languages compactly on one line (`Skills by language/tech: …`)
  instead of one entry each; keep dedicated entries for `coder-generic` and
  `coder-meta`.
- List dotfiles-specific artefacts (from `<repo>/.agents/` and `<repo>/.opencode/`)
  in their own section, separate from the global config.

### Mermaid graph

- The graph is `flowchart LR`, groups nodes into themed subgraphs, and labels every
  edge: needs / uses / delegates / invokes / derived from / loads / fallback /
  triggers.
  Use solid `-->|label|` for hard dependencies and dotted `-. label .->` for soft
  loads or fallbacks.
- It is a partial view — add an intro noting it does not show every artefact.
- Node IDs are descriptive but short: no single letters and no full names, ≤15
  chars, and `2` for "to" (e.g. `diff2commits`).
  The real name goes in the quoted display label.
- Style trigger-command nodes with `classDef trigger`.

## Layout

- `skills/<name>/SKILL.md` — skills (some nest sub-skills and `refs/`).
- `agents/<name>.md` — agents.
- `commands/<name>.md` — commands.
- `plugins/<name>/` — local plugins; their npm deps live in the root
  `package.json` + `bun.lock`, installed by `just update-local-plugins-deps`;
  run their tests with `just test <name>`.
- `opencode.jsonc` — main config (settings, `plugins`, agents, …).
- `cli.json` — CLI/TUI-only settings.
- `AGENTS.md` — the global system-prompt instructions (this dir is their root).
- `NOTES-opencode2.md` — running notes on OpenCode V2 behaviour.
