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

-- Import patterns from other files
return vim.tbl_extend(
  "error",
  require"mycfg.hl_patterns.keywords",
  require"mycfg.hl_patterns.vim_colors",

  -- Tech-specific patterns
  -- TODO: use `vim.b.minihipatterns_config` instead of global patterns 🤔
  --   Find a nice way to define a pattern or group of patterns for 1+ filetype(s)
  require"mycfg.hl_patterns.tech_python",
  require"mycfg.hl_patterns.tech_lua",
  {} -- (for trailing commas)
)
