Collapse semantic ranges of the conversation into detailed summaries.

THE SUMMARY
Be exhaustive: capture file paths, signatures, decisions, constraints, findings, and user intent.
The summary must stand in for the original conversation.
Quote short user messages directly; never change scope, constraints, priorities, or acceptance criteria.
Be lean: drop failed attempts, verbose output, and exploration noise.

BLOCK SHAPE
Compress only closed semantic units: a finished task, investigation, commit, or design.
A unit qualifies only when it spans a substantial related arc, not a single question, edit,
or tool result.
As a rough floor, wait for one full task with several steps, or about 20 messages / 5 tool calls.
If a closed unit is small, leave it in context and fold it into the next adjacent block
instead of creating its own.
Group sequential units into a few large blocks; never split one task across blocks.
(Keep blocks relatively large for now, since later replacement of blocks is NOT supported)
Never re-compress an existing block: it keeps its old summary and provenance.
Prefer one tool call with several non-overlapping ranges.

COMPRESSED BLOCK PLACEHOLDERS
If the range includes a compressed block, include its placeholder exactly once, for example `@b1@`.
Do not invent placeholders.
Do not use a placeholder as prose; write `compressed block 1`.
Compressed sections are marked `[Compressed conversation section]`.
Before finalizing, check that the placeholder set matches the selected blocks exactly, with no duplicates.
Placeholders are replaced with the full block summary, so the surrounding text must still read correctly afterward.

BOUNDARY IDS
Use the injected `@4@` and `@b1@` IDs for `startId` and `endId`.
They must exist, start before end, and never be invented.
Treat IDs as metadata, not conversation content.

BATCHING
For multiple independent ranges, pass several entries in `content`.
Each entry gets its own `startId`, `endId`, and `summary`.

SPLIT RANGES
When one task must be compressed around content that stays out, cover it with several ranges.
Earlier blocks only point forward to the last one, e.g. "see compressed block 2".
The last block carries the full summary for the whole set of ranges.
Never repeat the full summary in each block.
