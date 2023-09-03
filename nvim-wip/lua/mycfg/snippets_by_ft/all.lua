-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local U = require"mycfg.snippets_by_ft._utils"

local SNIPS = {}
local snip = U.get_snip_fn(SNIPS)

local i = ls.insert_node
local t = ls.text_node

-- Start of snippets definitions

snip("#!", { desc = "Generic shebang" }, {
  t"#!/usr/bin/env ", i(1, "bash"),
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
