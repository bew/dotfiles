-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local U = require"mycfg.snippets_by_ft._utils"

local SNIPS = {}
local snip = U.get_snip_fn(SNIPS)

local i = ls.insert_node
local t = ls.text_node

-- Start of snippets definitions

snip("r", {desc = "require"}, U.myfmt {
  [[require"<module>"]],
  { module = i(1, "module") },
})

snip("l", {desc = "local var = ..."}, U.myfmt {
  [[local <var> = <value>]],
  {
    var = i(1, "var"),
    value = i(2),
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

snip("!=", {desc = "Lua's != operator"}, { t"~= " })

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
