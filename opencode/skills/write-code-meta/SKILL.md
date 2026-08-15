---
name: write-code-meta
description: |
  Rules for writing write-code-<lang> skills. Load BEFORE writing any content.
  Always load when asked to draft/write/edit/refactor/review any write-code-* skills.
  Triggers: "new write-code-X skill", "draft write-code-X", "add write-code-X",
  "update write-code-X", "write-code-python", "write-code-go", or any lang-specific code skill.
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
- The language has idioms that override or contradict generic conventions
  (e.g. no `function` keyword, different error signaling,
  structured data instead of string manipulation).
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

Four layers: generic SKILL.md → generic module/script-rules.md → lang SKILL.md → lang module/script-rules.md.

| Concern | Belongs in |
|---|---|
| Function naming, comments, constants, whitespace, type annotations | generic `SKILL.md` |
| Module/script distinction, conditional load instructions | generic `SKILL.md` |
| No top-level side effects, no `exit`, minimal public API | generic `module-rules.md` |
| Script entrypoint header, `main` entry point, no top-level logic | generic `script-rules.md` |
| Mutable globals, standard fn names, subcommand dispatch | generic `script-rules.md` |
| Error message actionability, script structure template | generic `script-rules.md` |
| Script testing workflow, dependency guard, section separators | generic `script-rules.md` |
| Lang-specific idioms, quoting, operators, syntax examples, universal param conventions | lang `SKILL.md` |
| How to identify module vs script in this language | lang `SKILL.md` |
| Conditional load (`module-rules.md` / `script-rules.md`) | lang `SKILL.md` |
| No shebang, no `exit`, sourcing/import conventions | lang `module-rules.md` |
| Shebang, strict-mode flags, lang boilerplate template | lang `script-rules.md` |

## Required structure for a lang skill

```md
---
name: write-code-<lang>
description: |
  <Lang> code writing guidelines: <2-3 key topics>.
  Always load when asked to draft/write/edit/refactor/review <lang> code files.
  Requires write-code-generic skill.
metadata:
  maintainers: [<github-user>]
---

## Goal

<One sentence: what this skill produces.>
Do not name required skills explicitly in the Goal sentence — they are listed on the REQUIRES line.
Use a short phrase like "building on generic conventions" or
"building on generic & language conventions".

REQUIRES: load `write-code-generic` skill first.

[Module/script identification paragraph: explain what module code and script code look like in
this language — observable signals (extension, shebang, entry guard). Then conditional loads:]

If working on **module code**: read <./module-rules.md>.
If working on **script code**: read <./script-rules.md>.

## Rules
[lang-specific hard rules only]

## Guidelines
[lang-specific soft recommendations — omit section if none]

## Testing
[name known testing system(s); load write-code-<testing-skill> when tests are wanted;
if no testing skill exists, say so and instruct agent to ask user]

## Section separators
[syntax only — the threshold rule (5+ functions) is owned by generic, do not restate it]
```

Required companion files (siblings of `SKILL.md`):
- `module-rules.md` — lang-specific module rules (extend `write-code-generic/module-rules.md`)
- `script-rules.md` — lang-specific script rules + complete copy-pasteable boilerplate template

Required additional section: `## Testing` — name the known testing system(s) for the language and
which skill to load for writing tests.
If no testing skill exists yet, say so explicitly and instruct the agent to ask the user.

Optional sections (add when relevant): `## Output capture`, `## Error handling`, `## Subcommands`.

## Description frontmatter requirements

The `description` field must:
- Name the language explicitly so the auto-trigger fires on file type or task context.
- Say "Always load when asked to draft/write/edit/refactor/review <lang> code files".

Bad (too vague, won't auto-trigger reliably):
> Script writing conventions for shell programs.

Good:
> Bash script writing guidelines: shebang, strict mode, bash idioms, and full boilerplate.
> Always load when asked to draft/write/edit/refactor/review bash code files.

## Rules

- Never restate a rule already in `write-code-generic` in a lang skill.
  If the rule is generic, it belongs in `write-code-generic` — move it there instead.
- Before placing a new rule in a lang skill, verify it is truly lang-specific.
  If unsure, ask: does this rule apply identically to a second unrelated language?
  If yes, it belongs in `write-code-generic`.
- Prose rules are allowed in lang skills only when genuinely lang-specific.
  When a lang skill adds a code example for a rule that already exists verbatim in `write-code-generic`,
  omit the prose restatement — the generic skill owns it.
  If the prose captures a lang-specific nuance not present in generic, keep it.
- Lang skills must not reference files from other skills by path (e.g. `write-code-generic/script-rules.md`).
  The module/script distinction in a lang skill must be described in lang-specific terms — signals
  observable in that language (file extension, shebang, entry guard). The agent infers which ref
  to load from that description.
- Companion ref files (`module-rules.md`, `script-rules.md`) are siblings of `SKILL.md`,
  not nested in a `refs/` subdirectory.
