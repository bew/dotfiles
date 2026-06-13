# [DRAFT] Session Manager Plugin

## Introduction

Neovim's built-in `:mksession` / `:source` machinery is reliable but bare.
There is no standard way to list, pick, rename, or archive sessions tied to a
project, and no convention for where to store them.
This plugin fills that gap for a single-developer workflow where sessions live
alongside the project they belong to.

The primary motivation is ergonomics: save a named session with one keystroke,
restore it the same way, and occasionally curate the list through a lightweight
picker UI.
A secondary motivation is predictability: session files sit in a known,
per-project location alongside the repo so nothing is ever lost in a global
cache directory.

Use-cases:
- Open a project, restore exactly where you left off by name.
- Save mid-task progress under a descriptive name before switching branches.
- Archive stale sessions without permanently losing them.
- (Optional) Run custom Lua before save / after load (e.g. close terminals,
  reopen a file tree).

The design was informed by `resession.nvim` (hooks model, per-directory
scoping) but is also specified for a full-custom implementation using
`:mksession` / `:source` directly.

## Terminology

**Session** (new!): a named snapshot of the current Neovim state, produced by
`:mksession` (or equivalent) and restorable via `:source`.
A Session is identified by its Session Name within the Active Session Directory.

**Session Name** (new!): a user-supplied string used to identify a Session.
No `/` character allowed; no `.vim` suffix stored by the user — the plugin
appends it internally.
There is no automatic default; interactive commands always prompt the user with
an empty input.

**Session File** (new!): the `.vim` file on disk that stores a Session.
Path: `<Active Session Directory>/<session-name>.vim`.

**Active Session Directory** (new!): the directory `.nvim-sessions/` at the
Repo Root.
Contains all live Sessions.
Created lazily on first save.

**Archive Directory** (new!): the directory `.nvim-sessions/archive/` at the
Repo Root.
Contains Sessions that have been soft-deleted (archived).
Archiving is the only deletion path exposed for active Sessions in the picker;
permanent deletion is only exposed for archived Sessions.
Created lazily on first archive.

**Repo Root** (new!): the top-level directory of the Git repository, resolved
once by running `git rev-parse --show-toplevel` on first use and then cached.
When inside a Worktree, this returns the base repo root, not the worktree path,
so all worktrees share one Active Session Directory.

**Worktree** (well-known): a linked working tree created with `git worktree add`.
Worktrees are transparent to this plugin: they all resolve to the same Repo Root.

**Hook** (new!): an optional user-supplied Lua callback invoked at a defined
point in the save or load lifecycle.
Hooks are the extension point for custom side effects (e.g. closing terminals
before save, reopening a file tree after load).
Returning `false` from a `before_*` hook aborts the operation.

**`sessionoptions`** (well-known): a native Vim option (`:help sessionoptions`)
controlling what `:mksession` captures: open buffers, cwd, window sizes, folds,
tab pages, etc.
The custom implementation delegates entirely to whatever `sessionoptions` the
user has set globally; the plugin does not read or modify it.
`resession.nvim` ignores `sessionoptions` entirely and has its own `options`
list in its `setup()` config.

## Naming & IDs

Session Names:
- User-supplied; no `/` allowed.
- Stored as `<name>.vim` on disk.
- Displayed without the `.vim` suffix everywhere.

Path patterns:

```
<repo-root>/.nvim-sessions/<name>.vim          -- Active Session
<repo-root>/.nvim-sessions/archive/<name>.vim  -- Archived Session
```

Examples:

```
/home/user/myproject/.nvim-sessions/main.vim
/home/user/myproject/.nvim-sessions/feat-auth.vim
/home/user/myproject/.nvim-sessions/archive/old-refactor.vim
```

Gitignore: a `.gitignore` file is written into `.nvim-sessions/` on first save,
ignoring `*.vim` so session files are never accidentally committed.

## API

### Setup

`session_dir` is a function, not a string.
It is called lazily on first use, not at setup time.
This allows it to run `git` commands that depend on the current working
directory being set correctly after Neovim has fully initialized.

```lua
require("project-sessions").setup({
  -- Required: returns the absolute path to the Session Directory (Repo Root).
  -- Called once on first use, result is cached.
  -- Return nil to signal "not in a supported project" — all commands will no-op with a notification.
  session_dir = function()
    local root = vim.trim(vim.fn.system("git rev-parse --show-toplevel"))
    if vim.v.shell_error ~= 0 then return nil end
    return root
  end,

  -- Keybindings (set to false to disable a binding)
  keys = {
    save   = "<leader>ss",
    picker = "<leader>sp",
  },

  -- Hooks (all optional)
  hooks = {
    -- Return false to abort the operation.
    before_save = function(session_name) end,
    after_save  = function(session_name) end,
    -- Return false to abort the operation.
    before_load = function(session_name) end,
    after_load  = function(session_name) end,
  },
})
```

### Programmatic API

```lua
local sessman = require"project-sessions"

---@class sessman.Session
---@field name     string
---@field path     string
---@field mtime    number
---@field archived boolean

-- Save current state as a named session.
-- Prompts the user if name is nil (interactive use).
-- opts.force: bool — skip before_save hook check (default false)
sessman.save(name, opts)

-- Load a session by name. Wrapped in pcall; shows error on failure.
-- opts.archived: bool — load from Archive Directory instead (default false)
sessman.load(name, opts)

-- Move an active session to the Archive Directory.
sessman.archive(name)

-- Permanently delete a session from the Archive Directory.
sessman.delete_archived(name)

-- Rename a session (active or archived, determined by the dir it lives in).
sessman.rename(name, new_name)

-- Open the Telescope picker.
sessman.picker()

-- Return active sessions sorted by mtime desc.
sessman.list() --> sessman.Session[]

-- Return archived sessions sorted by mtime desc.
sessman.list_archived() --> sessman.Session[]

-- Return the resolved Active Session Directory path.
-- Returns nil if session_dir() returned nil.
-- Result is cached after the first call.
sessman.active_dir() --> string | nil
```

## Session Directory Resolution

`session_dir` in setup is called once on the first operation that needs it.
The result is cached for the lifetime of the Neovim process.

If `session_dir` returns `nil`, all interactive commands show:
`"project-sessions: not in a supported project"` and return early.

The Active Session Directory and Archive Directory are created lazily on first
save if they do not exist.

## Picker UI

Telescope is the only supported picker backend.
The picker opens a `telescope.nvim` finder over the session list.

**Display format (two sections, active first):**

```
[active]
  scratch              just now
  feat-auth            5 hours ago
  main                 2 days ago

[archived]
  old-refactor         3 weeks ago
```

Sessions are sorted by `mtime` descending within each section.
Relative timestamps are computed at picker open time.
The `[archived]` section appears below active sessions and is visually
separated (telescope result separator or highlighted header entry).

**Picker keybindings (configurable via `keys.picker_*`):**

| Key     | Active session action       | Archived session action         |
|---------|-----------------------------|---------------------------------|
| `<CR>`  | Load session                | Load session (restore from archive) |
| `<C-s>` | Save & update session       | —                               |
| `<C-r>` | Rename (prompt)             | Rename (prompt)                 |
| `<C-x>` | Archive (soft-delete)       | Permanently delete (confirm)    |
| `<Esc>` | Close picker                | Close picker                    |

Permanent deletion shows an inline confirmation: `"Delete 'old-refactor' permanently? [y/N]"`.

NOTE: Loading an archived session does NOT automatically move it back to
active. The user must rename/move explicitly if they want that.

## Load Safety (pcall)

All `:source` / `resession.load()` calls are wrapped in `pcall`.
On error, the plugin shows a notification with the raw error message and does
not attempt rollback (Neovim state may be partially applied — this is
acceptable; the user can `:qa!` and restart).

```lua
-- Custom impl pattern:
local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(path))
if not ok then
  vim.notify("project-sessions: load failed\n" .. err, vim.log.levels.ERROR)
end
```

## Hooks as Extension Points

Common use-cases:

```lua
hooks = {
  before_save = function(name)
    -- Close terminal buffers so they don't pollute the session file.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].buftype == "terminal" then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,

  after_load = function(name)
    vim.cmd("Neotree show")
  end,
}
```

Returning `false` from `before_save` or `before_load` aborts the operation.
All other return values are ignored.

## Alternatives & Tradeoffs

Two competing implementation strategies for the session save/load core.
The rest of the plugin (picker, archive, hooks) is identical in both.

### Option A — Full custom (pure Lua + `:mksession` / `:source`)

```lua
vim.fn.mkdir(active_dir, "p")
vim.cmd("mksession! " .. vim.fn.fnameescape(path))
-- load:
local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(path))
```

**Advantages:**
- Zero additional dependencies.
- Session file is a plain `.vim` script — readable and portable without the plugin.
- Behavior is entirely in this plugin's code, nothing delegated upstream.
- Respects the user's existing `sessionoptions`.

**Costs:**
- Must implement the full lifecycle (list, rename, archive, delete, hooks) manually.
- No built-in extension system for third-party plugin state.
- Session content quality depends entirely on the user's `sessionoptions`.

### Option B — resession.nvim wrapper

```lua
local resession = require"resession"
-- NOTE: dir= is passed per-call (not in setup) to keep resolution lazy.
resession.save(name, { dir = active_dir })
resession.load(name, { dir = active_dir })
```

**Advantages:**
- Hooks, autosave, and tab-scoped sessions come for free.
- Session format is JSON — easy to inspect and diff.
- Extension system for saving/restoring third-party plugin state (aerial, overseer, etc.).
- Per-call `dir` override makes the archive pattern trivial.

**Costs:**
- One extra dependency (`resession.nvim`).
- JSON format is not portable — requires resession to restore.
- Ignores `sessionoptions`; has its own `options` list in `setup()`.

### Decision criteria

Use **Option A** when:
- Zero-dependency or vanilla Neovim portability is required.
- The user already has `sessionoptions` tuned for their workflow.

Use **Option B** when:
- Third-party plugin state (e.g. aerial, overseer) must survive across sessions.
- Autosave or tab-scoped sessions are desired.
- JSON diffability is useful (e.g. committing sessions to git).

## Related files

- `POC/project-sessions.nvim/lua/project-sessions/init.lua` — Option A POC: full custom impl (pure Lua + `:mksession`), telescope picker, hooks, archive.
- `POC/sessions.lua` — Option B POC: resession.nvim-based impl as a plugin declaration for the dotfiles plugin system.

## Open Questions

1. **Loading an archived session: move it back to active or not?**
   Non-blocking. Current spec says loading archived does NOT restore it to active.
   This may be surprising if the user loads it frequently.
   Could add a `<C-u>` "unarchive" action in the picker as an explicit alternative.

2. **Session name collision on archive.**
   Blocking. If an active session named `main` is archived and a new `main` is later
   archived, the second archive overwrites the first.
   Options: auto-suffix with timestamp, error and prompt for rename, silently overwrite.
   Must decide before first release.

3. **Picker archived-section header UX.**
   Non-blocking. Telescope has no native section-header concept.
   Current POC uses a non-selectable entry; needs validation that it renders acceptably.

4. **`sessionoptions` recommendation for Option A.**
   Non-blocking. Should the plugin document a recommended `sessionoptions` value,
   or expose a scoped override for its own saves?
   Low impact — can be a README note rather than a code change.

5. **Auto-save / auto-load on `VimEnter` / `VimLeavePre`.**
   Non-blocking. Out of scope for v1.
   If added: should it use the last-used session name (persisted in `stdpath("data")`)
   or always prompt?
