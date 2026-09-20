---
name: coder-lua-for-nvim
description: |
  Neovim Lua conventions for this dotfiles repo: nvim API over Ex, naming/type conventions,
  keymap/action system, window layout, and headless testing.
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

## Rules

### Naming

- nvim handle/index names:
  * `bufnr` (buffer handle) vs a buffer name
  * `winid` (window handle) vs `winnr` (window number)
  * `tabid` (tab handle) vs `tabnr`

### Types & annotations

- Use the builtin nvim type when one exists (`vim.api.keyset.*`, e.g.
  `vim.api.keyset.user_command`, `vim.api.keyset.cmd.mods`) instead of a hand-rolled type or a
  bare `table`.
- Type annotations live in the nvim runtime Lua meta files, NOT in help pages:
  `$VIMRUNTIME/lua/vim/_meta/{api,api_keysets,api_keysets_extra}.lua`.
  Help pages describe behaviour; they rarely carry annotations.
- Do NOT declare a plugin-specific type for an nvim API that lacks an annotation; if no builtin
  fits, add an `@YYYY-MM missing type annotation` note instead (see `coder-generic` Dated notes).
- When forwarding command modifiers to a builtin that accepts raw smods (e.g. `nvim_cmd`), keep
  the standard type (`vim.api.keyset.cmd.mods`); do not invent a minimal enum.
  Convert to a strict field set/enum only when plugin logic actually branches on the values.
- Whenever an API takes or returns a row/column/line/cursor, annotate whether it is 0-indexed or
  1-indexed (nvim APIs are mostly 0-indexed; Ex is 1-indexed). (`:h api-indexing`)
  - Encode the base in the variable name: `pos0`/`row0` for 0-indexed, `pos1`/`row1` for
    1-indexed, and mixed forms like `pos10` (row 1-indexed, column 0-indexed).
    See `mylib.Pos0` in `nvim/lua/mylib/utils/pos_utils.lua` for a worked example.
  - State the index base at each API call site when it is not obvious from the name.

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
  - `nvim_cmd` (table form) for commands that take mods/args.
  - No API exists for creating/closing tab pages (`vim.cmd.tabnew`,
    `vim.cmd[[silent tabonly]]`) or equalizing splits (`vim.cmd[[wincmd =]]`), so Ex
    commands remain there.
- Among non-Ex options, prefer the ergonomic `vim.*` wrapper over the raw `nvim_*` call when one
  exists:
  - `vim.o`/`vim.bo`/`vim.wo`/`vim.opt` for options, `vim.hl.*` for highlights.
  - Use the raw `nvim_*`/`vim.fn.*`/`vim.cmd.*` form only when no wrapper exists or it is clearly
    easier, and say why. When unsure, ask the user.
- Reference nvim behaviour by help tag inline: `` `:h api-indexing` ``.
  Load the `read-nvim-help` skill to read those tags.
- Plugins expose actions as plain functions; this config owns the mappings.
  Wire them through the action/keymap system (`A.mk_action` + `K.*`), never rely on a plugin to
  define maps itself.
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
