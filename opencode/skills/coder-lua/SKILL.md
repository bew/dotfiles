---
name: coder-lua
description: |
  Lua code writing guidelines: module shape, require conventions, LuaCATS doc comments,
  type annotations, inline call comments.
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
- A prose doc line is `---`, a space, then the text: `--- <text>`.
  Writing `---<text>` (no space) is wrong — it is not prose, and LuaCATS reads it as a tag prefix.
- A tag line is `---@<keyword> ...` (no space after `---`).
- In `---@field <name> <type> <description>`, the description is plain text — do NOT prefix it
  with `--` or any other comment marker.
  ```lua
  --- Return the current argument list (files passed on the command line).
  ---@return string[]
  function M.get_given_args() ... end
  ```
- Use `---@alias` for repeated string/union types.

## Type annotations

- Name a function's named-params/options structure `<ns>.Opts.<Variant>` (e.g.
  `Backend.Opts.Connect`) — this is the table one function accepts, not a general config/data type.
- Never annotate a value as bare `table`/`any` when a more specific type can be written.
  Use a LuaCATS named type, or a builtin type that LuaCATS/language tooling provides.
- `?` placement in LuaCATS:
  - `---@field foo? TheType <desc>` — the field may be absent from the table.
  - `---@field foo TheType? <desc>` — the field is required, but its value may be `nil`.
  - Combine both for a field that may be absent and may also be `nil`:
    `---@field foo? TheType? <desc>`.
  A type checker treats these as equivalent; the distinction documents intent for human readers.

## Inline call comments

- For an obscure positional argument at a call site, name it inline:
  `foo(bar, --[[strict_indexing]] false)`.

## Testing

No Lua test skill exists in this setup.
If tests are wanted, ask the user how to structure them before writing any.

## Reference docs

- Lua 5.1 reference manual — Neovim embeds LuaJIT (Lua 5.1): <https://www.lua.org/manual/5.1/>
- LuaCATS annotations reference: <https://luals.github.io/wiki/annotations/>
