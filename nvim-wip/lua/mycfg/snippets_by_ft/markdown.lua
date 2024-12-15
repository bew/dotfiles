-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node
local t = ls.text_node
local dn = ls.dynamic_node

-- Start of snippets definitions

snip("b", { desc = "bold text" }, SU.myfmt {
  [[**<text>**]],
  {
    text = SU.insert_node_default_selection(1),
  },
})

snip("em", { desc = "italic (emph) text" }, SU.myfmt {
  [[_<text>_]],
  {
    text = SU.insert_node_default_selection(1),
  },
})

snip("ln", { desc = "link" }, SU.myfmt {
  "[<desc>](<target>)",
  {
    desc = i(1),
    target = SU.insert_node_default_selection(2),
  },
})

snip("com", { desc = "HTML comment" }, SU.myfmt_braces {
  [[<!-- {text} -->]],
  {
    text = SU.insert_node_default_selection(1),
  },
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
