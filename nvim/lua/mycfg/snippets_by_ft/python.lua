-- vim:set ft=lua.luasnip:
local U = require"mylib.utils"

local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils
local conds = require"mycfg.snippets_by_ft._conditions"

local ls_extras = require"luasnip.extras"
ls_extras.repeat_node = ls_extras.rep

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

-- TODO: Split snips in multiple files for **large** topics 🤔

snip("ffa", {desc = "lazy annotation import", when = conds.very_start_of_line}, (
  t"from __future__ import annotations"
))

snip("fy", {desc = "from typing import …", when = conds.very_start_of_line}, (
  t"from typing import "
))

snip("cl", {desc = "class def", when = conds.start_of_line}, SU.myfmt {
  [[
    class <name><maybe_parents>:
        <body>
  ]],
  {
    name = i(1, "MyClass"),
    maybe_parents = ls.choice_node(2, {
      t"",
      { t"(", i(1, "object"), t")" },
    }),
    body = SU.insert_node_default_selection(3, "pass"),
  }
})

snip("dc", {desc = "data-only class", when = conds.start_of_line}, SU.myfmt {
  [[
    @dataclass<maybe_decor_params>
    class <name><maybe_parents>:
        <body>
  ]],
  {
    name = i(1, "MyData"),
    maybe_decor_params = ls.choice_node(2, {
      t"",
      { t"(", i(1), t")" },
    }),
    maybe_parents = ls.choice_node(3, {
      t"",
      { t"(", i(1, "object"), t")" },
    }),
    body = SU.insert_node_default_selection(4, "pass"),
  }
})

snip("fdc", {desc = "import for @dataclass", when = conds.start_of_line}, ls.choice_node(1, {
  t[[from dataclasses import dataclass]],
  t[[from pydantic.dataclasses import dataclass]],
}))

-------------------

-- MAYBE: contribute this snippet generator to LuaSnip's Wiki? 🤔

---@class mysnips.Opts.py.Def
---@field decor_name string? Decorator name (if needed)
---@field name string? The def name (not editable)
---@field default_name string? The default def name (editable)
---@field first_arg_name string|false? Name of the first arg (e.g. `self`), or `false`
---@field maybe_arg boolean? Whether def may have more args (alt choice to remove it)
---@field maybe_return_type boolean? Whether def may have return type (alt choice to remove it)
---@field needs_return_type boolean? Whether def must have return type
---@field maybe_no_cover boolean? Whether def may have `# pragma: no cover` (for abstract defs)
---@field simple_body_node (fun(idx_fn: (fun(): integer)): LuaSnip.Node)?
---    Function that should return a snippet node for the body, takes an index factory function.
---    If not given, it'll default to `pass`.

--- Returns method def snippet for given options
---@param opts mysnips.Opts.py.Def
---@return LuaSnip.Node
local function make_def_snip(opts)
  opts = opts or {}

  local current_insert_idx = 0
  local function next_insert_idx()
    current_insert_idx = current_insert_idx + 1
    return current_insert_idx
  end

  return SU.myfmt {
    -- NOTE: we don't use [[…]] string to be able to optionally have a decorator,
    --   without leaving a blank line or breaking expansion indent.
    (
      (opts.decor_name and "<decor>\n" or "") ..
      "def <name>(<first_arg><maybe_arg>)<maybe_return_type>:<maybe_no_cover>\n" ..
      "    <body>"
    ),
    {
      decor = (
        opts.decor_name and t("@" .. opts.decor_name)
        or nil -- key should not be defined (fmt placeholder don't exist)
      ),
      name = (
        opts.name and t(opts.name)
        or i(
          next_insert_idx(), opts.default_name,
          {key="def-name"}
        )
      ),
      first_arg = (
        opts.first_arg_name and t(opts.first_arg_name)
        or t"" -- nothing
      ),
      maybe_arg = (
        opts.maybe_arg and ls.choice_node(next_insert_idx(), {
          { (opts.first_arg_name and t", " or t""), i(1, "arg") },
          t"",
        })
        or t"" -- nothing
      ),
      maybe_return_type = (
        opts.maybe_return_type and ls.choice_node(next_insert_idx(), {
          { t" -> ", i(1, "Any") },
          t"",
        })
        or opts.needs_return_type and ls.snippet_node(next_insert_idx(), {t" -> ", i(1, "Any")})
        or t"" -- nothing
      ),
      maybe_no_cover = (
        opts.maybe_no_cover and ls.choice_node(next_insert_idx(), {
          t"  # pragma: no cover",
          t"",
        })
        or t"" -- nothing
      ),
      body = (
        opts.simple_body_node and opts.simple_body_node(next_insert_idx)
        or SU.insert_node_default_selection(next_insert_idx(), "pass")
      ),
    }
  }
end

snip(
  "def", {desc = "function def", when = conds.very_start_of_line},
  make_def_snip {
    default_name = "function_name",
    first_arg_name = false, -- no first arg
    maybe_arg = true,
    maybe_return_type = true,
  }
)

-- Example:
-- ```py
-- def __init__(self, arg):
--     pass
-- ```
snip(
  "def", {desc = "method def", when = conds.after_indent},
  make_def_snip {
    default_name = "method_name",
    first_arg_name = "self",
    maybe_arg = true,
    maybe_return_type = true,
  }
)

-- Example:
-- ```py
-- def __init__(self, arg):
--     pass
-- ```
snip(
  "defi", { desc = "initializer def", when = conds.after_indent },
  make_def_snip {
    name = "__init__",
    first_arg_name = "self",
    maybe_arg = true,
    return_type = false,
  }
)

-- Example:
-- ```py
-- @abstractmethod
-- def method_name(self, arg) -> Any:  # pragma: no cover
--     pass
-- ```
snip(
  "defa", { desc = "abstract method def", when = conds.after_indent },
  make_def_snip {
    decor_name = "abstractmethod",
    default_name = "method_name",
    first_arg_name = "self",
    maybe_arg = true,
    maybe_return_type = true,
    maybe_no_cover = true,
    simple_body_node = function(next_insert_idx)
      return ls.choice_node(next_insert_idx(), {
        t"pass",
        ls.dynamic_node(nil, function(given_nodes_text)
          local def_name = given_nodes_text[1][1]
          return ls.snippet_node(nil, SU.myfmt {
            [[raise NotImplementedError("<msg>"<after>)]],
            {
              msg = i(1, "Function '"..def_name.."' must be implemented in subclass!"),
              after = i(2),
            }
          })
        end, {SU.node_ref"def-name"})
      })
    end,
  }
)

-- Example:
-- ```py
-- @abstractproperty
-- def prop_name(self) -> Any:
--     pass
-- ```
snip(
  "defap", { desc = "abstract property def", when = conds.after_indent },
  make_def_snip {
    decor_name = "abstractproperty",
    default_name = "prop_name",
    first_arg_name = "self",
    maybe_arg = false,
    return_type = true, -- not optional
    maybe_no_cover = true,
  }
)

-- Example:
-- ```py
-- @classmethod
-- def function_name(self, arg) -> Any:
--     pass
-- ```
snip(
  "defc", { desc = "class method def", when = conds.after_indent },
  make_def_snip {
    decor_name = "classmethod",
    default_name = "function_name",
    first_arg_name = "cls",
    maybe_arg = true,
    maybe_return_type = true,
  }
)

-- Example:
-- ```py
-- @staticmethod
-- def function_name(self, arg) -> Any:
--     pass
-- ```
snip(
  "defs", { desc = "static method def", when = conds.after_indent },
  make_def_snip {
    decor_name = "staticmethod",
    default_name = "function_name",
    first_arg_name = false, -- no first arg
    maybe_arg = true,
    maybe_return_type = true,
  }
)

-- Example:
-- ```py
-- @property
-- def prop_name(self) -> Any:
--     pass
-- ```
snip(
  "defp", { desc = "property def", when = conds.after_indent },
  make_def_snip {
    decor_name = "property", -- TODO: allow choice_node with `property` / `cached_property`
    default_name = "prop_name",
    first_arg_name = "self",
    return_type = true, -- not optional
  }
)

-- Example:
-- ```py
-- @property
-- def prop_name(self) -> Any:
--     return self._prop_name
-- ```
snip(
  "defpr", { desc = "property def (getter for _prop)", when = conds.after_indent },
  make_def_snip {
    decor_name = "property",
    default_name = "prop_name",
    first_arg_name = "self",
    return_type = true, -- not optional
    simple_body_node = function()
      return ls.function_node(function(given_nodes_text)
        return "return self._" .. given_nodes_text[1][1]
      end, {SU.node_ref"def-name"})
    end,
  }
)

-------------------

snip("deft", { desc = "def test function", when = conds.start_of_line }, SU.myfmt {
  [[
  <deco>def test_<name>(<args>):
    <body>
  ]],
  {
    deco = ls.choice_node(1, {
      t{"@pytest.mark.unit", ""},
      t"",
    }),
    name = i(2, "something_is_working"),
    args = i(3),
    body = i(4, [[assert False, "TODO: write a test!"]]),
  }
})

snip("deftx", { desc = "pytest fixture function", when = conds.start_of_line }, SU.myfmt {
  [[
  @pytest.fixture<params>
  def <name>(<args>) <arrow> <ret>:
    <body>
  ]],
  {
    params = ls.choice_node(1, {
      -- @pytest.fixture${1:(scope="${2:function}"${3:, autouse=True})}
      -- def ${10:some_prefilled_obj}($20) -> ${30:Any}:
      SU.myfmt {
        [[(scope="<scope>"<autouse>)]],
        {
          scope = i(1, "function"),
          autouse = i(2, ", autouse=True"),
          -- note: 'autouse' part is an insert node to avoid nested choice node,
          --   and to be easy to delete in 1 backspace.
        }
      },
      t"",
    }),
    name = i(2, "some_prefilled_obj"),
    args = i(3),
    arrow = t"->", -- to avoid bare `>` in fmt string conflicting with placeholders
    ret = i(4, "Any"),
    body = SU.insert_node_default_selection(5, "pass"),
  }
})

snip("pytr", { desc = "pytest check raise" }, SU.myfmt {
  [[
  with pytest.raises(<ex><maybe_match><after_args>):
    <body>
  ]],
  {
    ex = i(1, "MyException"),
    maybe_match = ls.choice_node(2, {
      SU.myfmt {
        [[, match=r"<txt>"]],
        { txt = i(1, "matching text") }
      },
      t"",
    }),
    after_args = i(3),
    body = SU.insert_node_default_selection(4, "pass"),
  }
})

snip("pytm", { desc = "pytest mark decorator", when = conds.start_of_line }, {
  t"@pytest.mark."
})

snip("pytp", { desc = "pytest parametrize" }, SU.myfmt {
  [[
  @pytest.mark.parametrize(
    "<params>",
    [
      (<values>),<end_>
    ],
  )
  ]],
  {
    params = i(1, "param1, param2"),
    values = i(2, "value1, value2"),
    end_ = i(3),
  }
})

-------------------

snip("([%w_]+)=", {desc = "arg=arg auto-fill", rx = true, wordTrig = false}, SU.myfmt {
  [[<param>=<param>]],
  {
    param = ls.function_node(function(_args, snip)
      ---@cast snip LuaSnip.Snippet (I know I have a snippet here!)
      return snip.env.LS_CAPTURE_1
    end),
  },
})

-- Docstrings-related snips
snip("dd", {desc = [["""Doc…"""]]}, SU.myfmt {
  [["""<doc>"""]],
  { doc = i(1, "TODO: doc!") }
})
snip(":p", {desc = ":param <foo>: …", when = conds.start_of_line}, SU.myfmt {
  [[:param <param>: <desc>]],
  {
    param = i(1, "my_param"),
    desc = i(2, "TODO: describe!"),
  }
})
snip(":x", {desc = ":raises <Error>: …", when = conds.start_of_line}, SU.myfmt {
  [[:raises <errors>: <desc>]],
  {
    errors = i(1, "my_param"),
    desc = i(2, "TODO: describe!"),
  }
})
snip(":r", {desc = ":return: …", when = conds.start_of_line}, t":return: ")

-------------------

snip("f", {desc = "f-string"}, SU.myfmt {
  [[f"<msg>"]],
  { msg = i(1) },
})

snip("p", {desc = "print(…)"}, SU.myfmt {
  [[print(<stuff>)]],
  { stuff = i(1) }
})

snip("pf", {desc = "print(f-string…)"}, SU.myfmt {
  [[print(f"<msg>"<rest>)]],
  {
    msg = i(1),
    rest = i(2),
  },
})

snip("pp", {desc = "debug pretty print (…)", when = conds.start_of_line}, SU.myfmt {
  [[__import__("pprint").pprint(<expr>)  # (!!) REMOVE DEBUG!]],
  { expr = SU.insert_node_default_selection(1) }
})

-- GRR: it's reeaalllyyyy lloooonnnggg 😬
snip("ppj", {desc = "debug pretty print data as json", when = conds.start_of_line}, SU.myfmt {
  [[
    __debug_expr = <expr>  # (!!) REMOVE DEBUG!
    print(__import__("json").dumps(__debug_expr, indent=4, sort_keys=True))  # (!!) REMOVE DEBUG!
  ]],
  { expr = SU.insert_node_default_selection(1, "data") }
})

snip("s", {desc = "self.X = …", when = conds.start_of_line}, SU.myfmt {
  [[self.<name> = <value>]],
  {
    name = ls.choice_node(1, {
      { t"_", ls.restore_node(1, "name") },
      { ls.restore_node(1, "name") },
    }, { restore_cursor = true }),
    value = SU.insert_node_default_selection(2, "")
  },
}, {
  stored = {
    name = i(nil, "name")
  }
})

snip("ss", {desc = "self._?X = X (~repeated)", when = conds.start_of_line}, ls.choice_node(1, {
  SU.myfmt {
    [[self._<name_again> = <name>]],
    {
      name = ls.restore_node(1, "name"),
      name_again = ls_extras.repeat_node(1), -- same as written node
    },
  },
  SU.myfmt {
    [[self.<name_again> = <name>]],
    {
      name = ls.restore_node(1, "name"),
      name_again = ls_extras.repeat_node(1), -- same as written node
    },
  },
}, { restore_cursor = true }), {
  stored = {
    -- Keys for ls.restore_node
    name = i(nil, "name")
  },
})

-- NOTE: Adds the space after `return` only if needed,
--   but _always_ leave the cursor after the space.
snip(
  "r",
  {
    desc = "return …",
    -- Tweak what will be removed exactly before snip expansion
    -- Remove extra spaces after trigger, to always leave cursor 'after space' after snip expansion.
    resolveExpandParams = SU.mk_expand_params_resolver { delete_after_trig = "^%s+" },
  },
  {
    t"return "
  }
)

snip("ld", {desc = "lambda"}, t"lambda")

snip("try", {desc = "try … except …", when = conds.start_of_line}, SU.myfmt {
  [[
    try:
        <body>
    except <ex_type><maybe_ex_name>:
        <handler>
  ]],
  {
    body = SU.insert_node_default_selection(1, "# do something useful.."),
    ex_type = i(2, "SomeException"),
    maybe_ex_name = ls.choice_node(3, {
      { t" as ", i(1, "err") },
      t"",
    }),
    handler = i(4, "pass"),
  }
})

snip("ex", {desc = "except …", when = conds.start_of_line}, SU.myfmt {
  [[
    except <ex_type><maybe_ex_name>:
        <handler>
  ]],
  {
    ex_type = i(1, "SomeException"),
    maybe_ex_name = ls.choice_node(2, {
      { t" as ", i(1, "err") },
      t"",
    }),
    handler = i(3, "pass"),
  }
})

snip("forkv", {desc = "for loop over keys", when = conds.start_of_line}, SU.myfmt {
  [[
    for <key>, <value> in <dict>.items():
        <body>
  ]],
  {
    dict = i(1, "somedict"),
    key = i(2, "_key"),
    value = i(3, "_value"),
    body = i(4, "pass"),
  },
})

snip("forn", {desc = "for n in range", when = conds.start_of_line}, SU.myfmt {
  [[
    for <item> in range(<range_args>):
        <body>
  ]],
  {
    item = i(1, "item"),
    range_args = ls.choice_node(2, {
      i(nil, "num_iterations"),
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
      -- Seemlessly keep cursor pos across choice branches
      restore_cursor = true
    }),
    body = i(3, "pass"),
  },
}, {
  stored = {
    -- Keys for ls.restore_node
    -- (used to share nodes between choice node branches)
    start = i(nil, "1"),
    end_ = i(nil, "10"),
  },
})

snip("for", {desc = "for item in iterable", when = conds.start_of_line}, SU.myfmt {
  [[
    for <item> in <iterable>:
        <body>
  ]],
  {
    item = i(1, "item"),
    iterable = i(2, "someiterable"),
    body = i(3, "pass"),
  },
})

snip("o", {desc = "Foo | None"}, SU.myfmt {
  [[<type> | None]],
  { type = SU.insert_node_default_selection(1, "SomeType") }
})

snip("on", {desc = "Foo | None = None"}, SU.myfmt {
  [[<type> | None = None]],
  { type = SU.insert_node_default_selection(1, "SomeType") }
})

snip("rt", {desc = "reveal type", when = conds.start_of_line}, SU.myfmt {
  -- note: `(!!)` allows to draw attention without eating too much editor space for the hint
  [[reveal_type(<expr>)  # noqa: F821 (!!)]],
  { expr = SU.insert_node_default_selection(1) }
})
snip("rt", {desc = "reveal type (in expr)"}, SU.myfmt {
  [[reveal_type(<expr>)]],
  { expr = SU.insert_node_default_selection(1) }
})

snip("bp", {desc = "Add breakpoint here"}, SU.myfmt {
  [[breakpoint()<maybe_reminder>]],
  {
    maybe_reminder = ls.choice_node(1, {
      t"  # FIXME: REMOVE DEBUG PROBE!",
      t"",
    }),
  },
})
snip("bpt", {desc = "Add pytest breakpoint"}, SU.myfmt {
  [[__import__("pytest").set_trace()<maybe_reminder>]],
  {
    maybe_reminder = ls.choice_node(1, {
      t"  # FIXME: REMOVE DEBUG PROBE!",
      t"",
    }),
  },
})

snip("maincli", {desc = "minimal setup for main(args) & cli parsing", when = conds.very_start_of_line}, SU.myfmt {
  -- NOTE: the `->>` is just a way to escape `>` to avoid having it
  -- NOTE: `move_to_top` is not on the first instance, because having insert mode just after an
  --   identifier triggers the completion popup, which is absolutely not useful ><
  [[
    import argparse<move_to_top_again>
    import sys<move_to_top_again>


    class ScriptError(Exception):<move_to_top>
        pass


    def parse_args(args) ->> argparse.Namespace:
        parser = argparse.ArgumentParser()
        return parser.parse_args(args)


    def main(args):
        opts = parse_args(args)
        <body>


    if __name__ == "__main__":
        try:
            main(sys.argv[1:])
        except ScriptError as err:
            print(f"ERROR: {err}", file=sys.stderr)
            sys.exit(1)<after>
  ]],
  {
    move_to_top = ls.choice_node(1, {
      t"  # TODO: move to top!",
      t"",
    }),
    move_to_top_again = ls_extras.repeat_node(1),
    body = SU.insert_node_default_selection(2, "# do something useful!"),
    after = i(3),
  },
})

snip("mainsimple", {desc = "simple main() script", when = conds.very_start_of_line}, SU.myfmt {
  [[
    def main():
        <body>


    if __name__ == "__main__":
        main()<after>
  ]],
  {
    body = SU.insert_node_default_selection(1, "pass"),
    after = i(2),
  }
})

snip("ifmain", {desc = "if module is main", when = conds.very_start_of_line}, SU.myfmt {
  [[
    if __name__ == "__main__":
        <body>
  ]],
  {
    body = SU.insert_node_default_selection(1, "pass"),
  }
})

-- FIXME: 🙁 FAILS in all of these cases:
-- ```py
-- class Fail1:
--     def foo(self):
--         | <- cursor
--
-- class Fail2:
--     def foo(self):
--         something before
--         | <- cursor
--
-- class Fail3:
--     def foo(self):
--         | <- cursor
--         something after
-- ```
-- Because at this point the direct TS parent is either of type 'class_definition' or 'block',
-- instead of being the `foo` function node 🙁
--
-- 👉 TOTRY: Find immediate function node parent based on current indent
snip("su", {desc = "super().samefunction(…)"}, ls.dynamic_node(1, function()
  -- IDEA: Suggest that returning nil in a `dynamic_node` be the same as returning an empty snippet node 🤔
  local failure_sn = ls.snippet_node(nil, t"")

  local node = U.ts.try_get_node_at_cursor { show_warning = true }
  if not node then return failure_sn end

  local parents = U.ts.collect_node_parents(node, { until_node_type = "class_definition" })
  if #parents == 0 or parents[1]:type() ~= "class_definition" then
    vim.notify("!! Not in a class!", vim.log.levels.ERROR)
    return failure_sn
  end

  -- find first 'function_definition' node
  ---@type TSNode?
  local class_function_node = vim.iter(parents):find(function(p) return p:type() == "function_definition" end)
  if not class_function_node then
    vim.notify("!! Not in a class function node!", vim.log.levels.ERROR)
    return failure_sn
  end

  local fn_name_node = class_function_node:field("name")[1]
  local fn_name = vim.treesitter.get_node_text(fn_name_node, 0)

  return ls.snippet_node(nil, { t("super()." .. fn_name .. "("), i(1), t")" })
end))

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
