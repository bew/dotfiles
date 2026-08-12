# [DRAFT] Agentic Stuff Reorganization

## Introduction

`dotfiles/opencode/` is the config root for OpenCode.
It conflates two kinds of artefacts: those coupled to OpenCode's primitives (agents, commands, plugins, tools, meta-skills), and those that are fully generic — behavioral skills, coding guidelines, git workflows — applicable to any AI agent.

Immediate motivation: adopting pi-agent alongside OpenCode.
Without a shared layer, every skill built for OpenCode must be duplicated into pi-agent's config.
Goal: make the vast majority of skills agent-agnostic; keep only genuinely agent-system-specific artefacts in each agent's own dir.

This spec defines:
- a new agentic root layout with a shared `agent-agnostic/` dir + per-agent `*-specific/` dirs
- a composition model (each agent's effective config = its own dir merged with `agent-agnostic/`)
- a naming convention + rename mapping for artefacts that change scope

Most current opencode-specific skills are candidates for future migration to `agent-agnostic/`; that analysis is deferred.

## Terminology

**Agentic root** (new!): Top-level dir owning all agent config — agent-specific subdirs + shared `agent-agnostic/`.
Primary design: subdir of `dotfiles/`; dedicated-repo alternative: the repo root itself.

**Agent-agnostic artefacts** (new!): Skills, prompts, config files with no dependency on a specific agent system's primitives.
Applicable regardless of which agent loads them (coding style, commit drafting, spec writing, etc.).

**Agent-specific artefacts** (new!): Artefacts depending on a specific agent system's extension model.
Examples for OpenCode: `.md` agents, `.md` commands, `.ts` plugins, `.ts` tools, and skills describing how to author those primitives.

**Agentic primitive** (new!): First-class extension point of a specific agent system.
OpenCode: agents, commands, plugins, tools, skills. Term is agent-system-scoped.

**Config composition** (new!): Merge of `agent-agnostic/` + agent-specific subdir → effective config loaded by an agent.
Mechanism is per-machine (determined by installation mode), not per-artefact.

**Artefact** (well-known): Discrete config file (skill, agent def, command, plugin, tool, snippet) registered with an agent system.

**OpenCode** (well-known): AI coding agent at https://opencode.ai, config at `~/.config/opencode/`.

**pi-agent** (new!, placeholder): Future agent system with its own `*-specific/` subdir. Name provisional.

## Proposed Layout

Primary design: agentic root lives inside `dotfiles/` (name TBD — see Open Questions).

```
agentic-stuff/                       ← agentic root (name TBD)
├── agent-agnostic/                  ← artefacts shared across all agents
│   ├── skills/
│   │   ├── generic-agentic-crafter/ ← renamed from opencode-crafter (agent-agnostic core)
│   │   ├── agent-blocker/
│   │   ├── caveman/
│   │   ├── write-spec/
│   │   └── ...                      ← all other generic skills (slugs unchanged)
│   ├── agents/                      ← agent-agnostic agent defs (e.g. generic diff-explorer)
│   ├── commands/                    ← agent-agnostic command defs (if any)
│   └── AGENTS.md                    ← placement is an open question
│
├── opencode-specific/               ← OpenCode artefacts
│   ├── AGENTS.md                    ← OpenCode-specific prompt additions (if AGENTS.md is split)
│   ├── opencode.jsonc
│   ├── tui.jsonc
│   ├── dcp.jsonc
│   ├── agents/
│   ├── commands/
│   ├── plugins/
│   ├── tools/
│   ├── snippets/
│   └── skills/
│       ├── opencode-artefact-rules/
│       ├── opencode-crafter/        ← thin wrapper over generic-agentic-crafter
│       ├── opencode-reflect-friction/
│       └── opencode-test-runner/
│
├── pi-agent-specific/               ← placeholder; .gitkeep
│
├── nix/                             ← Nix packaging & activation layer
│
└── _WIP_SPECS/                      ← design specs (agent-agnostic; top-level for visibility)
```

**Notes:**
- `opencode-crafter` in `opencode-specific/` becomes a thin wrapper over `generic-agentic-crafter`, adding OpenCode primitive anatomy.
- `grill-me-*` skills (3 variants) → `agent-agnostic/skills/` as-is (all agent-agnostic, manual-only, not registered).
- `_WIP_SPECS/` lives at the **agentic root top-level** (not inside any subdir).
- `nix/` lives as a subdir at the agentic root top-level (no `flake.nix` at root).
- Most `opencode-specific/skills/` items (e.g. `opencode-artefact-rules`, `opencode-test-runner`) are candidates to be refactored into agent-agnostic equivalents; analysis deferred, non-blocking.

### Open Questions

1. What should the agentic root dir be named?
   Non-blocking. Candidates: `agentic-stuff`, `ai-agents`, `agentic`. Final choice deferred.

2. Where does `AGENTS.md` live?
   Blocking before migration. Options: (a) split — `agent-agnostic/AGENTS.md` + `opencode-specific/AGENTS.md`; (b) single file at agentic root; (c) only in `opencode-specific/` with generic rules inlined.
   Splitting is cleanest but requires agents to support loading multiple prompt files.

## Agent Config Composition

Effective config for an agent = `agent-agnostic/` + `*-specific/` merged.
Agent-specific artefacts take precedence on name collision.

Composition mechanism is global per machine (set by installation mode):

- **Nix-managed**: Nix derivation merges both dirs into a read-only output → linked as `~/.config/<agent>/`.
  Reproducible + pinned; changes require rebuild.

- **Mutable install** (dev/local): composition at runtime so edits are picked up immediately.
  Candidate approach: FUSE-based union filesystem (Rust) presenting a live merged view at `~/.config/<agent>/`.
  Speculative — requires its own design spec; noted as future work.

Both models must remain compatible with the layout in this spec.

By design, composition produces a **single merged dir** that the agent sees as `~/.config/<agent>/`. This keeps the agent config surface simple and avoids relying on agent-specific multi-dir loading support.

### Open Questions

1. Right mechanism for runtime composition on mutable installs?
   Non-blocking. FUSE union (Rust) is one candidate; simpler: startup script copying/symlinking both sources into one dir. Needs dedicated spec.

## Naming Convention & Rename Mapping

### Convention

**Agent-agnostic skills**: kebab-case, no agent-system prefix (e.g. `write-spec`, `caveman`, `draft-commit-message`).

**Agent-specific meta-skills**: carry agent-system prefix (e.g. `opencode-crafter`, `opencode-artefact-rules`).

**`generic-agentic-crafter`** (special case): agent-agnostic core of crafter logic (how to author any agentic primitive).
Agent-specific crafters (`opencode-crafter`, future `pi-crafter`) are thin wrappers extending it with system-specific anatomy.
Name is provisional — see Open Questions.

### Rename Mapping

| Current path | New path | Notes |
|---|---|---|
| `opencode/skills/opencode-crafter` | `agent-agnostic/skills/generic-agentic-crafter` | Core logic extracted, renamed |
| `opencode/skills/opencode-crafter` (residual) | `opencode-specific/skills/opencode-crafter` | OC-specific wrapper; slimmed down |
| `opencode/skills/opencode-artefact-rules` | `opencode-specific/skills/opencode-artefact-rules` | Already OC-scoped; path update only |
| `opencode/skills/opencode-reflect-friction` | `opencode-specific/skills/opencode-reflect-friction` | Same |
| `opencode/skills/opencode-test-runner` | `opencode-specific/skills/opencode-test-runner` | Same |
| All other `opencode/skills/*` | `agent-agnostic/skills/*` | Generic; slugs unchanged |

Slugs with no change (all moving to `agent-agnostic/`): `write-code-*`, `write-spec*`, `caveman*`, `agent-blocker`, `agent-stuck`, `bew-*`, `karpathy-guidelines`, `gh-read-file`, `read-man-page`, `reflect-code-skills`, `reflect-script-skills`, `incremental-write`, `write-github-issue`, `grill-me-*`.

Skills marked for split (generic core extracted, OC wrapper stays in `opencode-specific/`):
- `diff-to-commits-drafts`: agnostic core = four-phase workflow + grouping/drafting logic; OC-specific = `task` tool invocation, PLAN/BUILD mode guard, slash-command trigger.
- `draft-commit-message`: agnostic core = diff analysis procedure, style detection, subject/body rules; OC-specific = `task` tool for subagent dispatch, `question` tool calls, PLAN/BUILD mode guards.

`incremental-write` was initially classified split but decided to move as-is to `agent-agnostic/`; OC-specific examples will be fixed in place when moving.

Skills that stay in `opencode-specific/` (not agent-agnostic):
- `git-track-new-file`: entire skill wraps the `git_track_new_file` opencode tool primitive. No generic equivalent without a different agent's tool.

### Open Questions

1. Should generic crafter be named `generic-agentic-crafter` or shorter (e.g. `agentic-crafter`, `primitive-crafter`)?
   Non-blocking. Shorter name reduces friction in trigger descriptions.

2. When generic equivalents of `opencode-reviewer`, `opencode-simulated-test-runner`, `opencode-skill-script-crafter` are introduced in `agent-agnostic/agents/`, they drop the `opencode-` prefix but retain a descriptive prefix (e.g. `artefact-reviewer`, `simulated-test-runner`, `script-crafter`). The OC-specific versions keep their `opencode-` prefix.

## Configuration Changes

### Symlink

`~/.config/opencode/ → dotfiles/opencode/` → update to point to composed config dir:
- Nix install: Nix-built merge of `opencode-specific/` + `agent-agnostic/`
- Mutable install: live union mount (see Agent Config Composition)

### `opencode.jsonc`

No structural changes. Composition produces a single merged dir, so no multi-dir loading support is needed from OpenCode.
Plugin refs (`opencode-snippets`, `dcp`) stay unchanged.

### `tui.jsonc` / `dcp.jsonc`

No changes. Stay in `opencode-specific/`.

### Skill registration (`available_skills` in AGENTS.md)

After composition, `agent-agnostic/` skill paths must resolve correctly in `available_skills`.
If `AGENTS.md` is split, each part lists only the skills it owns.

## Alternatives & Tradeoffs

### Option A — Subdir in dotfiles (primary)

```
dotfiles/
├── agentic-stuff/
│   ├── agent-agnostic/
│   ├── opencode-specific/
│   └── pi-agent-specific/
└── ...
```

**Advantages:** single repo, unified history, no extra remote; existing Nix/symlink management works with path updates.

**Costs:** high-frequency skill edits pollute dotfiles git log; PR surface shared with unrelated dotfiles changes.

### Option B — Dedicated repo (alternative)

Standalone repo (e.g. `bew-agentic-stuff`) hosting only the agentic root.

**Advantages:** clean git history scoped to agentic artefacts; independently versionable + shareable.

**Costs:** extra remote to manage; Nix flake must reference two repos (or agentic repo becomes a dotfiles flake input); cross-repo coordinated commits needed for coupled changes.

**Decision criteria:**
Use A if log noise is acceptable and dotfiles is the primary config surface.
Use B if churn warrants isolation or repo needs to be shared/published independently.

## Artefact Analysis

Full read-and-classify pass over all current artefacts (except `opencode-crafter` internals — deferred).
Verdicts: `opencode-specific` | `agent-agnostic` | `split` (has extractable generic core).

### Skills

| Slug | Verdict | Key evidence |
|---|---|---|
| `agent-blocker` | agent-agnostic | Pure behavioral protocol; no OC primitives. |
| `agent-stuck` | agent-agnostic | Doom-loop detection + escalation; no OC primitives. |
| `bew-communication-style` | agent-agnostic | Prose style rules; no OC primitives. `question` tool is generic. |
| `bew-inline-callout-style` | agent-agnostic | Inline callout conventions; OC path in example text is incidental. |
| `caveman` | agent-agnostic | Compression rules + auto-clarity; `/caveman` trigger is illustrative, not OC-registered. |
| `caveman-review` | agent-agnostic | Code review format; zero OC dependency. |
| `diff-to-commits-drafts` | **split** | Core: four-phase workflow, grouping, drafting. OC wrapper: `task` tool, PLAN/BUILD mode, slash-command trigger. |
| `draft-commit-message` | **split** | Core: style detection, subject/body rules. OC wrapper: `task` tool for subagent, `question` tool, PLAN/BUILD guards. |
| `gh-read-file` | agent-agnostic | Pure `gh` CLI workflow; no OC primitives. |
| `git-track-new-file` | opencode-specific | Entire skill wraps `git_track_new_file` OC tool primitive. |
| `grill-me-full` | agent-agnostic | Socratic interview methodology; not registered in `available_skills` (manual-only). |
| `grill-me-medium` | agent-agnostic | Compressed `grill-me-full`; not registered. |
| `grill-me-original` | agent-agnostic | Nine-line minimal prompt; external origin (mattpocock). Not registered. Internal `name:` was `grill-me-minimal` (slug inconsistency — fixed). |
| `incremental-write` | agent-agnostic | Core: skeleton-first → confirm → fill workflow. OC seams (trigger examples, tool names) are thin — move as-is and fix examples in place. |
| `karpathy-guidelines` | agent-agnostic | Pure coding philosophy; no OC references. |
| `opencode-artefact-rules` | opencode-specific | Reviews OC artefacts; references OC type taxonomy, `opencode-reviewer` agent, `$draftpath`. |
| `opencode-crafter` | (deferred) | Analysis of internals deferred. Known: has extractable generic core + OC-specific wrapper. |
| `opencode-reflect-friction` | opencode-specific | Uses OC `task` tool + `task_id` subagent revival; references `opencode-crafter` ecosystem. |
| `opencode-test-runner` | opencode-specific | Tests OC artefacts; invoked by OC-specific agents only. Dry-run pattern is generic but context is inseparably OC. |
| `read-man-page` | agent-agnostic | `manq` local script; any agent with shell exec can use it. |
| `reflect-code-skills` | agent-agnostic | Post-session reflection + pattern extraction; no OC primitives. |
| `reflect-script-skills` (nested) | agent-agnostic | Same as parent; `write-script-*` refs are compositional, not OC-specific. |
| `write-code-bash` | agent-agnostic | Bash idioms + boilerplate; no OC primitives. |
| `write-code-bats` | agent-agnostic | Bats test conventions; no OC primitives. |
| `write-code-generic` | agent-agnostic | Language-agnostic coding conventions; no OC primitives. |
| `write-code-meta` | agent-agnostic | Rules for authoring `write-code-<lang>` skills; generic skill-library concept. |
| `write-code-nushell` | agent-agnostic | Nushell idioms; no OC primitives. |
| `write-github-issue` | agent-agnostic | Issue drafting methodology; depends only on `bew-communication-style` (also agnostic). |
| `write-spec` | agent-agnostic | Spec drafting methodology; uses `_WIP_SPECS/` file paths only. |
| `write-spec-noninteractive` | agent-agnostic | Explicitly designed for cross-tool use (Perplexity, ChatGPT). |
| `write-spec-noninteractive-standalone` | agent-agnostic | All instructions inlined for portability; most portable by design. |

### Agents

| Agent | Verdict | Key evidence |
|---|---|---|
| `explore-diff` | **has-generic-logic** | Core: diff-analysis algorithm, concern schema, output format — fully portable. OC wrapper: frontmatter (`mode: subagent`, permissions). Generic equivalent: "structured diff summarizer" system prompt. |
| `opencode-reviewer` | opencode-specific | Reviews OC artefacts; references `opencode-artefact-rules`, `opencode-simulated-test-runner`, `$draftpath`, OC taxonomy throughout. |
| `opencode-simulated-test-runner` | opencode-specific | Sole purpose: invoke `opencode-test-runner` skill + sandbox OC artefact drafts. |
| `opencode-skill-script-crafter` | **has-generic-logic** | Core: read spec → clarify → draft script → write bats tests → run → iterate. Generic "script-from-spec TDD loop". OC wrapper: `$draftpath`, `available_skills` refs, frontmatter. |

### Commands

| Command | Verdict | Key evidence |
|---|---|---|
| `diff-to-commits-drafts` | opencode-specific | 2-line dispatcher to named skill; zero standalone logic. |
| `draft-commit-message` | opencode-specific | Same — pure skill dispatcher shim. |
| `draft-pr-description` | **has-generic-logic** | Self-contained: embeds full workflow, style rules, output format inline. Only OC seams: `$ARGUMENTS` slot + `bew-communication-style` skill load. Generic equivalent: standalone "PR description drafter" system prompt. |
| `reflect-friction` | opencode-specific | Dispatches to `opencode-reflect-friction` skill; no extractable logic. |
| `retitle` | **has-generic-logic** | Title generation logic (≤80 chars, multi-subject disambiguation, subject rules) is self-contained. OC seam: `retitle_session` tool call from plugin. Generic equivalent: "session titler" prompt + any agent's rename action. |
| `why-you` | **has-generic-logic** | Response protocol (root-cause → suggestions, no apology) is fully behavioral. OC seam: `$ARGUMENTS` only. Generic equivalent: AGENTS.md instruction block, verbatim portable. |

### Plugins / Tools / Snippets

| Item | Type | Verdict | Key evidence |
|---|---|---|---|
| `plugins/retitle.ts` | plugin | opencode-specific | Uses `@opencode-ai/plugin` SDK (`Plugin`, `tool()`, `client.session.update()`). Concept is generic; implementation is 100% OC runtime. |
| `tools/git-track-new-file.ts` | tool | **split** | Logic (secret guard → `git check-ignore` → `git add -N` + symlink retry) is a self-contained shell utility. OC wrapper: `tool()`, `tool.schema`, `export default`, `@opencode-ai/plugin` registration. Generic equivalent: standalone bash function or post-write hook for any agent with hook support. |
| `snippets/*` | snippet | opencode-specific | Stored/retrieved by `opencode-snippets` plugin. Format + retrieval mechanism are OC-specific. |

### Analysis Summary

**Agent-agnostic (ready to move as-is):** `agent-blocker`, `agent-stuck`, `bew-communication-style`, `bew-inline-callout-style`, `caveman`, `caveman-review`, `gh-read-file`, `grill-me-full`, `grill-me-medium`, `grill-me-original`, `incremental-write` (move as-is, fix examples), `karpathy-guidelines`, `read-man-page`, `reflect-code-skills`, `reflect-script-skills`, `write-code-bash`, `write-code-bats`, `write-code-generic`, `write-code-meta`, `write-code-nushell`, `write-github-issue`, `write-spec`, `write-spec-noninteractive`, `write-spec-noninteractive-standalone`

**Split (extract generic core, keep OC wrapper):** `diff-to-commits-drafts`, `draft-commit-message`

**OC-specific (stay in `opencode-specific/`):** `git-track-new-file`, `opencode-artefact-rules`, `opencode-reflect-friction`, `opencode-test-runner`, `opencode-crafter` (deferred)

**Non-skill artefacts with generic logic → future `agent-agnostic/agents/`:** `explore-diff`, `opencode-skill-script-crafter` (generic versions to be authored separately)

**Non-skill artefacts with generic logic → future skills/prompts:** `draft-pr-description` command, `retitle` command, `why-you` command

**Fully OC-specific non-skill artefacts:** `opencode-reviewer` agent, `opencode-simulated-test-runner` agent, `diff-to-commits-drafts` command, `draft-commit-message` command, `reflect-friction` command, `plugins/retitle.ts`, `tools/git-track-new-file.ts`, `snippets/*`

### Resolved decisions from Analysis

1. `grill-me-original` frontmatter slug mismatch (`name: grill-me-minimal`) → **fix now**, before migration. SKILL.md updated separately.
2. `incremental-write` → **move as-is** to `agent-agnostic/`; clean up OC-specific trigger examples in-place when moving.
3. Generic equivalents of `explore-diff` and `opencode-skill-script-crafter` → **author as agents** in `agent-agnostic/agents/` (not skills).
4. `tools/git-track-new-file.ts` → **leave as OC tool** (`opencode-specific/tools/`). Pi-agent gets its own equivalent when needed.

## Related Files

No companion files yet.
`_WIP_SPECS/complex-skills-rework-v2/SPEC.md` is related — covers `opencode-crafter` internals rework, overlapping with the `generic-agentic-crafter` split.
