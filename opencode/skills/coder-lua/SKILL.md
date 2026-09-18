---
name: coder-lua
description: |
  Lua code writing guidelines: module shape, require conventions, LuaCATS doc comments.
  Always load when asked to draft/write/edit/refactor/review Lua (.lua) code files.
  Requires coder-generic skill.
metadata:
  maintainers: [bew]
---

## Goal

Write Lua code that is well-documented and idiomatic, building on generic conventions.

REQUIRES: load `coder-generic` skill first.

NOTE: This skill covers general Lua (module shape, require style, LuaCATS doc comments).
It will expand with more Lua areas as usage grows.

In my usage Lua files are modules — required by other Lua modules; generic module rules apply.
I never use standalone Lua scripts, so this is out of scope here.

## Rules

- A module is `local M = {}` … `return M`.
  `M` is the module's public surface; internal helpers stay `local function`.
- Use `require"module.path"` — no space between `require` and the string.

## Doc comments

- A doc comment starts with a prose summary line, then the LuaCATS tags.
- Prose doc line: `--- <text>` (a space after `---`).
- Tag line: `---@<keyword> ...` (no space after `---`).
  ```lua
  --- Return the current argument list (files passed on the command line).
  ---@return string[]
  function M.get_given_args() ... end
  ```
- Use `---@alias` for repeated string/union types.

## Testing

No Lua test skill exists in this setup.
If tests are wanted, ask the user how to structure them before writing any.

## Reference docs

- Lua 5.1 reference manual — Neovim embeds LuaJIT (Lua 5.1): <https://www.lua.org/manual/5.1/>
- LuaCATS annotations reference: <https://luals.github.io/wiki/annotations/>
