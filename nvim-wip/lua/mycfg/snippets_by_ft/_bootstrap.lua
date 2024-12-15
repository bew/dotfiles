-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node
local t = ls.text_node

-- Start of snippets definitions

-- snip("hi!", { desc = "Hello? o/" }, {
--   t"Hello world!",
-- })

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
