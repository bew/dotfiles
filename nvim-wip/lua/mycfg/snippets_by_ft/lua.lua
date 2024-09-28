-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local ls_extras = require"luasnip.extras"
local U = require"mycfg.snippets_by_ft._utils"

local SNIPS = {}
local snip = U.get_snip_fn(SNIPS)

local i = ls.insert_node
local t = ls.text_node
local rep = ls_extras.rep

-- Start of snippets definitions

snip("rq", {desc = [[require"…"]]}, U.myfmt {
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

-- On call, I'm first on <module>. as I write the module name I want <var> to be the last part of
-- <module> unless I change it manually.
-- 👉 This is actually non-trivial, see: <https://github.com/L3MON4D3/LuaSnip/discussions/1194>
-- snip("lr", {desc = "local require"}, U.myfmt {
--   [[local <var> = require"<module>"]],
--   {
--     module = i(1, "module", {key="mod-name"}),
--
--     -- must be the 'last part of <module>' except if I set it to something else
--     var = ls.dynamic_node(
--       2,
--       function(given_nodes_text)
--         return ls.snippet_node(nil, { ls.restore_node(1, "var-name", i(nil, given_nodes_text[1])) })
--       end,
--       {U.node_ref"mod-name"}
--     )
--   },
-- })
--
-- Since having the local variable be dynamic, let's opt for the basic simple solution for now…
snip("lr", {desc = [[local require"…"]]}, U.myfmt {
  [[local <var> = require"<module>"]],
  {
    module = i(1, "some.module"),
    var = i(2, "var"),
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

snip("if", {desc = "if ... then ... end"}, U.myfmt {
  [[
    if <cond> then
      <body>
    end
  ]],
  {
    cond = i(1),
    body = i(2),
  },
})

snip("then", {desc = "then ... end"}, U.myfmt {
  [[
    then
      <body>
    end
  ]],
  { body = i(0) },
})
snip("th", {desc = "then ... end"}, U.myfmt {
  [[
    then
      <body>
    end
  ]],
  { body = i(0) },
})

snip("fori", {desc = "for each ipairs"}, U.myfmt {
  [[
    for <idx>, <value> in ipairs(<tbl>) do
      <body>
    end
  ]],
  {
    idx = i(1, "i"),
    value = i(2, "value"),
    tbl = i(3, "tbl"),
    body = i(0),
  }
})

snip("fork", {desc = "for each pairs"}, U.myfmt {
  [[
    for <key>, <value> in pairs(<tbl>) do
      <body>
    end
  ]],
  {
    key = i(1, "key"),
    value = i(2, "value"),
    tbl = i(3, "tbl"),
    body = i(0),
  }
})

snip("rt", {desc = "return ..."}, U.myfmt {
  [[return<maybe_space><rest>]],
  {
    rest = i(0),
    -- FIXME: remove space if there is already a space after cursor.
    -- e.g: with `foo = bar`, when I do `^cf=rt<TAB>` the snip should not have a trailing space
    maybe_space = t" ",
  },
})

snip("!=", {desc = "Lua's != operator"}, { t"~= " })

-- TODO: when cursor has text before, <maybe_name> should be skipped
-- TODO(treesitter): same when cursor is not at a 'statement' scope
snip("fn", {desc = "function def"}, U.myfmt {
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
snip("lfn", {desc = "local function def"}, U.myfmt {
  [[
    local function <name>(<args>)
      <body>
    end
  ]],
  {
    name = i(1),
    args = i(2),
    body = i(3),
  },
})

snip("p", {desc = "print(...)"}, U.myfmt {
  [[print(<stuff>)]],
  { stuff = i(1) }
})

snip("mod", {desc = "Module init M = {}; ret M"}, U.myfmt {
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
