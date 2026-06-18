---
name: write-script-meta
description: |
  Rules for drafting a new write-script-<lang> skill.
  Load when creating or updating any write-script-* language-specific skill.
metadata:
  maintainers: [bew]
---

NOTE: This is a reference document, not a procedure.
Load it to look up rules, naming, and structure requirements — not to follow a sequence of steps.

## Goal

Produce a well-structured `write-script-<lang>` skill that correctly extends `write-script-generic`
without restating rules already in `write-script-generic`.

## When to create a new lang skill

Create a new `write-script-<lang>` skill when:
- The language has a distinct shebang, strict-mode equivalent, or safety flags.
- The language has idioms that override or contradict generic conventions (e.g. no `function` keyword,
  different error signaling, structured data instead of string manipulation).
- There is enough lang-specific boilerplate to justify a reusable template.

Extend `write-script-generic` instead when:
- The language follows generic conventions with only minor stylistic differences.
- The difference is a single rule or naming convention — add it to generic as a note.

## Examples

Refer to these existing skills as concrete examples of the pattern:
- `write-script-bash` — fully featured: strict mode, boilerplate, output capture, testing section
- `write-script-nushell` — minimal: core idioms only, typed params, native error model

## Naming

Skill directory and `name` frontmatter field must follow: `write-script-<lang>`.
`<lang>` is lowercase, hyphenated if needed (e.g. `write-script-bash`, `write-script-nushell`).

## Split contract: what belongs where

| Concern | Belongs in |
|---|---|
| Function decomposition, naming verbs, `main` entry point | `write-script-generic` |
| Function comments, local variable scoping | `write-script-generic` |
| Global variable naming (SCREAMING_SNAKE_CASE) | `write-script-generic` |
| Subcommand dispatch (`cmd_*` pattern) | `write-script-generic` |
| Error message actionability rules | `write-script-generic` |
| Script structure template (pseudo-code) | `write-script-generic` |
| Shebang, strict-mode flags | lang skill |
| Language-specific conditionals, quoting, operators | lang skill |
| Full boilerplate template with real syntax | lang skill |
| Language-specific error signaling | lang skill |
| Language-specific idioms (pipelines, types, etc.) | lang skill |

## Required structure for a lang skill

```md
---
name: write-script-<lang>
description: |
  <Lang> script writing guidelines: <2-3 key topics>.
  Auto-load when writing or reviewing <lang> scripts.
  Loads write-script-generic for language-agnostic rules.
metadata:
  maintainers: [<github-user>]
---

## Goal

<One sentence: what this skill produces, referencing write-script-generic.>

NOTE: Load `write-script-generic` skill first — it defines the shared structure,
naming conventions, and error-handling rules this skill builds on.

## Rules
[lang-specific hard rules only]

## Guidelines
[lang-specific soft recommendations — omit section if none]

## Full script boilerplate / Script structure
[complete, copy-pasteable template in the target language]

## Testing
[name known testing system(s); load write-script-<testing-skill> when tests are wanted;
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
- Say "Auto-load when writing or reviewing <lang> scripts" (or `.bats` / `.nu` etc.).
- Mention that it loads `write-script-generic`.

Bad (too vague, won't auto-trigger reliably):
> Script writing conventions for shell programs.

Good:
> Bash script writing guidelines: shebang, strict mode, bash idioms, and full boilerplate.
> Auto-load when writing or reviewing bash scripts.
> Loads write-script-generic for language-agnostic rules.

## Rules

- Never restate a rule already in `write-script-generic` in a lang skill.
  If the rule is generic, it belongs in `write-script-generic` — move it there instead.
- Prose rules are allowed in lang skills when they are genuinely lang-specific.
  When a lang skill adds a code example for a generic rule, omit the prose — the generic skill owns it.
