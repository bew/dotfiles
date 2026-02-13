-- Highlighters for mini.hipatterns plugin
-- <https://github.com/echasnovski/mini.hipatterns>
--
-- Highlighters for this plugin are quite flexible, make sure to read `:h mini.hipatterns`,
-- especially the `Options > Highlighters` section
--
-- NOTE: Lua pattern supports the `%f[set]` Frontier pattern to work as _word separator_ checks,
-- which this plugin makes use of in its examples.
-- DOC: https://www.lua-users.org/wiki/FrontierPattern
-- And because it's not available in Lua5.1 (but only in Lua5.2+ & LuaJit), it's not in Neovim's `:h luaref` help page
-- (PR, cancelled: https://github.com/neovim/neovim/pull/22999)
-- |
-- Simple explaination:
-- `%f[set]` matches the transition from "not in set" to "in set".
-- For example:
--   `%f[%w]` matches the start of a "word"
--   -> Transition from `not in set 'chars of a word'` to `in set 'chars of a word'`)
--
-- FIXME: find a way to easily reload _just_ the highlight after I edited them 🤔
--
-- Nice example of usage:
-- https://github.com/ahmedelgabri/dotfiles/blob/59adb82540492781/config/nvim/lua/plugins/mini.lua#L140

-- TODO: upstream pattern type hints?

---@class mycfg.hl_patterns.GroupFnData
---@field full_match string String with full pattern match
---@field line integer match line number (1-indexed)
---@field from_col integer match starting byte column (1-indexed)
---@field to_col integer match ending byte column (1-indexed, inclusive)

---@class mycfg.hl_patterns.ExtmarkFnData: mycfg.hl_patterns.GroupFnData
---@field hl_group string The highlight group

---@alias mycfg.hl_patterns.PatternFn fun(buf_id: integer): string|string[]?
---@alias mycfg.hl_patterns.GroupFn fun(buf_id: integer, match: string, data: mycfg.hl_patterns.GroupFnData): string?
---@alias mycfg.hl_patterns.ExtmarkFn fun(buf_id: integer, match: string, data: mycfg.hl_patterns.ExtmarkFnData): vim.api.keyset.set_extmark?

---@class mycfg.hl_patterns.PatternSpec
---@field pattern string|string[]|mycfg.hl_patterns.PatternFn
---    Lua pattern(s) for this highlighter
---@field group string|mycfg.hl_patterns.GroupFn
---    The highlight group to use (set as empty string for extmark-only)
---@field extmark_opts? vim.api.keyset.set_extmark|mycfg.hl_patterns.ExtmarkFn
---    Optional extmark to attach to the match

-- Import patterns from other files
return vim.tbl_extend(
  "error",
  require"mycfg.hl_patterns.keywords",
  require"mycfg.hl_patterns.b2_notes",
  require"mycfg.hl_patterns.rgb_colors",
  require"mycfg.hl_patterns.term_colors",

  -- Tech-specific patterns
  require"mycfg.hl_patterns.tech_shell",
  require"mycfg.hl_patterns.tech_lua",
  require"mycfg.hl_patterns.tech_python",
  require"mycfg.hl_patterns.tech_yaml",
  {} -- (for trailing commas)
)
