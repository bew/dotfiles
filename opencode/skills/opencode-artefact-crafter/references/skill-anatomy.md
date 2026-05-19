# Skill Anatomy

A skill is a named directory containing a `SKILL.md` entry point and optional supporting resources.

Official documentation: https://agentskills.io/specification


## Install paths

| Scope | Path | Notes |
|---|---|---|
| Project-scoped | `.agents/skills/<name>/` | Tool-agnostic; works with OpenCode, Copilot Workspace, and other SKILL.md-compatible tools. **Preferred for team repos.** |
| Global (OpenCode only) | `~/.config/opencode/skills/<name>/` | Personal reusable skills not tied to a repo |

WARNING: Avoid `.opencode/skills/` for team repos — it locks the skill to OpenCode only.


## Directory layout

A skill is defined as a directory with a `SKILL.md`, with optional resources that the skill can
reference.

```
<skill-name>/
│ (required entrypoint)
├── SKILL.md     ← describes the skill, when to use, what it does
│ (optional resources)
├── references/  ← docs the agent reads during execution
├── scripts/     ← executable helpers the agent can run
├── assets/      ← static files used verbatim in output
└── templates/   ← scaffolds the agent fills in
```

TIP: Only add resource directories when `SKILL.md` would exceed ~300 lines, or when a resource is cleaner as a standalone file.

Reference supporting files explicitly from `SKILL.md`:
```markdown
Read `./references/api-spec.md` before writing any API calls.
Run `./scripts/validate.sh` before committing the output.
```
IMPORTANT: Always use `./` prefix when referencing a skill-associated file.


## Frontmatter

```yaml
---
name: my-skill          # ^[a-z0-9]+(-[a-z0-9]+)*$ — directory name must match
description: |          # 1–1024 chars: what it does + WHEN to use it
  One or two sentences. Specific enough for the agent to decide whether to load it.
---
```

Optional fields, rarely needed for personal skills: `license`, `compatibility`, `metadata` (string → string map).


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
The full body is loaded into context only when the agent calls the `skill` tool.
WARNING: A bloated skill wastes tokens for the entire duration of that task.
