-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

snip("$", { desc = [[$"…"]] }, SU.myfmt {
  [[$"<str>"]],
  { str = i(1) }
})

snip("p", { desc = "print" }, SU.myfmt {
  [[print <arg>]],
  {
    arg = ls.choice_node(1, {
      SU.myfmt { [["<msg>"]], { msg = ls.restore_node(1, "msg") } },
      SU.myfmt { [[$"<msg>"]], { msg = ls.restore_node(1, "msg") } },
    }, {
      -- Seemlessly keep cursor pos across choice branches
      restore_cursor = true
    })
  }
}, {
  stored = {
    -- Keys for ls.restore_node
    -- (used to share nodes between choice node branches)
    msg = i(nil),
  },
})

snip("l", { desc = "local var" }, SU.myfmt {
  [[<mode_and_var> = <end_>]],
  {
    mode_and_var = ls.choice_node(1, {
      SU.myfmt { [[let <var>]], { var = ls.restore_node(1, "var") } },
      SU.myfmt { [[mut <var>]], { var = ls.restore_node(1, "var") } },
      SU.myfmt { [[const <var>]], { var = ls.restore_node(1, "var") } },
    }, { restore_cursor = true }),
    end_ = i(2)
  },
}, {
  stored = {
    var = i(nil, "var"),
  },
})

snip("ld", { desc = "closure (lambda)" }, SU.myfmt {
  [[{<maybe_args> <body> }]],
  {
    maybe_args = ls.choice_node(1, {
      t"",
      {t"|", i(1), t"|"}
    }),
    body = i(2),
  }
})

snip("fn", { desc = "function definition" }, SU.myfmt {
  [[
    def <q><name><q> [<params>]<ret> {
    	<body>
    }
  ]],
  {
    name = i(1, "function name!", {key="name"}),
    q = ls.function_node(function(given_nodes_text)
      -- the function name _must_ have quotes if it contains 1+ spaces
      if given_nodes_text[1][1]:find" " then
        return [["]]
      else
        return ""
      end
    end, {SU.node_ref"name"}),
    params = i(2),
    ret = ls.choice_node(3, {
      SU.myfmt_braces {
        [[: {frompipe} -> {to}]],
        { frompipe = i(1, "nothing"), to = i(2, "nothing") },
      },
      t"",
    }),
    body = i(4)
  }
})
-- TODO: add more variants, like `export`, `--env`, `--wrapped`

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
