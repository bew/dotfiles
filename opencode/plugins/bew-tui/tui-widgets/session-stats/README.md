# session stats

## Purpose
The widget that counts turns and tool calls for the whole session and for the model's active context; `tui.tsx` renders it one line above the prompt in the session composer header.
The line reads `Sess: 󰍩 12 󱜾 30 󰒔 118 · Ctx: 󰍩 3 󱜾 9 󰒔 31`: `󰍩` counts user messages, `󱜾` assistant messages, and `󰒔` tools, with bookkeeping entries ignored.
`Sess:` covers the whole conversation and `Ctx:` the part still in the model's active context.
While compression has removed nothing the two counts agree, so the line merges them into `Sess/Ctx: 󰍩 12 󱜾 30 󰒔 118 · ctx info`: the merged group opens the session tooltip and `ctx info` the context one, so both stay reachable.
Once they differ, each count gets its own group, and each still opens its own tooltip.

## Responsibilities
- The counts line: user, assistant and tool counts per group, each kind behind its own glyph.
- DCP awareness: the context group subtracts whatever the active compression blocks cover, so it shows what the model still sees.
- The tooltip: clicking a group opens it, clicking the other replaces it, and clicking again or the close glyph closes it; leaving the session hides it and coming back to it shows it again, each session keeping whatever it had open.
- What the tooltip reports: each group's general section, the active context's content and last turn, the activity counts, the subagent sessions, and the compression blocks.
- The `tokens` row: the context the model holds now, summed the way the built-in counter does — prompt, completion, reasoning, and both cache directions of the latest assistant step — with the session's input, output and cache traffic as its detail line.
- The active context's general section: the `tokens` row with the used and total window and the session's thinking, then the `last turn` row with its details, then a `last step` row for the step whose provider report fills the window — how long it streamed and its pace, with its uncached `input`, its `output`, its `cache` traffic and its cache-hit share as details. The window rows are omitted when the model's limit is unknown, but the last-turn and last-step rows stay.
- The content section: a first `system` row for the selected agent's system prompt (one prompt, so no message count), then an `available: …` detail line counting the skills, agents and MCP servers the location offers; hidden agents are left out, since the model cannot discover them. Then the user, assistant and tools entries still in context, each with its entry count, an approximate token count and share of the window marked `~`, and its exact word count as a note. When the selected agent does not expose its prompt, the row says `prompt not exposed`. An `other` row covers persisted system notices, agent switches and idle records, with a detail line splitting those parts.
- The `last turn` row under the active context's general section: the steps since the latest user message, the turn's wall time, its cost with the subagent total when any ran during it, and its output and thinking tokens.
- The `last step` row: how long the step whose report fills the window streamed and how fast, marked `~`, with that step's uncached input, its completion and its cache traffic as a detail line — together they are the window figure the `tokens` row reports. The detail line appears whenever a step reports tokens, with or without a known window limit; the duration and pace need the provider's streaming marks, so a step still in flight leaves the row unlabelled.
- Cache-hit detail lines: the share of prompt tokens served from the provider's cache, reported as `avg cache hit` for the session totals and as `cache hit` under `last step`.
- The `thinking` detail line, in both window groups: reasoning the session generated, with how much of it remains in the active context in parentheses; omitted when the session reported none.
- The `timings` row: the busy time with its share of the wall time in parentheses, then the idle time; the busy part is split into generating and tools; a question tool's answer wait counts as idle.
- The tooltip text: selectable, so the figures can be copied out of the panel.
- A long subagent list: past a handful of sessions it trims to the dearest few and the most recent few, each group under its own label; a long agent name is cut so the columns stay aligned.

## Architecture
The line is reactive: a memo reads the host's message store together with the latest compression state, so a new message or a new compression redraws it.
The tooltip is built on demand instead, and rebuilt on each compression revision while it is open.
An open tooltip lives in the app slot, which outlives the composer it was opened from: each session's target is remembered while another session or route is viewed, and only the one belonging to the session on screen is drawn.
The panel anchors on whichever element is currently drawn for the group, which the counts line records on mount, so a remounted composer still places it.
Both need the whole transcript, but the store holds only a recent window, so the widget syncs it and then pages the remainder through whatever paging methods the store exposes.

The compression state comes from DCP's per-session state file: the widget reads the blocks that are active, subtracts the messages and tools they cover, and watches the file's directory, because DCP rewrites it in place.
The watch's revision drives both the counts and an open tooltip.
A file that is missing, unreadable or malformed reads as no compression.

## Failure behaviour
- A paging problem — no paging API, a failed load, or an unfinished load — warns once per session, as a toast and as a desktop notification when the terminal is in the background.
- An unsynced model list, or a model without a known limit, omits the active context's general window rows and leaves the last-turn and last-step rows and the rest of the tooltip intact; content rows then show counts and words without token estimates.
- A tooltip that cannot be built shows the reason in place of its content.

## Trade-offs
- The counts cover the message log, not the exact payload a provider receives.
- Loading a whole transcript costs a request per page of messages.
- DCP's state file and the transcript paging methods are undocumented host surface.
- The `tokens` row matches the built-in counter's sum, but it follows the newest assistant step DCP still leaves in context; after a compression the two counters can pick different steps.
- The `tokens` row and the window figure follow the last assistant step, so they lag a running step.
- The tooltip has no polling: it follows host events.
  The host reports output, reasoning, and cost only when a step ends, so the
  last turn's output and cost read zero and the last step's pace is missing
  while it streams.
  Live per-token figures would need streaming usage from the host.
- Cache-hit rate compares provider token counts: cache reads over uncached input plus both cache directions. The session figure is a token-weighted average across the whole session, not the mean of each step's rate; the last step reports only its own traffic.
- Content token counts are apportioned from each bucket's share of the transcript's characters, not measured per provider request; the selected agent's system prompt is counted when the host exposes it, but tool schemas never appear in the transcript, so the split is approximate and marked `~`. The apportioning only counts steps that have settled: a streaming step would grow the character denominator while the token total stayed at the last completed step, so every other bucket's share would shrink as it streamed. Available skills, agents and MCP servers are counted from the location, not apportioned; tool schemas are not exposed by the host, so their count is omitted.
- The built-in `build` and `plan` agents do not expose their system prompt through the SDK,
  so their content section shows `prompt not exposed`.
  Custom agents expose it.
  Reading the host package would couple the widget to an internal implementation,
  so the text and a precise split stay unavailable.
- Idle time is everything in the wall time that is neither generating nor running tools, so it also covers time between turns.
- The tooltip uses the absolute-positioning trick, so a host layout change can move it.
