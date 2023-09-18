-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local U = require"mycfg.snippets_by_ft._utils"

local SNIPS = {}
local snip = U.get_snip_fn(SNIPS)

-- local i = ls.insert_node
-- local t = ls.text_node

-- Start of snippets definitions

U.filetype_setup {
  filetype = "zsh", -- same as current collection
  inherits_from = {"sh"},
}

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
