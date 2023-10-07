-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local U = require"mycfg.snippets_by_ft._utils"

local SNIPS = {}
local snip = U.get_snip_fn(SNIPS)

local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node

-- Start of snippets definitions

snip("fn", { desc = "function foo() { ... }" }, U.myfmt {
  [[
    function <name>()
    {
    	<body>
    }
  ]],
  {
    name = i(1, "function_name"),
    body = i(2),
  },
})

snip("case", { desc = "switch case ..." }, U.myfmt {
  [[
    case <word> in
      <pattern>)
        <body>;;<next>
    esac
  ]],
  {
    word = i(1),
    pattern = i(2, "*"),
    body = i(3),
    next = i(4),
  }
})

snip("do", {desc = "do ... end"}, U.myfmt {
  [[
    do
      <body>
    done
  ]],
  { body = i(1) },
})

snip("if", {desc = "if ...; then ... fi"}, U.myfmt {
  [[
    if <cond>; then
      <body_true>
    fi
  ]],
  {
    cond = c(1, {
      -- In a choiceNode, direct children nodes that normally expect an index don't need one;
      -- their jump-index is the same as the choiceNodes'.
      i(nil, "condition"),
      (U.myfmt {"[[ <test> ]]", { test = i(1) }}),
    }),
    body_true = i(2),
  },
})

snip("cond", {desc = "[[ ... ]]"}, U.myfmt {
  "[[ <test> ]]",
  { test = i(1) },
})

snip("err", {desc = "echo to stderr"}, {
  t">&2 echo ",
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
