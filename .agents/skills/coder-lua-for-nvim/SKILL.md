---
name: coder-lua-for-nvim
description: |
  Neovim Lua conventions for this dotfiles repo: nvim API over Ex, keymap/action system,
  window layout, and headless testing.
  Always load when editing this repo's Nvim config (nvim/lua/**).
  Requires coder-generic and coder-lua skills.
metadata:
  maintainers: [bew]
---

## Goal

Write Neovim config Lua that follows this repo's API and mapping conventions,
building on generic & Lua conventions.

REQUIRES: load `coder-generic` and `coder-lua` skills first.

All files here are Nvim config modules — loaded via `require`/`dofile`; no script code.

TODO: Add a skill for querying Nvim help/docs (e.g. `:h`, `api.txt`) token-efficiently.

## Rules

### Ex commands from Lua

- For literal string Ex commands, use the long-bracket form:
  `vim.cmd[[silent only]]`, not `vim.cmd("silent only")`.
  Alternative is using `vim.cmd.only { mods = { silent = true } }`.
  Check surrounding code to choose.
- For complex dynamic/interpolated Ex commands, use the structured
  `vim.api.nvim_cmd({ ... }, {})` instead of concatenating a command string.
- NOTE: Escape filenames with `vim.fn.fnameescape(path)` when passing them to Ex commands.

## Guidelines

- Prefer `vim.api.nvim_*` functions over Ex commands; fall back to Ex commands only when
  there is no nicer API.
  - `nvim_win_close` instead of `:only`.
  - `nvim_set_current_buf` instead of `:edit`/`:buffer`.
  - `nvim_set_current_tabpage` instead of `:tabfirst`.
  - `nvim_get_option_value` / `nvim_set_option_value` instead of `vim.o`.
  - `nvim_cmd` (table form) for commands that take mods/args.
  - No API exists for creating/closing tab pages (`vim.cmd.tabnew`,
    `vim.cmd[[silent tabonly]]`) or equalizing splits (`vim.cmd[[wincmd =]]`), so Ex
    commands remain there.
- Prefer defining actions with the action system, then referencing them from map calls:
  - `my_actions.foo = A.mk_action { default_desc = "...", n = function() ... end }`
  - `K.global_leader_map{mode="n", key="...", action=my_actions.foo}`
  - Avoid inline `function()` map bodies, and do not add an explicit `desc` when the
    action already carries `default_desc`.
- The command-tree argument form is fine for commands that take a file argument:
  `vim.cmd.tabnew(path)`.

## Testing

Test a config module headlessly without booting the full config:
- `nvim --headless --clean <args> -c 'luafile /tmp/test.lua' -c 'qa!'` with
  `local M = dofile(".../module.lua")` inside the test.
- `VimEnter` fires *after* `-c` commands, so a `-c 'qa!'` can prevent it from firing.
  To test `VimEnter` behavior, register a follow-up `VimEnter` autocmd (registered after the
  one under test) that prints state and quits.
