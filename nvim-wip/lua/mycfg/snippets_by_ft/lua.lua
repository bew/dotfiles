-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local ls_extras = require"luasnip.extras"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils
local conds = require"mycfg.snippets_by_ft._conditions"

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node
local t = ls.text_node
local rep = ls_extras.rep

-- Start of snippets definitions

snip("rq", {desc = [[require"…"]]}, SU.myfmt {
  [[require"<module>"]],
  { module = i(1, "module") },
})

snip("l", {desc = "local var = ..."}, SU.myfmt {
  [[local <var> = <value>]],
  {
    var = i(1, "var"),
    value = SU.insert_node_default_selection(2),
  },
})

-- NOTE: By default, use custom name for <var>.
-- But I want choice to auto-set <var> as the last part of <modulepath>.
-- 👉 This is actually non-trivial, see: <https://github.com/L3MON4D3/LuaSnip/discussions/1194>
snip("lr", {desc = [[local require"…"]], condition = conds.start_of_line}, SU.myfmt {
  [[local <var> = require"<modulepath>"]],
  {
    modulepath = i(1, "the.module", {key="mod-path"}),

    -- choice node for custom name or 'last part of <modulepath>'
    var = ls.choice_node(2, {
      i(nil, "customname"),
      ls.function_node(
        function(given_nodes_text)
          local module_name = given_nodes_text[1][1]
          local last_part = vim.iter(vim.gsplit(module_name, ".", {plain=true})):last()
          return last_part
        end,
        {SU.node_ref"mod-path"}
      ),
    })
  },
})

snip("do", {desc = "do ... end"}, SU.myfmt {
  [[
    do
      <body>
    end
  ]],
  { body = SU.insert_node_default_selection(1) },
})

snip("if", {desc = "if ... then ... end"}, SU.myfmt {
  [[
    if <cond> then
      <body>
    end
  ]],
  {
    cond = i(1),
    body = SU.insert_node_default_selection(2),
  },
})

snip("then", {desc = "then ... end"}, SU.myfmt {
  [[
    then
      <body>
    end
  ]],
  { body = SU.insert_node_default_selection(1) },
})

snip("th", {desc = "then ... end"}, SU.myfmt {
  [[
    then
      <body>
    end
  ]],
  { body = SU.insert_node_default_selection(1) },
})

snip("fori", {desc = "for each ipairs", condition = conds.start_of_line}, SU.myfmt {
  [[
    for <idx>, <value> in ipairs(<tbl>) do
      <body>
    end
  ]],
  {
    idx = i(1, "i"),
    value = i(2, "value"),
    tbl = i(3, "tbl"),
    body = SU.insert_node_default_selection(4),
  }
})

snip("fork", {desc = "for each pairs", condition = conds.start_of_line}, SU.myfmt {
  [[
    for <key>, <value> in pairs(<tbl>) do
      <body>
    end
  ]],
  {
    key = i(1, "key"),
    value = i(2, "value"),
    tbl = i(3, "tbl"),
    body = SU.insert_node_default_selection(4),
  }
})

-- NOTE: Adds the space after `return` only if needed,
--   but _always_ leave the cursor after the space.
snip(
  "r",
  {
    desc = "return ...",
    -- Tweak what will be removed exactly before snip expansion
    -- Remove extra spaces after trigger, to always leave cursor 'after space' after snip expansion.
    resolveExpandParams = SU.mk_expand_params_resolver { delete_after_trig = "^%s+" },
  },
  {
    t"return "
  }
)

snip("!=", {desc = "Lua's != operator"}, { t"~= " })

-- TODO(treesitter): only when cursor is at a 'statement' scope
snip("fn", {desc = "function def", condition = conds.start_of_line}, SU.myfmt {
  [[
    function<maybe_name>(<args>)
      <body>
    end
  ]],
  {
    maybe_name = ls.choice_node(1, {
      ls.snippet_node(nil, {t" ", i(1, "function_name")}),
      t"",
    }),
    args = i(2),
    body = SU.insert_node_default_selection(3),
  },
})
-- NOTE: condition is reversed with `-` before condition obj,
--   to activate when the usual snippet (with name) is not active.
snip("fn", {desc = "function def (anon)", condition = -conds.start_of_line}, SU.myfmt {
  [[
    function(<args>)
      <body>
    end
  ]],
  {
    args = i(1),
    body = SU.insert_node_default_selection(2),
  },
})

snip("fni", {desc = "function def (inline, anon)"}, SU.myfmt {
  [[
    function(<args>) <body> end
  ]],
  {
    args = i(1),
    body = SU.insert_node_default_selection(2),
  },
})

snip("lfn", {desc = "local function def", condition = conds.start_of_line}, SU.myfmt {
  [[
    local function <name>(<args>)
      <body>
    end
  ]],
  {
    name = i(1, "function_name"),
    args = i(2),
    body = SU.insert_node_default_selection(3),
  },
})

snip("p", {desc = "print(..)"}, SU.myfmt {
  [[print(<stuff>)]],
  { stuff = i(1) }
})

snip("mod", {desc = "Module init M = {}; ret M", condition = conds.very_start_of_line}, SU.myfmt {
  [[
    local <mod_name> = {}

    <content>

    return <mod_name_ret>
  ]],
  {
    mod_name = i(1, "M"),
    content = i(0),
    mod_name_ret = rep(1)
  },
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
