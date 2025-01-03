-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local ls_extras = require"luasnip.extras"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils
local conds = require"mycfg.snippets_by_ft._conditions"

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

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

snip("data", {desc = "dataclass def", when = conds.very_start_of_line}, SU.myfmt {
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

snip("fromd", {desc = "import for @dataclass", when = conds.very_start_of_line}, {
  t[[from dataclasses import dataclass]]
})

-------------------

--- Returns method def snippet for given *opts*
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
        or opts.return_type and ls.snippet_node(next_insert_idx(), {t" -> ", i(1, "Any")})
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
  "def",
  {desc = "function def", when = conds.very_start_of_line},
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
  "def",
  {desc = "method def", when = conds.after_indent},
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

-- TODO: Split snips in multiple files for **large** topics

-- TODO: #!  =>  python shebang
-- TODO: foo=  =>  foo=foo
-- TODO: deft  =>  test function
-- TODO: deftx  =>  pytest fixture function
-- TODO: ifmain  =>  if name is main ...
-- TODO: mainsimple  =>  basic main fn
-- TODO: for  =>  for loop
-- TODO: try  =>  try except block
-- TODO: doc  =>  """Doc"""
-- TODO: :p  =>  :param …: doc
-- TODO: pp  =>  pretty print (inline import)
-- TODO: f  =>  f"blabla"
-- TODO: s  =>  self.X = X
-- TODO: s_  =>  self._X = X
-- TODO: opt  =>  Foo | None
-- TODO: optn  =>  Foo | None = None
-- TODO: ld  =>  lambda
-- TODO: bp  =>  breakpoint()
-- TODO: bpt  =>  pytest breakpoint
-- TODO: rty  =>  reveal_type(…)
-- TODO: pytr  =>  pytest check raise
-- TODO: pytp  =>  pytest parametrize
-- TODO: pyts  =>  pytest mark skip


-------------------

snip("p", {desc = "print(...)"}, SU.myfmt {
  [[print(<stuff>)]],
  { stuff = i(1) }
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

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
