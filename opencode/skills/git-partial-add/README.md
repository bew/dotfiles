# git-partial-add

OpenCode skill for staging specific hunks or partial hunks from a diff, without
interactive input (`git add -p` requires a tty; this works in agent context).

## Goal

Give an agent the ability to stage exactly the changes that belong together —
whole hunks, parts of hunks, or even a modified version of a line — leaving
everything else unstaged.

## Modes

**Easy mode** — agent constructs and applies patch fragments directly.
Covers whole-hunk staging/skipping and simple line exclusions.

**Granular mode** — agent uses `scripts/patch_hunk.py` for sub-line content
overrides (stage a different version of a line than what's in the working tree)
and complex rewrites.

## Files

```
SKILL.md                         skill entry point (easy + granular mode steps)
scripts/patch_hunk.py            patch rewriter — see references/patch_hunk_spec.md
references/patch_hunk_spec.md    full spec: instruction format, actions, edge cases, test fixtures
WIP.md                           known gaps and TODO items
```

## Current status

**Working (tested):**
- Easy mode: whole-hunk stage / skip / partial exclusion
- Granular mode: `stage`, `skip`, `partial`, `override staging`
- Multi-hunk selective apply via `git apply --cached`
- No-op hunk detection (pure-context hunks silently dropped)

**Not yet implemented / stub:**
- `override staged` modifier (fix already-staged content) — stub only
- `new_start` drift correction for multi-hunk rewrites with net delta
- `--intent-to-add` warning for new-file hunks
- Unit test suite (examples block in script documents the cases)

See `WIP.md` for details.

## Alternatives

[**git-surgeon**](https://github.com/raine/git-surgeon) — "Git primitives for autonomous
coding agents." Purpose-built for agent workflows; worth evaluating as a replacement or
complement to this skill.

Open question: whether git-surgeon will support sub-line (character-level) staging —
tracked in [raine/git-surgeon#4](https://github.com/raine/git-surgeon/issues/4).
If it does, granular mode's `override` action may become redundant.
