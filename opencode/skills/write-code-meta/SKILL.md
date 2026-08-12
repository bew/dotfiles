---
name: write-code-meta
description: |
  Rules for writing write-code-<lang> skills.
  Always load whenever any write-code-* skill is going to be added/modified.
metadata:
  maintainers: [bew]
---

NOTE: This is a reference document, not a procedure.
Load it to look up rules, naming, and structure requirements — not to follow a sequence of steps.

## Goal

Produce a well-structured `write-code-<lang>` skill that correctly extends `write-code-generic`
without restating rules already in `write-code-generic`.

## When to create a new lang skill

Create a new `write-code-<lang>` skill when:
- The language has a distinct shebang, strict-mode equivalent, or safety flags.
- The language has idioms that override or contradict generic conventions (e.g. no `function` keyword,
  different error signaling, structured data instead of string manipulation).
- There is enough lang-specific boilerplate to justify a reusable template.

Extend `write-code-generic` instead when:
- The language follows generic conventions with only minor stylistic differences.
- The difference is a single rule or naming convention — add it to generic as a note.

## Examples

Refer to these existing skills as concrete examples of the pattern:
- `write-code-bash` — fully featured: strict mode, boilerplate, output capture, testing section
- `write-code-nushell` — minimal: core idioms only, typed params, native error model

## Naming

Skill directory and `name` frontmatter field must follow: `write-code-<lang>`.
`<lang>` is lowercase, hyphenated if needed (e.g. `write-code-bash`, `write-code-nushell`).

## Split contract: what belongs where

| Concern | Belongs in |
|---|---|
| Function decomposition, naming verbs, `main` entry point | `write-code-generic` |
| Function comments, local variable scoping | `write-code-generic` |
| Global variable naming (SCREAMING_SNAKE_CASE) | `write-code-generic` |
| Subcommand dispatch (`cmd_*` pattern) | `write-code-generic` |
| Error message actionability rules | `write-code-generic` |
| Script structure template (pseudo-code) | `write-code-generic` |
| Code examples for generic rules (no prose restatement) | lang skill |
| Shebang, strict-mode flags | lang skill |
| Language-specific conditionals, quoting, operators | lang skill |
| Full boilerplate template with real syntax | lang skill |
| Language-specific error signaling | lang skill |
| Language-specific idioms (pipelines, types, etc.) | lang skill |

## Required structure for a lang skill

```md
---
name: write-code-<lang>
description: |
  <Lang> code writing guidelines: <2-3 key topics>.
  Always load when writing or reviewing <lang> code files.
  Requires write-code-generic skill.
metadata:
  maintainers: [<github-user>]
---

## Goal

<One sentence: what this skill produces, referencing write-code-generic.>

REQUIRES: load `write-code-generic` skill first.

## Rules
[lang-specific hard rules only]

## Guidelines
[lang-specific soft recommendations — omit section if none]

## Full script boilerplate / Script structure
[complete, copy-pasteable template in the target language]

## Testing
[name known testing system(s); load write-code-<testing-skill> when tests are wanted;
if no testing skill exists, say so and instruct agent to ask user]

## Section separators
[syntax only — the threshold rule (5+ functions) is owned by generic, do not restate it]
```

Required additional section: `## Testing` — name the known testing system(s) for the language and
which skill to load for writing tests.
If no testing skill exists yet, say so explicitly and instruct the agent to ask the user.

Optional sections (add when relevant): `## Output capture`, `## Error handling`, `## Subcommands`.

## Description frontmatter requirements

The `description` field must:
- Name the language explicitly so the auto-trigger fires on file type or task context.
- Say "Always load when writing or reviewing <lang> scripts" (or `.bats` / `.nu` etc.).
- Mention that it requires `write-code-generic`.

Bad (too vague, won't auto-trigger reliably):
> Script writing conventions for shell programs.

Good:
> Bash script writing guidelines: shebang, strict mode, bash idioms, and full boilerplate.
> Always load when writing or reviewing bash scripts.
> Requires write-code-generic skill.

## Rules

- Never restate a rule already in `write-code-generic` in a lang skill.
  If the rule is generic, it belongs in `write-code-generic` — move it there instead.
- Before placing a new rule in a lang skill, verify it is truly lang-specific.
  If unsure, ask: does this rule apply identically to a second unrelated language?
  If yes, it belongs in `write-code-generic`.
- Prose rules are allowed in lang skills only when genuinely lang-specific.
  When a lang skill adds a code example for a generic rule, omit the prose — the generic skill owns it.
