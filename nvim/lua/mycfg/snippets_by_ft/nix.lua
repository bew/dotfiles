-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

-- NOTE: not using `inh` trigger, because writing `in` would auto-dedented text in let blocks..
snip("ih", { desc = "inherit ...;" }, SU.myfmt {
  [[inherit <rest>;]],
  {
    rest = ls.choice_node(1, {
      SU.myfmt {
        [[(<attrset>) <fields>]],
        {
          attrset = i(1, "from"),
          fields = ls.restore_node(2, "fields"),
        },
      },
      ls.restore_node(nil, "fields"),
    }),
  }
}, {
  stored = {
    fields = i(nil, "field"),
  },
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
