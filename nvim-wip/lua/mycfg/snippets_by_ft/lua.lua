-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local U = require"mycfg.snippets_by_ft._utils"

local SNIPS = {}
local snip = U.get_snip_fn(SNIPS)

local i = ls.insert_node
local t = ls.text_node

-- Start of snippets definitions

snip("req", {desc = "local require"}, U.myfmt {
  [[local <var> = require"<module>"]],
  {
    var = i(1, "var"),
    module = i(2, "module"),
  },
})

snip("do", {desc = "do ... end"}, U.myfmt {
  [[
    do
      <body>
    end
  ]],
  { body = i(0) },
})

snip("!=", {desc = "Lua's not-equal operator"}, { t"~= " })

snip("fn", {desc = "function definition"}, U.myfmt {
  [[
  function<maybe_name>(<args>)
  	<body>
  end
  ]],
  {
    maybe_name = i(1),
    args = i(2),
    body = i(3),
  },
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
