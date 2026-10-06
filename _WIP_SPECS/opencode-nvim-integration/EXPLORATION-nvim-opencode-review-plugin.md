# nvim-opencode-review-plugin — exploration

Idea (user, verbatim intent): a way to review files in Neovim on demand, as **both** a Neovim plugin and an OpenCode plugin.
When wanted, the Neovim instance would initiate a pairing with the OpenCode instance (shows a dialog) — or the other way around, direction undecided —
and then in Neovim I can annotate a function/class/header/specific line/…, and the OpenCode prompt gets those comments added to it.

This file is the prior-art record: what already exists, and which parts of the idea are still unclaimed.

## Findings

### Neovim ↔ OpenCode bridges (the `opencode.nvim` family) — most relevant

These are the closest existing work, because they already speak the OpenCode server API from Neovim.

#### nickjvandyke/opencode.nvim — ★3866, MIT, active (2026-09-24)

The reference "attach Neovim to an external OpenCode instance" model.

- **Direction**: bidirectional over the OpenCode HTTP daemon API (`/api/*`, shelled out via `curl`).
  - nvim→OC: prompt, command, permission reply, plus editor context.
  - OC→nvim: a persistent SSE subscription to `/api/event`, re-emitted as `OpencodeEvent:*` autocmds (buffer reload, status, permission prompts, edit-diff tabs).
- **Connection/discovery** (`lua/opencode/server/discovery/init.lua`): already-connected server → configured `opts.server.url` → `service.json` in `$XDG_STATE_HOME/opencode/` (`{url, password, pid, version}`) → else start + poll (1s, 5 retries).
  Project isolation via an `x-opencode-directory` header, since the daemon is shared.
- **Multi-instance**: strictly one global connection (`Server.connected` singleton; connecting disconnects the previous).
  No server picker, no session picker.
  The session is auto-resolved on every call to the most-recent root session for nvim's cwd (`Server:resolve_session`), never cached.
  Multiple Neovim instances each discover the shared daemon independently and open their own SSE; no cross-instance coordination.
- **Scope selection**: one transient context per prompt (buffer/window/cursor + optional range).
  Placeholders: `@this`, `@buffer`, `@buffers`, `@visible`, `@diagnostics`, `@marks`, `@quickfix` (`lua/opencode/context/builtins.lua`).
  No set of files/topics, no pending queue, no diff/symbol placeholder.
- **Navigation UI**: a `select` picker (only PROMPTS + COMMANDS), ask input, permission prompt, and an edit-diff tab (`:diffpatch`; `da`/`dr`/`dp`/`do`/`]c`/`[c`/`q`), plus a statusline.
  No telescope/quickfix/sidebar/comment list; no user commands.
- **Persistence**: none. No treesitter/symbol anchors.

#### sudo-tee/opencode.nvim — ★959, Apache-2.0, active (2026-10-02)

A full Neovim frontend that already ships the embedded review flow.

- **Direction**: bidirectional over the OpenCode server HTTP API + SSE, plus a local shadow-git for snapshots.
  - OC→nvim: SSE events plus on-demand resource GETs (session, messages, inbox, execution, permissions, questions).
- **Connection/detection**: configured `url`/`port` → native `opencode service` CLI → else spawn a local server.
- **Multi-instance**: multiple Neovim on one server via `port_mapping.lua` (JSON keyed by port+cwd, registers nvim PIDs, releases the server when the last client leaves).
  Still one global connection per nvim, no server picker.
  Sessions are first-class: a session picker (`<leader>os`, project/global scope, rename/delete/new/fork/open-in-tab) and logical session tabs per panel (`session_tab_strip.lua`, `<leader>o1..o9`, `<leader>oN`, `<leader>o?`), each tab owning its own active session/context/model/pending permissions.
- **Scope selection**: the diff scope is a **span of turns/messages** (mark `f`/`t`, re-review the range) — the only tool with a multi-message scope.
  One file previewed at a time from the file tree; whole-patch vs side-by-side (`p`); line/visual-range comments with before/after side; hunk implicit; snapshot breakpoints/restore-points for commit-like scoping; deleted files handled.
  No multi-file batch; treesitter symbols only for output navigation, never review anchors.
- **Navigation UI**: session-diff tab (file tree + preview, `]r`/`[r` comment stepping, `c`/`dc`), range/messages window, `K` turn preview, `g?` help, comment-input float, a **context bar** (review-comment count + drift status), output navigation (`[[`/`]]`, `[u`/`]u`), session picker, tab strip/picker, timeline/history pickers.
  No standalone comment list; no quickfix.
- **Persistence**: review comments are transient in-memory, consumed after send.
  Restore points persisted to cache.
- **Core flow already works**: `:Opencode diff open` → annotate line/range with `c` → comments auto-attach to the next prompt, with drift/stale resolution (`review_anchor.lua`).

#### Smaller Neovim → OpenCode bridges

| Plugin | Direction | Multi-instance | Scope | Nav UI |
|---|---|---|---|---|
| HazielMagallanes/opencode.nvim (★5) | nvim→OC only (TUI in `termopen`, random `--port`) | no registry; window↔port↔session unmapped | none (no text/selection ever sent) | Telescope session picker (resume/delete/yank) |
| colewhitley/agent-review.nvim (★1) | nvim→OC one-shot via tmux `send-keys` | single global `registered_pane_id`; if >1 pane matches, `vim.ui.select` | visual selection + gitsigns hunk; multi-file accumulate; multi-repo via Diffview queue | `vim.ui.select` list, Diffview, repo-queue cycling |
| kksimons/nvim-opencode | both (partial): HTTP `POST /tui/paste`, `/tui/replace-prompt`; read-only GET pulls | one global terminal/session; no registry, no picker | file, line range, visual, cursor±N, **treesitter function**, one-file context toggle | essentially none; diff nav is a stub |
| AuenKr/open-code.nvim (★2) | nvim→OC only (terminal, `nvim_chan_send`) | `instances` keyed by git root, `current_instance` pointer | one scope at a time: visual paste, or `/add <path>` whole file | none (window-nav + scroll keys) |

Opposite direction (vim *inside* the OC prompt): Tarquinen/opencode-vim, leohenon/opencode-vim (OC fork with vim motions).

### Agent-agnostic "annotate → AI" Neovim plugins

- **georgeguimaraes/review.nvim** — ★136, Apache-2.0.
  Unidirectional nvim→agent: clipboard, an `on_export` callback (tmux/file/avante), and sidekick.nvim.
  Reviewable set chosen by revision (working tree, contiguous commit range, merge-base-aware branch), then walked file-by-file.
  Line/visual-range/whole-file/out-of-diff note; no hunk scope, no subset-of-files, no topics.
  UI: commit picker, branch picker, `:Review list` via `vim.ui.select`, `]n`/`[n` stepping, codediff explorer file stepping.
  Per-repo JSON at `stdpath('data')/review/{hash}.json`; a single global `current_tabpage` means concurrent review tabs clobber each other. No symbol anchors.
- **meowshed/meow.review.nvim** — ★11 (formerly retran/…).
  Unidirectional (clipboard, `.review.md`, avante, codecompanion, JSON formatter).
  Scope: line, visual range, hunk (gitsigns/`vim.diff`); function/class captured by treesitter only as *metadata*, not as the anchor; whole-file only as an export filter.
  UI: sign column, annotation picker (snacks→telescope→fzf→nui) with `goto`/`goto_file`/`goto_type`, view popup, next/prev, stale markers, statusline.
  Shared per-project JSON `.cache/meow-review/annotations.json`, extmark drift tracking + stale detection, per-annotation `resolved` flag. No lock (lost-update risk).
- **abrose/wishes.nvim** — ★1.
  Both directions, file-mediated: nvim writes `.wishes.md`, agent reads + deletes addressed wishes, nvim detects via 1s mtime poll.
  Ships an OpenCode **custom command** at `.opencode/commands/wishes.md` (not a skill).
  Scope: one wish = file + single line or contiguous range + category (`fix`/`question`/`refactor`/`note`).
  UI: sign column + virtual text, list picker (snacks/telescope/quickfix), Telescope extension, summary echo.
  Root fixed at `setup()`; one project per instance. No symbols.
- **choplin/code-review.nvim** (★18): simple line/block comments → markdown.

### OpenCode-side primitives and pattern

- Plugin API (v2, beta): plugins are in-process, loaded from `.opencode/plugins/` or `~/.config/opencode/plugins/`, or npm.
  Relevant capabilities: `ctx.session` (create/get/**prompt**/command/synthetic/interrupt/hook), `ctx.tool.transform.add` (register a custom tool), `ctx.event` (server event stream), `ctx.integration` (list/get/**connect/attempt**, connection resolution).
  TUI events include **`tui.prompt.append`**, `tui.command.execute`, `tui.toast.show`.
  `ctx.integration` semantics unverified (docs page 404'd).
- **ndom91/open-plan-annotator** — ★96, MIT.
  OC plugin (`opencode.json` plugin entry) that intercepts plan mode, spawns an ephemeral bun HTTP server (port 0) + browser React UI, and returns structured annotations to the agent; exposes an `annotate_plan` tool and injects a system prompt.
  Proves the "OC plugin hosts a local server + external annotator UI" pattern.
  Scope is arbitrary DOM text ranges within markdown blocks, incl. cross-block; UI is browser-only (outline/TOC, version sidebar, annotation sidebar, approve/request-changes).
  No `ctx.integration` usage.

### Key upstream sources consulted

- github.com/nickjvandyke/opencode.nvim
- github.com/sudo-tee/opencode.nvim
- github.com/georgeguimaraes/review.nvim
- github.com/meowshed/meow.review.nvim
- github.com/abrose/wishes.nvim
- github.com/ndom91/open-plan-annotator
- github.com/HazielMagallanes/opencode.nvim
- github.com/colewhitley/agent-review.nvim
- github.com/kksimons/nvim-opencode
- github.com/AuenKr/open-code.nvim
- v2.opencode.ai/docs/build/plugins
- Local shallow clones: `/tmp/opencode/prior-art/`

## Design crux

The idea overlaps heavily with existing work, so its value hinges on the parts nothing else does:
an **explicit, mutual pairing handshake** between a specific Neovim instance and a specific OpenCode instance/tab,
**symbol-level anchors** (function/class/heading) as first-class annotation targets,
and a **two-plugin split** where the OpenCode plugin is more than a passthrough.

Caveat: a Neovim-only plugin can already talk to the OpenCode server API (proven by nickjvandyke),
so the OpenCode-side plugin needs a concrete job to justify itself (pairing registry, `tui.prompt.append` injection, a custom pull tool, or `ctx.integration` registration).

## Already solved (avoid rebuilding)

- Editor context → prompt injection (nickjvandyke).
- Inline annotations on OC session diffs, auto-attached to the next prompt, incl. drift/stale handling (sudo-tee).
- Treesitter symbol context capture + extmark drift/stale handling (meow).
- Agent-side consumption of an on-disk annotations file, incl. an OC skill/command (wishes).
- Plugin hosting an external annotator server returning structured feedback (open-plan-annotator).

## Open threads

- **Core gap**: external side-annotator (nvim annotates while OC runs in its own TUI) vs symbol anchors on OC diffs (superset of sudo-tee) vs general OC-agnostic code annotation.
- **Pairing direction**: nvim→OC dialog vs OC→nvim dialog vs discovery-only (service.json) vs both with fallback.
- **Delivery path**: `tui.prompt.append` injection vs custom pull tool vs on-disk file (wishes-style) vs direct `ctx.session.prompt` push.
- **Anchor model**: lines/ranges only vs + treesitter symbols vs + drift handling vs + resolved-state review session.
- **Lifecycle**: transient (cleared after send) vs persistent review session.
- **OpenCode plugin justification**: what the OC-side plugin does that a nvim-only plugin cannot.
