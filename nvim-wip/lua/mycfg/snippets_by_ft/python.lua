-- vim:set ft=lua.luasnip:
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

snip("cl", {desc = "class def", when = conds.very_start_of_line}, SU.myfmt {
  [[
    class <name><maybe_parents>:
        <body>
  ]],
  {
    name = i(1, "MyClass"),
    maybe_parents = ls.choice_node(2, {
      t"",
      ls.snippet_node(nil, {t"(", i(1, "object"), t")"})
    }),
    body = SU.insert_node_default_selection(3, "pass"),
  }
})

snip("da", {desc = "dataclass def", when = conds.very_start_of_line}, SU.myfmt {
  [[
    @dataclass<maybe_decor_params>
    class <name><maybe_parents>:
        <body>
  ]],
  {
    name = i(1, "MyData"),
    maybe_decor_params = ls.choice_node(2, {
      t"",
      ls.snippet_node(nil, {t"(", i(1), t")"}),
    }),
    maybe_parents = ls.choice_node(3, {
      t"",
      ls.snippet_node(nil, {t"(", i(1, "object"), t")"}),
    }),
    body = SU.insert_node_default_selection(4, "pass"),
  }
})

snip("fda", {desc = "import for @dataclass", when = conds.very_start_of_line}, {
  t[[from dataclasses import dataclass]]
})

-------------------

-- MAYBE: contribute this snippet generator to LuaSnip's Wiki? 🤔

---@class mysnips.py.DefOpts
---@field decor_name string? Decorator name (if needed)
---@field name string? The def name (not editable)
---@field default_name string? The default def name (editable)
---@field first_arg_name string|false? Name of the first arg (e.g. `self`), or `false`
---@field maybe_arg boolean? Whether def may have more args (alt choice to remove it)
---@field maybe_return_type boolean? Whether def may have return type (alt choice to remove it)
---@field needs_return_type boolean? Whether def must have return type
---@field maybe_no_cover boolean? Whether def may have `# pragma: no cover` (for abstract defs)
---@field simple_body_node (fun(idx_fn: (fun(): integer)): SnipNodeT)?
---    Function that should return a snippet node for the body, takes an index factory function.
---    If not given, it'll default to `pass`.

--- Returns method def snippet for given options
---@param opts mysnips.py.DefOpts
---@return SnipNodeT
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
          ls.snippet_node(nil, { (opts.first_arg_name and t", " or t""), i(1, "arg") }),
          t"",
        })
        or t"" -- nothing
      ),
      maybe_return_type = (
        opts.maybe_return_type and ls.choice_node(next_insert_idx(), {
          ls.snippet_node(nil, {t" -> ", i(1, "Any")}),
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
    decor_name = "property",
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

-- TODO: deft  =>  test functionvim.split("foo", "%.")[1]
-- TODO: deftx  =>  pytest fixture function
-- TODO: pytr  =>  pytest check raise
-- TODO: pytp  =>  pytest parametrize
-- TODO: pyts  =>  pytest mark skip

snip("([%w_]+)=", {desc = "arg=arg auto-fill", trigEngine = "pattern", wordTrig = false}, SU.myfmt {
  [[<param>=<param>]],
  {
    param = ls.function_node(function(_args, snip)
      local snip = snip ---@type SnipT
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
  [[__import__("pprint").pprint(<expr>)  # FIXME: REMOVE DEBUG! # noqa]],
  { expr = SU.insert_node_default_selection(1) }
})

-- GRR: it's reeaalllyyyy lloooonnnggg 😬
snip("ppj", {desc = "debug pretty print data as json", when = conds.start_of_line}, SU.myfmt {
  [[print(__import__("json").dumps(<expr>, indent=4, sort_keys=True))  # FIXME: REMOVE DEBUG! # noqa]],
  { expr = SU.insert_node_default_selection(1, "data") }
})

snip("s", {desc = "self.X = X", when = conds.start_of_line}, SU.myfmt {
  [[self.<name> = <name_again>]],
  {
    name = i(1, "name"),
    name_again = ls.choice_node(2, {
      ls_extras.repeat_node(1), -- same name by default
      i(nil),
    }),
  },
})

snip("s_", {desc = "self._X = X", when = conds.start_of_line}, SU.myfmt {
  [[self._<name> = <name_again>]],
  {
    name = i(1, "name"),
    name_again = ls.choice_node(2, {
      ls_extras.repeat_node(1), -- same name by default
      i(nil),
    }),
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
      ls.snippet_node(nil, {t" as ", i(1, "err")}),
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
      ls.snippet_node(nil, {t" as ", i(1, "err")}),
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
      ls.snippet_node(nil, SU.myfmt {
        "<start>, <end_>",
        {
          start = ls.restore_node(1, "start"),
          end_ = ls.restore_node(2, "end_"),
        }
      }),
      ls.snippet_node(nil, SU.myfmt {
        "<start>, <end_>, <step>",
        {
          start = ls.restore_node(1, "start"),
          end_ = ls.restore_node(2, "end_"),
          step = i(3, "-1"),
        },
      }),
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
  [[reveal_type(<expr>)  # noqa: F821 # TODO: remove probe]],
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

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
