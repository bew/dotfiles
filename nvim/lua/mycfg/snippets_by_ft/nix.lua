-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

-- NOTE: not using `inh` trigger, to avoid writting `in` to dedent text in..
snip("ih", { desc = "inherit ...;" }, SU.myfmt {
  [[inherit<maybeFrom> <params>;]],
  {
    maybeFrom = ls.choice_node(1, {
      SU.myfmt_no_strip {[[ (<attrset>)]], {attrset = i(1, "from")}},
      t"",
    }),
    params = i(2, "field"),
  }
})

snip("ls", { desc = "language string" }, SU.myfmt {
  [[/* <lang> */ ''<code>''<end_>]],
  {
    lang = i(1, "lang"),
    code = i(2),
    end_ = i(3),
  }
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
