-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local U = require"mycfg.snippets_by_ft._utils"

local SNIPS = {}
local snip = U.get_snip_fn(SNIPS)

local i = ls.insert_node
local t = ls.text_node
local dn = ls.dynamic_node

-- Start of snippets definitions

snip("b", { desc = "bold text" }, U.myfmt {
  [[**<text>**]],
  {
    text = U.insert_node_default_selection(1),
  },
})

snip("em", { desc = "italic (emph) text" }, U.myfmt {
  [[_<text>_]],
  {
    text = U.insert_node_default_selection(1),
  },
})

snip("ln", { desc = "link" }, U.myfmt {
  "[<desc>](<target>)",
  {
    desc = i(1),
    target = U.insert_node_default_selection(2),
  },
})

snip("com", { desc = "HTML comment" }, U.myfmt_braces {
  [[<!-- {text} -->]],
  {
    text = U.insert_node_default_selection(1),
  },
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
