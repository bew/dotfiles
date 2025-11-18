-- vim:set ft=lua.luasnip:
local U = require"mylib.utils"
local _q = U.fmt.str_simple_quote_surround

local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils
local SR = require"mycfg.snippets_by_ft._resolvers" -- Snip Resolvers
local conds = require"mycfg.snippets_by_ft._conditions"

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

---@param pos integer?
---@return LuaSnip.Node
local function get_let_pat_maybe_mut_node(pos)
  return ls.choice_node(pos, {
    ls.restore_node(nil, "pat"),
    SU.myfmt { [[mut <pat>]], { pat = ls.restore_node(1, "pat") } }
  })
end

---@param pos integer?
---@return LuaSnip.Node
local function get_visibility_mod_node(pos)
  return ls.choice_node(pos, {
    t"",
    t"pub ",
    t"pub(super) ",
    t"pub(crate) ",
  })
end

-- Add let binding
-- - Allow to toggle `mut` on the let pattern/name
-- - Allow to toggle `else {..}` after let
-- - Handles being called like `l|something_already;` (disables optional `else` after)
snip("l", {desc = "let …;", when = conds.start_of_line, resolver = SR.delete_spaces_after_trigger}, ls.dynamic_node(1, function()
  local _, rest_of_line = U.get_line_around_cursor()
  local has_text_after = not not rest_of_line:match"^[^ ]"
  local default_expr ---@type string
  local after_node ---@type LuaSnip.Node
  if has_text_after then
    default_expr = ""
    after_node = t""
  else
    default_expr = "()"
    after_node = ls.choice_node(4, {
      t";",
      SU.myfmt_no_strip {
        [[ else {<else_branch>};]],
        { else_branch = i(1) },
      },
    })
  end
  return ls.snippet_node(nil, SU.myfmt {
    [[let <pat><maybe_ty> = <expr><after>]],
    {
      pat = get_let_pat_maybe_mut_node(1),
      maybe_ty = ls.choice_node(2, {
        t"",
        SU.myfmt {
          [[: <ty>]],
          { ty = i(1, "()") },
        }
      }),
      expr = SU.insert_node_default_selection(3, default_expr),
      after = after_node,
    }
  })
end), {
  stored = { pat = i(nil, "name_or_pat") },
})

snip("wl", {desc = "while let pat = … {…}", when = conds.start_of_line}, SU.myfmt {
  [[
    while let <pat> = <expr> {
    	<body>
    }
  ]],
  {
    pat = get_let_pat_maybe_mut_node(1),
    expr = i(2, "()"),
    body = SU.insert_node_default_selection(3, "()"),
  },
}, {
  stored = { pat = i(nil, "pat") },
})

snip("ifl", {desc = "if let pat = … {…}"}, SU.myfmt {
  [[
    if let <pat> = <expr> {
    	<body>
    }
  ]],
  {
    pat = get_let_pat_maybe_mut_node(1),
    expr = i(2, "()"),
    body = SU.insert_node_default_selection(3),
  }
}, {
  stored = { pat = i(nil, "pat") },
})

---@param ty string Type to guess default value of
---@return string
local function guess_default_value_for_type(ty)
  if ty:match"^bool" then
    return "false"
  elseif ty:match"^Option" then
    return "None"
  else
    return "()"
  end
end

---@param pos integer
---@param generic_node_ref LuaSnip.NodeRef
---@return LuaSnip.Node
local function get_maybe_where_node(pos, generic_node_ref)
  return ls.dynamic_node(pos, function(args_texts)
    local txt_with_generics = args_texts[1][1]
    local generics_part = txt_with_generics:match"%b<>"
    if not generics_part then
      -- No generics to define
      return ls.snippet_node(nil, t" ")
    end

    -- Detect generic types that need to be defined (in a `where`)
    local undefined_generics = {} ---@type string[]
    -- Matches things like (the capture group skips first char):
    -- - `<Other>`
    -- - `,T>`
    -- - ` Foo:`
    -- but NOT `'a`
    --
    -- (note: `string.gmatch` only gives captures, not whole match)
    -- note: last `.` in the capture allows to check if next char is `:` (see note below)
    for gen_name in generics_part:gmatch"[,< ]([A-Z][A-Za-z]*.)" do
      -- note: the last char of `gen_name` is not part of the name,
      -- it's the char after it, allowing us to check if next char is `:` or not.
      -- .. we need to remove that last char before use.
      if not gen_name:match":" then
        gen_name = gen_name:sub(1, -2) -- remove last char (see note above)
        table.insert(undefined_generics, gen_name)
      end
    end
    -- print("Detected undefined generics:", vim.inspect(undefined_generics)) -- DEBUG

    if vim.tbl_isempty(undefined_generics) then
      -- No generics to define
      return ls.snippet_node(nil, t" ")
    end

    -- TODO: handle name like:
    -- `strip_prefix<P>`
    -- `iter_after<'a, 'b, I, J>` (only I & J are types)
    -- `strip_prefix<P: Constraint>` (where not needed for P)
    -- `strip_prefix<Other, P: Constraint>` (where only needed for Other)
    return ls.snippet_node(nil, SU.myfmt {
      [[
          <newline>where
            <ty>: <constraints>,<more><newline>
        ]],
      {
        newline = t{"", ""}, -- TODO: `SU.newline_node()`
        -- TODO: <- inject each `\t<gen_name>: <insert_node>,` here
        -- FIXME: how to keep track of the nodes & their values for this,
        --   especially as we add types dynamically?
        ty = i(1, undefined_generics[1]),
        constraints = i(2, "std::fmt::Debug"),
        more = i(3),
      }
    })
  end, {generic_node_ref})
end

-- Smart function snip ✨
-- - Auto-add `where` when there are undefined generic types
-- - Auto-add sensible default return value based on return type
snip("fn", {desc = "fn def", when = conds.start_of_line}, SU.myfmt {
  [[
    <vis>fn <name>(<args>)<rtype><maybe_where>{
    	<body><maybe_ret>
    }
  ]],
  {
    name = i(1, "function_name", {key="name"}),
    vis = get_visibility_mod_node(2),
    args = i(3),
    rtype = ls.choice_node(4, {
      t"",
      SU.myfmt_braces_no_strip {
        [[ -> {rtype}]],
        {
          rtype = i(1, "()"),
        },
      },
    }, {key="rtype"}),
    maybe_where = get_maybe_where_node(5, SU.node_ref"name"),
    body = SU.insert_node_default_selection(6),
    maybe_ret = ls.dynamic_node(7, function(args_texts)
      local rtype = args_texts[1][1]
      if #rtype == 0 then
        return ls.snippet_node(nil, t"")
      end
      if rtype:match" %-> " then
        rtype = rtype:sub(5) -- skip return syntax prefix
      end

      -- skip module prefix if any (like `anyhow::`)
      local module_prefix = rtype:match"^[a-z_]+::"
      if module_prefix then
        rtype = rtype:sub(#module_prefix +1)
      end
      print("Choosing default return based on type:", _q(rtype))

      local ret_nodes ---@type LuaSnip.Node[]
      if rtype:match"^Result<" then
        local inner_ty = rtype:sub(#("Result<") +1) -- skip prefix
        ret_nodes = SU.myfmt {
          [[Ok(<inner>)]],
          { inner = i(1, guess_default_value_for_type(inner_ty)) },
        }
      else
        ret_nodes = { t(guess_default_value_for_type(rtype)) }
      end

      -- inject newline & indent to ensure the default return is on a separate line after body
      table.insert(ret_nodes, 1, t{ "", "	" })
      return ls.snippet_node(nil, ret_nodes)
    end, {SU.node_ref"rtype"}),
  }
})

-- Smart impl block snip ✨
-- - Auto-add `where` when there are undefined generic types
snip("im", {desc="impl block", when = conds.start_of_line}, SU.myfmt {
  [[
    <impl_line><maybe_where>{
    	<body>
    }
  ]],
  {
    impl_line = ls.choice_node(1, {
      SU.myfmt {
        [[impl<gen> <ty>]],
        {
          ty = ls.restore_node(1, "ty"),
          gen = ls.restore_node(2, "generics"),
        },
      },
      SU.myfmt {
        [[impl<gen> <trait> for <ty>]],
        {
          ty = ls.restore_node(1, "ty"),
          trait = i(2, "SomeTrait"),
          gen = ls.restore_node(3, "generics"),
        },
      },
    }, { restore_cursor = true }),
    maybe_where = get_maybe_where_node(2, SU.node_ref"gen"),
    body = i(3),
  }
}, {
  stored = {
    ty = i(nil, "SomeType"),
    generics = ls.choice_node(nil, {
      t"",
      {t"<", i(1), t">"}
    }, {key="gen"}),
  },
})

-- Annotations

-- note: unlike `#![…]`, `#[…]` applies on the next item
snip("an", {desc = "Annotation #[…]", when = conds.start_of_line}, SU.myfmt {
  "#[<annotation>]",
  { annotation = i(1, "annotation") },
})
-- note: same as non-inline, with added space at the end.
snip("an", {desc = "Annotation #[…] (inline)", when = conds.start_of_line:inverted()}, SU.myfmt_no_strip {
  "#[<annotation>] ",
  { annotation = i(1, "annotation") },
})

-- note: unlike `#[…]`, `#![…]` applies to the enclosing module or crate
-- Rust lang ref calls that `InnerAttribute`
-- ref: https://doc.rust-lang.org/reference/attributes.html#r-attributes.inner
snip("ang", {desc = "General (crate/module) annotation #![…]", when = conds.start_of_line}, SU.myfmt {
  "#![<annotation>]",
  { annotation = i(1, "crate-annotation") },
})

snip("and", {desc = "Derive annotation #[derive(…)]", when = conds.start_of_line}, SU.myfmt {
  "#[derive(<derives>)]",
  { derives = i(1) },
})


-- Type helpers

snip("st", {desc = "struct {…}", when = conds.start_of_line}, SU.myfmt {
  [[
    #[derive(Debug<derives>)]
    <vis>struct <name> {
    	<fields>
    }
  ]],
  {
    name = i(1, "StructName"),
    derives = i(2),
    vis = get_visibility_mod_node(3),
    fields = i(4),
  }
})

snip("en", {desc = "enum {…}", when = conds.start_of_line}, SU.myfmt {
  [[
    #[derive(Debug<derives>)]
    <vis>enum <name> {
    	<variants>
    }
  ]],
  {
    name = i(1, "EnumName"),
    derives = i(2),
    vis = get_visibility_mod_node(3),
    variants = i(4),
  }
})

-- TODO: restrict this snip to Type context only
-- (could be named `r` then 🤔)
snip("rs", {desc = "Result<…>"}, ls.choice_node(1, {
  SU.myfmt_braces {
    [[Result<{rtype}, {errtype}>]],
    { rtype = ls.restore_node(1, "rtype"), errtype = i(2, "String") },
  },
  SU.myfmt_braces {
    [[anyhow::Result<{rtype}>]],
    { rtype = ls.restore_node(1, "rtype") },
  },
}), {
  stored = { rtype = i(nil, "()") },
})

-- TODO: restrict this snip to Type context only
snip("opt", {desc = "Option<…>"}, SU.myfmt_braces {
  "Option<{type}>",
  { type = SU.insert_node_default_selection(1, "type") },
})

snip("ok", {desc = "Ok(…)"}, SU.myfmt {
  "Ok(<value>)",
  { value = SU.insert_node_default_selection(1, "()") },
})

-- TODO: restrict this snip to NON-Type context only, add another one for Type context
snip("vec", {desc = "vec![…] literal"}, SU.myfmt {
  "vec![<values>]",
  { values = i(1) }
})

-- note: dynamically adds the `;` if at EOL
-- Can have false-positives but it's very easy to remove when it happens
--
-- TODO: impl a treesitter_postfix snippet to wrap any expr with `dbg!(…)`
snip("db", {desc = "Debug! dbg!(…)"}, ls.dynamic_node(1, function()
  local _, line_after = U.get_line_around_cursor()
  local eol = ""
  if line_after:match"^$" then
    eol = ";"
  end
  return ls.snippet_node(nil, SU.myfmt {
    "dbg!(<thing>)<maybe_eol>",
    {
      thing = SU.insert_node_default_selection(1, "()"),
      maybe_eol = t(eol),
    }
  })
end))

snip("p", {desc = "println!(…)"}, SU.myfmt {
  [[println!("<thing>"<args>);]],
  {
    thing = i(1),
    args = i(2),
  }
})

snip("w", {desc = "write!(…)?"}, SU.myfmt {
  [[write!(<writer>, "<thing>"<args>)?;]],
  {
    writer = i(1, "writer"),
    thing = i(2),
    args = i(3),
  }
})

snip("mi", {desc = "match … {…} (inline)"}, SU.myfmt {
  [[match <thing> {<branches>}]],
  {
    thing = i(1),
    branches = i(2),
  }
})

snip("m", {desc = "match … {…}"}, SU.myfmt {
  [[
    match <thing> {
    	<branches><maybe_fallback>
    }
  ]],
  {
    thing = i(1, "()"),
    branches = i(2),
    maybe_fallback = ls.choice_node(3, {
      SU.myfmt_braces {
        [[{newline}	_ => {then_}]],
        {
          newline = t{"", ""}, -- TODO: `SU.newline_node()`
          then_ = i(1, "todo!()"),
        },
      },
      t"",
    }),
  }
})

snip("mb", {desc = "match branch"}, SU.myfmt_braces {
  [[{pat} => {then_}]],
  {
    pat = ls.choice_node(1, {
      ls.restore_node(nil, "pat"),
      SU.myfmt {
        [[<pat> if <cond>]],
        {
          pat = ls.restore_node(1, "pat"),
          cond = ls.restore_node(2, "cond"),
        }
      },
    }, { restore_cursor = true }),
    then_ = ls.choice_node(2, {
      SU.myfmt {
        [[<body>,]],
        { body = ls.restore_node(1, "body") },
      },
      SU.myfmt {
        [[
          {
          	<body>
          }
        ]],
        { body = ls.restore_node(1, "body") }
      }
    }, { restore_cursor = true }),
  }
}, {
  stored = {
    pat = i(nil, "pat"),
    cond = i(nil, "false"),
    body = i(nil, "todo!()"),
  },
})

-- Add space after `return` only if not at EOL
snip("r", {desc = "return …", resolver = SR.delete_spaces_after_trigger}, ls.dynamic_node(1, function()
  local _, line_after = U.get_line_around_cursor()
  local after_node ---@type LuaSnip.Node
  if line_after:match"^$" then
    -- TODO(?): when current function has a return type, always add a space
    after_node = t""
  else
    after_node = t" "
  end
  return ls.snippet_node(nil, SU.myfmt {
    [[return<after>]], { after = after_node }
  })
end))

snip("mod", {desc = "mod … {…}", when = conds.start_of_line}, SU.myfmt {
  [[
    mod <module> {
    	<body><end_>
    }
  ]],
  {
    module = i(1, "module"),
    body = SU.insert_node_default_selection(2),
    end_ = i(0),
  }
})

-- Test helpers

snip("modt", {desc = "Module for unit tests", when = conds.very_start_of_line}, SU.myfmt {
  [[
    #[cfg(test)]
    mod tests {
    	use super::*;

    	<body>
    }
  ]],
  { body = i(1) },
})

snip("fnt", {desc = "Unit test function", when = conds.start_of_line}, SU.myfmt {
  [[
    #[test]
    fn <name>()<maybe_rtype>{
    	<body><maybe_ret>
    }
  ]],
  {
    name = i(1, "name_of_the_test"),
    -- Optionally select anyhow's results for easy error handling in tests
    maybe_rtype = ls.choice_node(2, {
      t" ",
      t[[ -> anyhow::Result<()> ]],
      t[[ -> miette::Result<()> ]],
    }, {key="rtype"}),
    body = i(3),
    maybe_ret = ls.function_node(function(args_texts)
      local rtype = args_texts[1][1]
      if rtype:match"Result" then
        return {
          "", -- newline
          "	Ok(())"
        }
      end
      return "" -- nothing
    end, {SU.node_ref"rtype"}),
  },
})


--- Returns a LuaSnip node for eventual
---@param idx integer Index for the top node
---@return LuaSnip.Node
local function node_for_maybe_fmt_msg(idx)
  return ls.choice_node(idx, {
    i(nil), -- for manual entry if wanted, or as a stoppoint for the choice node
    SU.myfmt {
      [[, "<msg>"<fmt_args>]],
      { msg = i(1, "TODO: custom msg!"), fmt_args = i(2) }
    },
  })
end

snip("ass", {desc = "assert!(…);", when = conds.start_of_line}, SU.myfmt {
  [[assert!(<expr><maybe_msg>);]],
  {
    expr = SU.insert_node_default_selection(1, [[expr]]),
    maybe_msg = node_for_maybe_fmt_msg(2),
  },
})

snip("assq", {desc = "assert_eq!(…);", when = conds.start_of_line}, SU.myfmt {
  [[assert_eq!(<expr>, <expected><maybe_msg>);]],
  {
    expr = SU.insert_node_default_selection(1, [[expr]]),
    expected = i(2, [["EXPECTED"]]),
    maybe_msg = node_for_maybe_fmt_msg(3),
  },
})

snip("assm", {desc = "assert!(matches!(…));", when = conds.start_of_line}, SU.myfmt {
  [[assert!(matches!(<expr>, <pattern>)<maybe_msg>);]],
  {
    expr = SU.insert_node_default_selection(1, [[expr]]),
    pattern = i(2, [[Pattern]]),
    maybe_msg = node_for_maybe_fmt_msg(3),
  },
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
