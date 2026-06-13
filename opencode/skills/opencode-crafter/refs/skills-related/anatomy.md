# Skill Anatomy

Named directory containing `SKILL.md` entry point + optional supporting resources.

Official documentation: https://agentskills.io/specification


## Install paths

| Scope | Path | Notes |
|---|---|---|
| Project-scoped | `.agents/skills/<name>/` | Tool-agnostic; works with OpenCode, and other SKILL.md-compatible tools. **Preferred for team repos.** |
| Global (OpenCode only) | `~/.config/opencode/skills/<name>/` | Personal reusable skills not tied to a repo |

WARNING: Avoid `.opencode/skills/` for team repos — it locks the skill to OpenCode only.

NOTE: for global scope, the skills are found in `opencode/skills` in my `dotfiles` repo.
Use this relative path instead for edits if in the `dotfiles` repo.

## Directory layout

Directory with `SKILL.md` + optional resources.

```
<skill-name>/
│ (required entrypoint)
├── SKILL.md     ← describes the skill, when to use, what it does
│ (optional resources)
├── refs/        ← docs the agent reads during execution
├── scripts/     ← executable helpers the agent can run
├── assets/      ← static files used verbatim in output
└── templates/   ← scaffolds the agent fills in
```

## Phases

For complex skills with 3+ distinct concerns, structure workflow as named **phases** rather than a flat Steps list.
Phases enforce bounded context per stage, user checkpoints, and independent updateability.

Always read <`../rules-for-steps-phases-headers.md`> for naming rules, when named steps are required, phase gates, and optional phases.
If skill has phases: also read <`./skill-phases.md`> for SKILL.md structure and crafter integration.

## Progressive Disclosure
<!-- §progressive-disclosure -->

Skills load context in tiers — design content to match:

| Tier | What | When loaded |
|---|---|---|
| L1 | `description` frontmatter | Always — every session, to decide whether to trigger the skill |
| L2 | `SKILL.md` body | When skill is triggered for the current task |
| L3 | Additional files (e.g. in `refs/`) | On demand — agent reads only what it needs |

Keep in `SKILL.md` vs. extract to reference file:

| Criterion | Keep in SKILL.md | Extract to refs/ |
|---|---|---|
| Needed every time skill runs | Yes | No |
| Only needed in specific sub-scenarios | No | Yes |
| Body exceeds ~300 lines (prefer to extract) | No | Yes |
| Two concerns rarely needed together | No | Each in own file |

Common split: **create vs. update** — create instructions (type selection, scaffolding, gate checks)
irrelevant when updating. Extract create-only content; keep shared skeleton + update detection inline.

### Conditional instructions load

Reference files only work if agent knows *when* to read them.
Every reference must have explicit conditional trigger in `SKILL.md`.

Good — concrete & specific:
```md
Read <`./refs/forms.md`> before filling out any form field.
Read <`./refs/api-spec.md`> only when writing or modifying API calls.
```

Bad — agent cannot decide when to load:
```md
Read `./refs/extra-context.md` if you need more detail.
```

IMPORTANT: Always use angle-bracket syntax when referencing a skill-associated file: `<` + backtick-path + `>`.
Paths are relative to the file doing the referencing (filesystem-accurate).

TIP: If the trigger condition is "always", keep the content in `SKILL.md` instead.


## Frontmatter

```yaml
---
name: my-skill          # ^[a-z0-9]+(-[a-z0-9]+)*$ — directory name must match
description: |          # 1–1024 chars: what it does + WHEN to use it
  One or two sentences. Specific enough for the agent to decide whether to load it.
---
```

Optional fields (rarely needed for personal skills): `license`, `compatibility`, `metadata` (string → string map).


## Body sections

| Section | Required | Purpose |
|---|---|---|
| **Goal** | Yes | One sentence — what the agent must produce |
| **Steps** | Yes | Numbered sequential actions, one instruction each |
| **Rules** | Yes | Hard constraints: "must" / "always" / "never" |
| **Guidelines** | No | Soft recommendations: "prefer" / "avoid" |
| **Output format** | When applicable | Fenced example of the exact expected output |
| **Example** | Optional | Minimal end-to-end scenario when steps are ambiguous |

**Rules vs Guidelines**:

| | Rules | Guidelines |
|---|---|---|
| Language | "must", "never" | "prefer", "avoid", "when possible" |
| Violation | Always wrong | Agent may deviate with reason |
| Use for | Safety, correctness, preconditions | Style, efficiency, conventions |


## Loading behaviour

At startup, OpenCode reads only each skill's `name` and `description`.
Full body loaded into context only when agent calls the `skill` tool.
WARNING: A bloated skill wastes tokens for the entire duration of that task.
