# Writing Style for OpenCode Artefacts

Apply to all SKILL.md, agent, command, & prompt files.

## Caveman mode

Artefact bodies (SKILL.md, agent prompts, command templates) must follow caveman-mode discipline:
Use `caveman` skill to cut every word that adds no information.
Applies to artefact content & agent-to-user comms during crafting process.

## Tone

Brief a capable engineer who executes instructions exactly as written.

- **Imperative.** "Run `git status`." Not "You should run…"
- **Terse.** One idea per sentence. No filler. See **Caveman mode** above.
- IMPORTANT: One sentence per line. Never pack multiple sentences on one line (unless each sentence is very short, few words only).
- **Concrete.** Name real paths, commands, field names. No abstract placeholders unless genuinely variable.
- **Neutral.** Cut: "usually", "typically", "generally", "feel free to", "in most cases".

## Formatting

- `##` for top-level sections, `###` for subsections. No deeper nesting.
- Numbered lists for ordered steps. Bullets for unordered rules/options.
- Inline code for all commands, paths, field names, values.
- Fenced code blocks with language tag for multi-line content.
  Use short language tag like `md` or `py`.
- Tables for comparisons with 3+ items & 2+ dimensions.
- Bold for terms being defined or critical warnings only.
- No emojis.
- Line length:
  For prose: 100 chars.
  For code blocks & examples: line length follows content.

### Guidelines for examples

- Prose examples (utterances, natural language outputs): use blockquote (`> ...`). Line length unconstrained.
  > Write a skill that monitors my inbox and summarizes unread threads every morning at 9am
- All other examples (commands, config, file content, structured output): fenced code block with language tag. Line length follows language's own conventions.
- **Short labeled pairs** (`Not:`/`Yes:`, `Bad:`/`Good:`, `Q:`/`A:`): inline form allowed when each side fits on one line.

### Callout blocks

Load `bew-inline-callout-style` skill for full spec & examples (reference-only, not auto-loaded).

Use `NOTE:`, `IMPORTANT:`, `WARNING:`, `TIP:` prefixes for inline callouts.
Same-paragraph lines are attached; blank line ends callout.
Parenthesized form `(KEYWORD: ...)` must be one line; may appear inline in another paragraph.

## Length

| Artefact | Target |
|---|---|
| Skill (simple) | 30–80 lines |
| Skill (medium) | 80–200 lines |
| Skill (complex) | 200–400 lines |
| Agent prompt | 50–200 lines |
| Command template | 5–50 lines |

Prefer to split to `references/` when skill body exceeds ~300 lines.
Must split when skill body exceeds 400 lines.
