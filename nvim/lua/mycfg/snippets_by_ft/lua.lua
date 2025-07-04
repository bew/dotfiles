-- vim:set ft=lua.luasnip:
local U = require"mylib.utils"

local ls = require"luasnip"
local ls_extras = require"luasnip.extras"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils
local conds = require"mycfg.snippets_by_ft._conditions"

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local
local rep = ls_extras.rep

-- Snip Resolvers, to tweak what will be removed exactly before snip expansion
local SR = {}
--- Remove extra spaces after trigger, to always leave cursor 'after space' after snip expansion.
SR.delete_spaces_after_trigger = SU.mk_expand_params_resolver { delete_after_trig = "^%s+" }

-- Start of snippets definitions

-- NOTE: `---@foo` snips must be before others to have a chance to match instead of `@foo`
snip("an", {desc = "LuaCATS @annotation"}, { t"---@" })
-- must be first, ~necessary to avoid `---@` to expand to `------@` with `@` below
snip("---@", {desc = "LuaCATS @annotation"}, { t"---@" })
snip("@", {desc = "LuaCATS @annotation"}, { t"---@" })

--- Generate easy-to-use snippets for the given LuaCATS @annotation
---@param trig string
---@param context mysnips.Context
---@param nodes_factory (fun(): SnipNodeT)
local function snip_lua_annotation(trig, context, nodes_factory, ...)
  assert(trig:sub(1, 1) == "@", "annotation's trigger must start with '@'")
  assert(type(nodes_factory) == "function", "annotation's nodes factory must be a function, got: "..type(nodes_factory))
  local trig_without_at = trig:sub(2)
  do
    -- Allows `---@foo|` or `---foo|` or `--- foo|`
    --   => `---@foo_or_foobar |`
    -- (must be first to have a chance to match before `@foo` below)
    local context_rx = vim.tbl_extend("keep", context, { rx = true })
    snip("%-%-%- ?@?"..trig_without_at, context_rx, nodes_factory(), ...)
  end
  do
    -- [EXPERIMENT]: let's see if it's better to use `anfoo` or `dfoo`
    -- Allows `anfoo|` => `---@foo_or_foobar |`
    -- This is nicer to type on my external split keyboard,
    -- as the snip-trigger finger is also used for `@`
    local context_copy = vim.tbl_extend("keep", context, {})
    snip("an"..trig_without_at, context_copy, nodes_factory(), ...)
  end
  do
    -- Allows `@foo|` => `---@foo_or_foobar |`
    snip(trig, context, nodes_factory(), ...)
  end
end

local function get_class_annotation_nodes()
  return ls.choice_node(1, {
    SU.myfmt {
      [[---@class <name><after>]],
      {
        name = ls.restore_node(1, "class_name"),
        after = i(2), -- avoid exiting too early
      }
    },
    SU.myfmt {
      [[---@class <name>: <inherit_from>]],
      {
        name = ls.restore_node(1, "class_name"),
        inherit_from = i(2, "InheritFromClass")
      }
    },
  }, { restore_cursor = true --[[ Seemlessly keep cursor pos across choice branches ]] })
end
snip_lua_annotation("@cl?", {desc = "LuaCATS @class", rx = true, when = conds.start_of_line}, get_class_annotation_nodes, {
  stored = { class_name = i(nil, "ClassName") },
})
snip("cl", {desc = "LuaCATS @class", when = conds.start_of_line}, get_class_annotation_nodes(), {
  stored = { class_name = i(nil, "ClassName") },
})

snip_lua_annotation("@d", {desc = "LuaCATS @diagnostic disable-for-x"}, function()
  return SU.myfmt {
    "---@diagnostic <action>: <diags><maybe_why>",
    {
      action = ls.choice_node(1, {
        t"disable-next-line",
        t"disable-line",
      }),
      -- IDEA: could default to the diag name of the first hint/warning on the line current/below
      diags = i(2),
      maybe_why = ls.choice_node(3, {
        SU.myfmt_no_strip {
          [[ (<why>)]],
          { why = i(1, "TODO: Reason 🤔") }
        },
        t"",
      }),
    }
  }
end)

snip_lua_annotation("@db", {desc = "LuaCATS @diagnostic toggle-around-block"}, function()
  return SU.myfmt {
    [[
    ---@diagnostic disable: <diags> (<why>)
    <middle>
    ---@diagnostic enable: <diags_again><after>
    ]],
    {
      diags = i(1),
      why = i(2, "TODO: Reason 🤔"),
      middle = SU.insert_node_default_selection(3, "-- YOLO, do random things here!"),
      diags_again = rep(1),
      after = i(4), -- don't exit snip context too fast 😬
    }
  }
end)

snip("@as", {desc = "LuaCATS (inline) @as"}, SU.myfmt {
  "--[[@as <type>]]",
  { type = i(1, "Type") }
})

-- NOTE: must be last to allow custom annotation snips to be found before
do
  local short_to_long_annotation = {
    a = "alias",
    e = "enum",
    f = "field",
    fi = "field private",
    fo = "field protected",
    g = "generic",
    m = "module",
    o = "overload",
    p = "param",
    pri = "private",
    pro = "protected",
    r = "return",
    t = "type",
  }
  for short, long in pairs(short_to_long_annotation) do
    snip_lua_annotation(
      "@"..short,
      {desc = "LuaCATS @"..long, resolver = SR.delete_spaces_after_trigger},
      function()
        return t("---@"..long.." ")
      end
    )
  end
end

--------------------------

-- NOTE: must be after annotations, to avoid matching `---d|`
-- note: Does not include the ending space, I can easily add it and it helps with LuaLS function doc
--   generation (which would otherwise add a space before all generated annotations ><).
snip("d", {desc = "Documentation prefix", resolver = SR.delete_spaces_after_trigger}, { t"---" })

snip("%-%-", {desc = "--[[block comment]]", rx = true}, SU.myfmt {
  "--[[<comment>]]",
  { comment = i(1, "comment") }
})

snip("rq", {desc = [[require"…"]]}, SU.myfmt {
  [[require"<module>"]],
  { module = i(1, "module") },
})

-- Add local var, can only declare on demand
-- Handles many cases:
-- - `|foo = ...`
-- - `| = ...`
-- - (nothing after)
snip("l", {desc = "local var = …", resolver = SR.delete_spaces_after_trigger}, ls.dynamic_node(1, function()
  local rest_of_line = U.get_rest_of_line()
  if rest_of_line:match"^[^ ]+ =" or rest_of_line:match"^function " then
    -- rest_of_line looks like `|foo = ...` or `|function foo...`
    -- only add `local`
    return ls.snippet_node(nil, t"local ")
  end
  local assignment_node
  if rest_of_line:match"^= " then
    -- rest_of_line looks like `|= ...`
    -- (e.g. after we've replaced a var name to put a local var instead)
    -- We don't need the assignment
    assignment_node = t" "
  else
    local has_text_after = not not rest_of_line:match"^[^ ]"
    assignment_node = ls.choice_node(2, {
      SU.myfmt_no_strip {
        [[ = <value>]],
        -- note: default value is important to avoid _breaking_ syntax highlight
        { value = SU.insert_node_default_selection(1, has_text_after and "" or "nil") }
      },
      t"",
    })
  end
  return ls.snippet_node(nil, SU.myfmt {
    [[local <var><assignment>]],
    {
      var = i(1, "var"),
      assignment = assignment_node,
    },
  })
end))

-- NOTE: By default, use custom name for <var>.
-- But I want choice to auto-set <var> as the last part of <modulepath>.
-- 👉 This is actually non-trivial, see: <https://github.com/L3MON4D3/LuaSnip/discussions/1194>
snip("lr", {desc = [[local require"…"]], when = conds.start_of_line}, SU.myfmt {
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

snip("eli", {desc = "elseif ... then"}, SU.myfmt {
  [[elseif <cond> then]],
  { cond = i(1) },
})

snip("th", {desc = "then ... end"}, SU.myfmt {
  [[
    then
      <body>
    end
  ]],
  { body = SU.insert_node_default_selection(1) },
})

snip("thi", {desc = "then … end (inline)"}, SU.myfmt {
  [[then <body> end]],
  { body = i(1) },
})

snip("forn", {desc = "for n in range (including end)", when = conds.start_of_line}, SU.myfmt {
  [[
    for <idx> = <range> do
      <body>
    end
  ]],
  {
    idx = i(1, "n"),
    range = ls.choice_node(2, {
      SU.myfmt {
        "<start>, <end_>",
        {
          start = ls.restore_node(1, "start"),
          end_ = ls.restore_node(2, "end_"),
        }
      },
      SU.myfmt {
        "<start>, <end_>, <step>",
        {
          start = ls.restore_node(1, "start"),
          end_ = ls.restore_node(2, "end_"),
          step = i(3, "-1"),
        },
      },
    }, {
      -- Seemlessly keep cursor pos across choice branches ✨
      restore_cursor = true
    }),
    body = SU.insert_node_default_selection(3),
  }
}, {
  stored = {
    -- Keys for ls.restore_node
    -- (used to share nodes between choice node branches ✨)
    start = i(nil, "1"),
    end_ = i(nil, "10"),
  },
})

snip("fori", {desc = "for each ipairs", when = conds.start_of_line}, SU.myfmt {
  [[
    for <idx>, <value> in ipairs(<tbl>) do
      <body>
    end
  ]],
  {
    idx = i(1, "idx"),
    value = i(2, "value"),
    tbl = i(3, "tbl"),
    body = SU.insert_node_default_selection(4),
  }
})

snip("fork", {desc = "for each pairs", when = conds.start_of_line}, SU.myfmt {
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
    resolver = SR.delete_spaces_after_trigger,
  },
  {
    t"return "
  }
)

snip("!=", {desc = "Lua's != operator"}, { t"~= " })

-- TODO(treesitter): only when cursor is at a 'statement' scope
--   (or NOT in a table def nor in an fn arguments list)
snip("fn", {desc = "function def", when = conds.start_of_line}, SU.myfmt {
  [[
    <maybe_local>function <name>(<args>)
      <body>
    end
  ]],
  {
    name = i(1, "function_name", {key="name"}),
    -- NOTE: Only add `local` for simple function names. When using `M.foo` (or more nesting) the
    --   `local` is hidden as it doesn't make sense as the function is in some table.
    maybe_local = ls.function_node(function(given_nodes_text)
      ---@type string
      local fn_name = given_nodes_text[1][1]
      vim.notify("fn_name: " .. fn_name)
      if fn_name:match"%." or fn_name:match":" then
        return ""
      else
        return "local "
      end
    end, {SU.node_ref"name"}),
    args = i(2),
    body = SU.insert_node_default_selection(3),
  },
})
-- A snippet for the function type, must be on a `---@something` line (after).
-- NOTE: Must be before anon fn def to have a chance to match
snip("fn", {desc = "annotation for function type", when = conds.line_before_matches"%-%-%-@"}, SU.myfmt {
  [[(fun(<args>): <ret>)]],
  {
    args = ls.choice_node(1, {
      i(nil),
      SU.myfmt {
        [[<param>: <ty><maybe_more>]],
        {
          param = i(1, "param"),
          ty = i(2, "any"),
          maybe_more = i(3),
        },
      },
    }),
    ret = i(2, "any"),
  }
})
-- NOTE: condition is reversed (with `-` before condition obj),
--   to activate when the usual snippet (with name) is not active.
snip("fn", {desc = "function def (anon)", when = -conds.start_of_line}, SU.myfmt {
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

snip("lfn", {desc = "local function def", when = conds.start_of_line}, SU.myfmt {
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

snip("pp", {desc = "pretty print / inspect"}, SU.myfmt {
  [[print("DEBUG", "<prompt>:", vim.inspect(<expr>))]],
  {
    prompt = i(1, "debug this thing"),
    expr = SU.insert_node_default_selection(2)
  }
})

snip("ins", {desc = "vim.inspect(..)"}, SU.myfmt {
  [[vim.inspect(<expr>)]],
  { expr = SU.insert_node_default_selection(1) }
})

snip("mod", {desc = "Module init M = {}; ret M", when = conds.very_start_of_line}, SU.myfmt {
  [[
    local <mod_name> = {}

    <content>

    return <mod_name_ret>
  ]],
  {
    mod_name = i(1, "M"),
    content = SU.insert_node_default_selection(2),
    mod_name_ret = rep(1)
  },
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
