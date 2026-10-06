# opencode-nvim-integration — exploration

The Neovim↔OpenCode bridge idea: inject editor context into prompts, run prompts/OpenCode
commands, and support edit review, all driven from keymaps.
The reference implementation in this space is `nickjvandyke/opencode.nvim`; `sudo-tee/opencode.nvim`
is an alternative, richer frontend.
Both connect to an external `opencode` daemon (or start one), i.e. a thin layer, "NOT a full
blown client".

## Findings

- Three interaction lanes: `ask` (freeform input), `select` (picker over built-in prompts +
  OC commands), and `operator` (dot-repeatable send of a range/line).
- Built-in context placeholders (usable in any prompt): `@this`, `@buffer`, `@buffers`,
  `@visible`, `@diagnostics`, `@marks`, `@quickfix`.
- Every plugin API call sends **one** message into the OpenCode session.
  → many comments can't be batched into a single long message.
- The `ask` prompt is **single-line** (`vim.ui.input`-style).
  → long or multiline/structured messages aren't really writable.
- The plugin injects editor context, but scope is one transient context per prompt; no pending
  queue and no persisted annotations.
- Fork-candidacy signals: the upstream dev is actively working on it (updated for OC v2
  ~2 weeks ago), and Neovim 0.13 `vim.async` support is expected to land.

## Design crux

Can the weak interaction model — one-message-per-call and a single-line prompt — be fixed
without forking, or is a fork the right investment given upstream momentum and the risk of
diverging while the author is still actively moving?

## Candidate directions

- (active) **Stay on upstream + workarounds** — no fork; lean on `select` custom prompts and an
  external editor / scratch buffer to compose long messages, accept the gaps for now.
- (deferred) **Fork opencode.nvim** — add a multiline/structured prompt input and message
  batching, and absorb `vim.async` once upstream provides it (or contribute upstream instead).
- (deferred) **Build on sudo-tee/opencode.nvim** — an alternative full frontend that already
  ships a richer review/comment flow; assess whether it covers the niche (see cross-link).

## Open threads

- Does the OC server API support appending to a single message / a prompt buffer (true
  batching), or is one HTTP call = one message by design?
- Is the single-line prompt a `vim.ui.input` limitation (forkable) or an intentional design
  choice?
- Fork vs wait vs contribute-upstream: what does the upstream roadmap say about
  multiline input, batching, and `vim.async`?
- Relationship to `EXPLORATION-nvim-opencode-review-plugin.md`: is this experiment a
  stepping stone toward that review/annotation plugin, or an independent usage thread?
