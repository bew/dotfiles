-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

SU.filetype_setup {
  filetype = "zsh", -- same as current collection
  inherits_from = {"sh"},
}

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
