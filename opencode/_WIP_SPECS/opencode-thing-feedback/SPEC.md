# [DRAFT] oc-feedback

## Introduction

During agentic sessions, an agent may trigger the wrong skill, misapply an instruction, or silently skip a rule that should have applied.
The only way to improve that over time is to capture what went wrong — concisely, structurally, and close to when it happened.

`oc-feedback` is a tool that writes a structured feedback entry for any OpenCode artefact.
It covers skills, commands, agents, snippets, plugins, and global instruction files (e.g. `AGENTS.md`).
It is available as a `/command` for user invocation and as an agent auto-use rule so the agent can write feedback on its own when it detects a mis-trigger or mis-application.

Each feedback entry is stored as a Markdown file alongside the artefact it targets, inside a `feedbacks/` subdirectory.
Co-location keeps feedback easy to find and consult when editing or reviewing the artefact.

**Use-cases:**
- Agent fires the wrong skill → agent writes feedback noting the mis-trigger and suggests a tighter description.
- User notices an instruction was over-applied → user invokes `/oc-feedback` to log a correction hint.
- Post-session review: scan `feedbacks/` directories to find recurring patterns before rewriting an artefact.

## Terminology

**Artefact** (new!): any named OpenCode configuration object that can receive feedback.
Covers: skill, command, agent, snippet, plugin, and global instruction file (e.g. `AGENTS.md`).

**Artefact path** (new!): the filesystem path used to locate an artefact.
For directory-based artefacts (skills, plugins, directory-form snippets), this is the artefact's root directory.
For file-based artefacts (commands, agents, file-form snippets, global instruction files), this is the file itself.

**Feedback entry** (new!): a single Markdown file capturing one incident of misuse, mis-trigger, or missing rule for a specific artefact.
Named `<slug>.md` where `<slug>` is a short kebab-case label supplied by the caller.

**Feedbacks directory** (new!): a `feedbacks/` subdirectory that holds all feedback entries for an artefact.
Its location depends on artefact type — see **Artefact Types & Storage Paths**.

**Feedback author** (new!): the originator of a feedback entry — either `agent` (written autonomously during a session) or `user` (invoked manually via `/oc-feedback`).
Recorded in the feedback file front-matter.

**Slug** (well-known): short kebab-case identifier.
Used both as the argument passed to the tool and as the filename of the resulting feedback entry.

## Command Interface

### Invocation

```
/oc-feedback <artefact-name> <slug> <feedback-text> [--path <artefact-path>]
```

| Argument         | Required | Description                                                                                   |
|------------------|----------|-----------------------------------------------------------------------------------------------|
| `artefact-name`  | yes      | Name of the artefact (e.g. `write-spec`, `oc-feedback`, `AGENTS.md`)                         |
| `slug`           | yes      | Short kebab-case label for this feedback entry (e.g. `wrong-trigger`, `over-applied-rule`)   |
| `feedback-text`  | yes      | Full feedback body as a string; must follow the structure defined in **Feedback File Format** |
| `--path`         | no       | Explicit artefact path; used as fallback when auto-discovery is not possible                  |

### Path resolution

The command attempts to resolve the artefact path in this order:
1. `--path` if provided — use directly, skip all discovery.
2. OpenCode plugin SDK artefact lookup (if available at implementation time).
3. If neither resolves: fail with a clear error asking the caller to supply `--path`.

NOTE: Whether the SDK exposes a usable artefact-name → path lookup is unknown at spec time.
See **Open Questions** §1.

### Output

On success: print the path of the written feedback entry.
On failure: print a clear error (artefact not found, path not writable, slug already exists) and exit non-zero.

## Feedback File Format

Each feedback entry is a Markdown file with YAML front-matter followed by three required body sections.

### Example

```markdown
---
artefact: write-spec
slug: fired-without-user-ask
author: agent
date: 2026-06-13
---

**Context**: User asked to draft a PR description.
Agent loaded `write-spec` skill automatically without user requesting a spec.

**Root cause** — Skill description did not exclude prose writing tasks.
The trigger condition "draft … document" matched "draft a PR description" too broadly,
causing the skill to load when only `bew-communication-style` was relevant.

**Suggestions**
- Narrow trigger: add "for a system, API, or subsystem" explicitly to the description
  so prose tasks without a technical design component don't match.
- Add a negative example to the skill description: "NOT for prose, PR descriptions, or emails."
```

### Front-matter fields

| Field      | Type   | Description                                                   |
|------------|--------|---------------------------------------------------------------|
| `artefact` | string | Name of the artefact this feedback targets                    |
| `slug`     | string | Kebab-case slug — must match the filename (without `.md`)     |
| `author`   | string | `agent` or `user`                                             |
| `date`     | string | ISO 8601 date (`YYYY-MM-DD`), set to today at write time      |

### Body sections (required, in order)

**Context** — 1–2 lines.
What happened; what the agent or user did or failed to do.

**Root cause** — one sentence naming the cause (misread of instructions, bad assumption, rule over-applied, priority gap, …), followed by 1–2 sentences explaining how it led to the outcome.

**Suggestions** — 1–2 concrete, actionable suggestions to improve the artefact's description, trigger condition, or instructions so the situation does not recur.

NOTE: Sections use Markdown bold headers (`**Section**`), not `##` headings, to keep entries lightweight and scannable inline.

## Artefact Types & Storage Paths

| Artefact type      | Form        | Example artefact path              | Feedbacks directory                       |
|--------------------|-------------|------------------------------------|-------------------------------------------|
| skill              | directory   | `skills/my-skill/`                 | `skills/my-skill/feedbacks/`              |
| plugin             | directory   | `plugins/my-plugin/`               | `plugins/my-plugin/feedbacks/`            |
| snippet (dir form) | directory   | `snippet/my-snip/`                 | `snippet/my-snip/feedbacks/`              |
| command            | file        | `commands/my-cmd.md`               | `commands/feedbacks/`                     |
| agent              | file        | `agents/my-agent.md`               | `agents/feedbacks/`                       |
| snippet (file form)| file        | `snippets/my-snip.md`              | `snippets/feedbacks/`                     |
| global instruction | file        | `AGENTS.md`                        | `feedbacks/` (sibling to the file)        |

**Rule for directory-form artefacts**: feedbacks directory is `<artefact-root>/feedbacks/`.

**Rule for file-form artefacts**: feedbacks directory is `<parent-dir>/feedbacks/` (shared across all file-form artefacts in that directory).

NOTE: For file-form artefacts, feedback entries from different artefacts share one `feedbacks/` directory.
The `artefact` front-matter field disambiguates which artefact each entry targets.

The feedback entry filename is `<slug>.md` within the feedbacks directory.

## Agent Auto-Use

The agent must call `/oc-feedback` (or write the feedback entry directly via file tools) whenever it detects it made an artefact-related mistake.
Writing feedback is corrective behavior, not optional.

### Trigger conditions

- Agent loaded a skill that was not the right one for the task.
- Agent skipped a skill it should have loaded.
- Agent applied an instruction rule too broadly or too narrowly.
- Agent repeated a mistake that an existing skill or instruction was meant to prevent.
- User explicitly points out a mis-trigger or mis-application of an artefact.

### Agent procedure

1. Identify the artefact involved and resolve its path (via SDK, or from prior context such as the skill's known install path).
2. Compose the feedback body following **Feedback File Format**: Context → Root cause → Suggestions.
3. Choose a slug that names the failure pattern (e.g. `wrong-trigger`, `over-applied-rule`, `skipped-skill`).
4. Call `/oc-feedback <name> <slug> <body>` or write the file directly to the feedbacks directory.
5. Inform the user: "Wrote feedback to `<feedbacks-path>/<slug>.md`."

### Not triggered by

- General task mistakes unrelated to artefacts (wrong code output, bad suggestions, etc.).
- First attempt at a task where no artefact guidance exists yet.

## Alternatives & Tradeoffs

### Simplest alternative: edit the artefact directly

When a problem is noticed, the agent or user edits the skill/command/agent file in place.

```
# No tooling — just open skills/my-skill/SKILL.md and fix the description.
```

**Advantages of direct editing:**
- No extra tooling or file format.
- Fix is immediately live.

**Advantages of `oc-feedback`:**
- Non-destructive — records what happened without altering the artefact.
  Useful when the diagnosis may be wrong, or when the agent is mid-task and should not change config.
- Accumulates a history of incidents across sessions, enabling pattern-based rewrites.
- Works without interrupting the current task.

**Costs of `oc-feedback`:**
- Adds a file format and a tool to maintain.
- Feedback entries are inert until someone acts on them; they do not self-apply.

**Heuristic:**
- Certain, small, immediate fix → edit artefact directly.
- Uncertain diagnosis, first occurrence, or mid-task → write feedback, fix later.
- Recurring pattern across sessions → read accumulated feedback entries, then rewrite artefact.

<!-- NOTE: Naming & IDs — omitted: no named/anonymous object pattern; file naming convention is covered in Feedback File Format -->
<!-- NOTE: Placement / Scope — omitted: storage paths fully covered in Artefact Types & Storage Paths -->
<!-- NOTE: Related files — omitted: no companion files at this stage -->

## Open Questions

1. **Artefact path auto-discovery via OC plugin SDK.**
   Blocking.
   Unknown at spec time whether the plugin SDK exposes a lookup API that maps artefact name → filesystem path.
   If it does not, the fallback is: agent supplies `--path` from its known context (the path the skill/command was loaded from).
   Implementation must probe this first before deciding whether `--path` is truly optional.

2. **Command implementation approach: shell script vs JS plugin command.**
   Non-blocking; depends on resolution of OQ #1.
   A shell script command can write the file with standard POSIX tools.
   A JS plugin command could use the SDK for path discovery but adds a build step.

3. **Slug collision handling.**
   Non-blocking.
   If `feedbacks/<slug>.md` already exists: overwrite, append, or fail?
   Current assumption: fail with a clear error — forces the caller to choose an explicit slug.
   An `--overwrite` flag can be added at implementation time if needed.

4. **Global instruction files as artefacts.**
   Non-blocking.
   Files like `AGENTS.md` are not registered artefacts in the SDK sense.
   Storage path is unambiguous (sibling `feedbacks/` dir), but the `artefact` front-matter value needs a convention
   (e.g. `AGENTS.md` literal vs. a symbolic name like `global-instructions`).
   Recommendation: use the filename literally (e.g. `artefact: AGENTS.md`) until a better convention emerges.
