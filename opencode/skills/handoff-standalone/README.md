# handoff-standalone

Self-contained export of `handoff`, for ad-hoc loading into tool-less chat contexts.
All instructions inlined — no external files.

Source: `handoff` at `./opencode/skills/`.

## Differences from `handoff`

| | `handoff` | `handoff-standalone` |
|---|---|---|
| File structure | `SKILL.md` + `refs/` | Single `SKILL.md` |
| Variant marker | none | `VARIANT` (`Variant type: standalone`) |
| Progressive disclosure | Loads refs on demand | All content inline |
| Interactive loop | Phase gates | None |
| Output | Writes `HANDOFF-*.md` to disk | Writes to a local file when possible, else emits inline |
| Companion command | `/handoff` | None |
| Skill refs | `load \`foo\` skill` | Plain recommendations |
| Doc preamble | none | Tool-access notice |