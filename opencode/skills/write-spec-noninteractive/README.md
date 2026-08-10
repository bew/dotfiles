# write-spec-noninteractive

Non-interactive variant of `write-spec`, designed for tools without interactive loops
(Perplexity, ChatGPT, one-shot LLM prompts).

## Key differences from `write-spec`

| | `write-spec` | `write-spec-noninteractive` |
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
