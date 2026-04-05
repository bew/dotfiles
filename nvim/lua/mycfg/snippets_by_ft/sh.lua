-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local ls_extras = require"luasnip.extras"
ls_extras.repeat_node = ls_extras.rep

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

-- MAYBE(?): allow adding as many vars at decl step? (easier for the decl-first variant 🤔)
-- but how to still properly support switching from one form to the other?..
snip("l", { desc = "local var decl/def" }, ls.choice_node(1, {
  SU.myfmt_braces {
    "local {var}={after}",
    {
      var = ls.restore_node(1, "var"),
      after = ls.restore_node(2, "after"),
    },
  },
  SU.myfmt_braces {
    [[
      local {var}
      {var_again}={after}
    ]],
    {
      var = ls.restore_node(1, "var"),
      var_again = ls_extras.repeat_node(1),
      after = ls.restore_node(2, "after"),
    },
  },
}), {
  stored = {
    -- Keys for ls.restore_node
    -- (used to share nodes between choice node branches ✨)
    var = i(nil, "var"),
    after = i(nil),
  },
})

snip("fn", { desc = "function foo() { ... }" }, SU.myfmt {
  [[
    function <name>() {
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
      SU.myfmt {"[[ <test> ]]", { test = ls.restore_node(1, "test") } },
      SU.myfmt {"(( <test> ))", { test = ls.restore_node(1, "test") } },
    }),
    body_true = i(2),
  },
}, {
  stored = {
    -- Keys for ls.restore_node
    -- (used to share nodes between choice node branches ✨)
    test = i(nil),
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

snip("cond", {desc = "[[ ... ]]"}, ls.choice_node(1, {
  SU.myfmt { "[[ <test> ]]", { test = ls.restore_node(1, "test") } },
  SU.myfmt { "(( <test> ))", { test = ls.restore_node(1, "test") } },
}), {
  stored = {
    -- Keys for ls.restore_node
    -- (used to share nodes between choice node branches ✨)
    test = i(1),
  },
})

snip("err", {desc = "echo to stderr"}, {
  t">&2 echo ",
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
