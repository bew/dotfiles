-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

snip("safe", { desc = "Safe, strict script execution" }, ls.choice_node(1, {
  t[[set -euo pipefail # Safe, strict script execution]],
  t {
    "# Safer shell script with these options",
    "# -e          : exit if a command exits with non-zero status",
    "# -u          : exit if an expanded variable does not exist",
    "# -o pipefail : if a command in a pipeline fail, fail the pipeline",
    "#               (e.g this now fails: false | true)",
    "set -euo pipefail",
  },
}))

snip("l", { desc = "local var decl/def" }, SU.myfmt_braces {
  "local {var}={after}",
  {
    var = i(1, "var"),
    after = i(2),
  },
})

snip("fn", { desc = "function foo() { ... }" }, SU.myfmt {
  [[
    function <name>()
    {
    	<body>
    }
  ]],
  {
    name = i(1, "function_name"),
    body = SU.insert_node_default_selection(2),
  },
})

snip("case", { desc = "switch case ..." }, SU.myfmt {
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

snip("do", {desc = "do ... end"}, SU.myfmt {
  [[
    do
      <body>
    done
  ]],
  { body = SU.insert_node_default_selection(1) },
})

snip("if", {desc = "if ...; then ... fi"}, SU.myfmt {
  [[
    if <cond>; then
      <body_true>
    fi
  ]],
  {
    cond = ls.choice_node(1, {
      -- In a choiceNode, direct children nodes that normally expect an index don't need one;
      -- their jump-index is the same as the choiceNodes'.
      i(nil, "condition"),
      (SU.myfmt {"[[ <test> ]]", { test = i(1) }}),
    }),
    body_true = i(2),
  },
})

snip("th", {desc = "then ... fi"}, SU.myfmt {
  [[
    then
      <body>
    fi
  ]],
  {
    body = i(1),
  },
})

snip("cond", {desc = "[[ ... ]]"}, SU.myfmt {
  "[[ <test> ]]",
  { test = i(1) },
})

snip("err", {desc = "echo to stderr"}, {
  t">&2 echo ",
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
