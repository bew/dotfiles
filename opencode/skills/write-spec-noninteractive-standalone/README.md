# write-spec-noninteractive-standalone

Fully self-contained variant of `write-spec-noninteractive`.
All instructions are inlined in a single `SKILL.md` — no `refs/` directory required.
Intended for import into external tools (Perplexity, ChatGPT, raw prompt injection)
where only a single file can be provided.

## Key differences from `write-spec-noninteractive`

| | `write-spec-noninteractive` | `write-spec-noninteractive-standalone` |
|---|---|---|
| File structure | `SKILL.md` + `refs/` | Single `SKILL.md` only |
| Progressive disclosure | Loads refs on demand | All content always present |
| Token cost | Lower (refs loaded lazily) | Higher (all content inline) |

## Key differences from `write-spec`

| | `write-spec` | `write-spec-noninteractive-standalone` |
|---|---|---|
| Checkpoints | Phase gates between each stage | None — single pass, no pausing |
| Questions | Asked live at each phase | Batched in `## Questions for you` at end |
| Spec lifecycle | Promotes `DRAFT` → `MAYBE-READY` → `READY` via rename script | `DRAFT` only; `READY`/`ABANDONED` set manually by user |
| Scope detection | Pauses mid-draft if new scope appears | Surfaces conflicts in deferred questions |
| Modes | Create only | Create and Update |

## What stays the same

- Spec structure, section order, prose style rules
- Open Questions format (Blocking / Non-blocking)
- Alternatives & Tradeoffs conventions
- Readiness criteria (criteria 1–6 assessed; criterion 7 always deferred)
