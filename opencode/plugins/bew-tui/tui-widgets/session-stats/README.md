# session stats

## Purpose
The widget that counts turns and tool calls for the whole session and for the model's active context; `tui.tsx` renders it one line above the prompt in the session composer header.
The line reads `Sess: 󰍩 12 󱜾 30 󰒔 118 · Ctx: 󰍩 3 󱜾 9 󰒔 31`: `󰍩` counts user messages, `󱜾` assistant messages, and `󰒔` tools, with bookkeeping entries ignored.
`Sess:` covers the whole conversation and `Ctx:` the part still in the model's active context; while the two still match, the line collapses to a single `Sess/Ctx:` group.

## Responsibilities
- The counts line: user, assistant and tool counts per group, each kind behind its own glyph.
- DCP awareness: the context group subtracts whatever the active compression blocks cover, so it shows what the model still sees.
- The tooltip: clicking a group opens it, clicking the other replaces it, and clicking again or the close glyph dismisses it.
- What the tooltip reports: the session totals and the subagent sessions behind them, the model's window usage, the activity counts, and the compression blocks.
- A long subagent list: past a handful of sessions it trims to the dearest few and the most recent few, each group under its own label.

## Architecture
The counting, the compression state, the insight text and the colour helpers are pure modules, free of host and Solid types, so the figures and their layout can be unit-tested without a terminal.
The panel that draws them comes from `tui-toolkit/tooltip/`, and the rows it holds come from the insight module.

The line is reactive: a memo reads the host's message store together with the latest compression state, so a new message or a new compression redraws it.
The tooltip is built on demand instead, and rebuilt on each compression revision while it is open.
Both need the whole transcript, but the store holds only a recent window, so the widget syncs it and then pages the remainder through whatever paging methods the store exposes.

The compression state comes from DCP's per-session state file: the widget reads the blocks that are active, subtracts the messages and tools they cover, and watches the file's directory, because DCP rewrites it in place.
The watch's revision drives both the counts and an open tooltip.
A file that is missing, unreadable or malformed reads as no compression.

## Failure behaviour
- A paging problem — no paging API, a failed load, or an unfinished load — warns once per session, as a toast and as a desktop notification when the terminal is in the background.
- An unsynced model list, or a model without a known limit, omits the window row and leaves the rest of the tooltip intact.
- A tooltip that cannot be built shows the reason in place of its content.

## Trade-offs
- The counts cover the message log, not the exact payload a provider receives.
- Loading a whole transcript costs a request per page of messages.
- DCP's state file and the transcript paging methods are undocumented host surface.
- The window figure follows the last assistant step, so it lags a running step.
- The tooltip uses the absolute-positioning trick, so a host layout change can move it.
