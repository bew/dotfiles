---
created-at: 20261109T2307
---

# Fork DCP plugin and add block-replacement support

Add a supported replace operation to a fork of the DCP plugin.
Goal: replace an existing compression block's summary without keeping the old text in active context or rebuilding coverage by hand.

Current `compress` path only creates a successor block.
When the range is a block, it preserves the old summary and appends the new text.
Direct edits to the DCP state JSON are overwritten by the live process, which saves from memory.

Observed: block 29 held 173,028 chars / 46,778 tokens over 748 messages and 913 tools.
`compress` on it created block 32 with 173,237 chars / 46,829 tokens and `consumedBlockIds` / `includedBlockIds` `[29]`.
The old summary was still present before the appended note.
A manual replacement block also needs its id added to `allBlockIds` for every covered message plus consistent active maps, or `syncCompressionBlocks` deactivates it and the old messages reappear.

## Design decisions

- Replacement unit: one whole block.
- Replacing a covered child means replacing its parent.
- Nesting only within one semantic group, identified by a stable slug `groupId`.
- A parent cannot consume a block from another group; enforce this structurally.
- A parent summary distills its children; it never concatenates them.
- A parent replacement keeps its children inactive as provenance.
- `summaryTokens` is recomputed from the replacement summary with the plugin tokenizer.
- Replacement updates the live in-memory state, then persists; no session restart.
- The previous summary is kept in block history, not in active context.
- `compress` stays additive; replacement is a separate operation.
- Block creation accepts disjoint message ranges, so an unrelated block sitting in the middle of a larger task does not prevent compressing the whole task.

## Blockers

- Live DCP state is in memory; the fork needs an in-memory replacement API.
- Need the fork point and the exact `compress` path that writes block state.
- Need to add `groupId` to the block schema and validate `consumedBlockIds`.

## Open questions

- How should `compressedTokens` be recomputed or retained on replacement?
- How to migrate existing blocks that have no `groupId`?
- How to choose semantic group boundaries in practice?
- Should `groupId` be visible in the tooltip or compression commands?
- On a disjoint range, does the skipped block stay active as its own unit, or must the parent consume it too?

## Artefacts

- `~/.local/share/opencode/storage/plugin/dcp/ses_e3f61dd3efferBIt6E1FSlI0jM.json` — session state holding the b29/b32 evidence.
- `https://raw.githubusercontent.com/Opencode-DCP/opencode-dynamic-context-pruning/master/lib/messages/sync.ts` — `syncCompressionBlocks` rebuilds active ids from `compressMessageId` and `allBlockIds`.
- `commands/dcp-compress-aggressive.md` — inspect before changing the aggressive compression flow; intentionally not read during capture.
