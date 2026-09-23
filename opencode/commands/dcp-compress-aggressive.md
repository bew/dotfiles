---
description: Aggressively shrink context by collapsing blocks into one lean summary
subtask: false # shared context!
---

Goal: aggressively shrink the context window.
Replace chosen context items with one lean summary, dropping their detail.

1. **Read** — read the active-block list from the latest system reminder
   (e.g. `Active compressed blocks: 3 (b7, b9, b10)`).
2. **Inventory** — inventory significant items only:
   - every compressed block (`bN`);
   - any large raw message (long tool output or multi-screen content).
   One line each: id + what it holds.
   Skip small individual messages.
   If no significant items: report "nothing to compress" and stop.
3. **Select** — ask via the `question` tool, one question per inventory item:
   choices drop, condense, or keep.
   Batch all items into a single call.
   If dismissed or empty: treat all items as keep and continue.
4. **Compress** — call `compress` over the ranges covering the chosen items.
   - To keep a block: leave its `(bN)` placeholder in the summary.
     To keep a raw message: leave it out of the range.
   - To drop an item: omit it from the summary.
     For a block that means omitting its `(bN)` placeholder.
   - To condense an item: write a short faithful paraphrase of it in the summary instead.
   In the summary, keep only still-actionable state:
   open tasks, uncommitted files, unacted decisions.
   If `compress` errors: report and stop.
5. **Report** — items dropped or condensed, new active-block count, messages saved.

WARNING: dropping or condensing discards the item's original content permanently.

## Focus hint

May be empty. If non-empty, weight toward what to preserve.

```
$ARGUMENTS
```
