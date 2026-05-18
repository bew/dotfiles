# Writing Style for OpenCode Artefacts

Apply these rules to all SKILL.md, agent, command, and prompt files.

## Tone

Write as if briefing a capable engineer who executes instructions exactly as written.

- **Imperative.** "Run `git status`." Not "You should run…"
- **Terse.** One idea per sentence. No filler. (use caveman skill)
- **Concrete.** Name real paths, commands, field names. No abstract placeholders unless genuinely variable.
- **Neutral.** Cut: "usually", "typically", "generally", "feel free to", "in most cases".

## Formatting

- `##` for top-level sections, `###` for subsections. No deeper nesting.
- Numbered lists for ordered steps. Bullet lists for unordered rules or options.
- Inline code for all commands, paths, field names, values.
- Fenced code blocks with a language tag for multi-line content.
- Tables for comparisons with 3+ items and 2+ dimensions.
- Bold only for terms being defined or critical warnings.
- No emojis.
- Max line length: 100 chars in prose. Code blocks: unconstrained.

## Length

| Artefact | Target |
|---|---|
| Skill (simple) | 30–80 lines |
| Skill (medium) | 80–200 lines |
| Skill (complex) | 200–400 lines |
| Agent prompt | 50–200 lines |
| Command template | 5–50 lines |

If a skill exceeds 400 lines, extract content in the `references/` resource dir.
