# opencode/ — agent instructions

This directory is the global OpenCode config (`~/.config/opencode`, symlinked to
this repo's `opencode/`). It defines the skills, agents, commands, plugins, and
settings that apply to every OpenCode session on this machine.

## Read first

- `README.md` — overview of this config dir and its local plugin dependencies.
- `MY_AI_STUFF.md` — catalogue of every skill, agent, command, and plugin, with
  dependency graphs for the complex artefacts and the remaining ones.

## Maintenance

Whenever you add, remove, or rename a skill, command, or agent, update
`MY_AI_STUFF.md` to match: its entry (definition link and description) and the
dependency-graph nodes and edges.
A catalogue that drifts from reality is worse than none.

## MY_AI_STUFF.md format

### Grouping and entries

- Entries are grouped by topic (Crafting OC artefacts, Coding, Specs & planning,
  Commits, Handoff & session, Writing & issues), then unmatched entries fall under
  `## Other Skills`, `## Other Commands`, and `## Other Plugins`.
  Omit an `Other …` group when it would be empty.
- Each entry is ``- <Type> [`<name>`](<path>) — <one-line description>``, where
  `<Type>` is Skill / Agent / Command / Plugin.
- A command that only loads a skill and adds no behavior has no description — its
  whole entry is ``**triggers `skill`**``.
  A command that adds behavior (e.g. a default scope) keeps a short description.
- Annotate a skill's name with `(multi-phased)` and/or `(has script)` when true.

### Links

- Every entry's name links to its definition, so the catalogue is one click from
  the source.
- Link target by kind: skills and local plugins point at their directory
  (`./skills/<name>/`, `./plugins/<name>/`); agents and commands point at their
  file (`./agents/<name>.md`, `./commands/<name>.md`).
- Give in-repo target paths an explicit `./` prefix.
- Link the names in the compact `Skills by language/tech:` line and in each
  `Variants:` bullet too.
- A dotfiles-specific skill points across to the repo skills dir
  (`../.agents/skills/<name>/`).
- Third-party plugins have no local definition — leave them unlinked.

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

### Mermaid graphs

- Two `flowchart LR` graphs, in this order:
  1. `### Complex skills` — the artefact groups with real dependencies (Crafting
     OC artefacts, Coding, Spec and planning, Commits), with each group's trigger
     commands folded in, and the cross-graph nodes they reference at the top level.
  2. `### Remaining skills and commands` — the `Misc` group (with the trigger
     commands for the skills it holds), the standalone skills, and the standalone
     commands.
- A trigger command lives in the group of the artefact it triggers, never in a
  dedicated trigger group.
- `Standalone` groups hold artefacts with no dependency edges — no edges to or from
  any other node in the graph.
- Each graph groups nodes into themed subgraphs and labels every edge.
  Solid `-->|label|` edges are hard dependencies (needs / uses / delegates /
  invokes / triggers).
  Dotted `-. label .->` edges are light links; phrase a soft, optional
  relationship as `can …` (e.g. `can load`, `can delegate`, `can use`,
  `can reference`, `can invoke`).
- Node IDs are prefixed by artefact kind — `sk_` skill, `ag_` agent, `cmd_`
  command, `plug_` plugin — then the short name (e.g. `sk_coder_generic`,
  `ag_explore_diff`).
  The real name goes in the quoted display label.
- Prefix each display label by kind, followed by a space: agents take `@`
  (`@ explore-diff`), commands take `/` (`/ commit`), skills take `§`
  (`§ coder-generic`), plugins take `(plugin)` (`(plugin) git-track-new-file`).
- Each graph carries a single `legend` node titled `Prefix legend`, with one line
  per prefix (`@ → Agent`, `§ → Skill`, `/ → Command`, `(plugin) → Plugin`),
  left-aligned (`style legend text-align:left,fill:none`).
- A node used by both graphs is declared independently in each (e.g.
  `ag_explore_diff`); the graphs do not share state.
- A node referenced by a subgraph but not belonging to it is declared outside
  every subgraph, so it does not render inside the wrong group (e.g. the
  cross-graph `sk_cav`, `sk_bew_callout`, and `sk_task_capture` in the complex
  graph, or `ag_explore_diff` in the remaining graph).
- Do not add `~~~` invisible links — Mermaid does not honour them.
- Do not add `classDef` styling for trigger commands; nodes use the default style.
- The graphs are still a partial view: dotfiles-specific artefacts and third-party
  plugins are not shown. Keep the intro noting the scope.

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
