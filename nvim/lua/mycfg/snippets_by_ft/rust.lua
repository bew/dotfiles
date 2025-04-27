-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

snip("l", {desc = "let var = …"}, SU.myfmt {
  [[let <var> = <value>]],
  {
    var = i(1, "var"),
    value = SU.insert_node_default_selection(2),
  },
})

-- Annotations

snip("an", {desc = "Annotation #[…]"}, SU.myfmt {
  "#[<annotation>]",
  { annotation = i(1, "annotation") },
})

snip("anc", {desc = "Crate annotation #![…]"}, SU.myfmt {
  "#![<annotation>]",
  { annotation = i(1, "crate-annotation") },
})

snip("and", {desc = "Derive annotation #[derive(…)]"}, SU.myfmt {
  "#[derive(<derives>)]",
  { derives = i(1) },
})


-- Type helpers

snip("opt", {desc = "Option<…>"}, SU.myfmt_braces {
  "Option<{type}>",
  { type = SU.insert_node_default_selection(1, "type") },
})

snip("ok", {desc = "Ok(…)"}, SU.myfmt {
  "Ok(<value>)",
  { value = SU.insert_node_default_selection(1, "()") },
})

snip("vec", {desc = "vec![…] literal"}, SU.myfmt {
  "vec![<values>]",
  { values = i(1) }
})

snip("db", {desc = "Debug! dbg!(…)"}, SU.myfmt {
  "dbg!(<thing>)",
  { thing = i(1) }
  -- FIXME: when not in an expression, add `;` at the end 🙏
})

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

-- Test helpers

snip("modt", {desc = "Module for unit tests"}, SU.myfmt {
  [[
    #[cfg(test)]
    mod tests {
    	use super::*;

    	<body>
    }
  ]],
  { body = i(1) },
})

snip("fnt", {desc = "Unit test function"}, SU.myfmt {
  [[
    #[test]
    fn <name>() {
    	<body>
    }
  ]],
  {
    name = i(1, "name_of_the_test"),
    body = i(2),
  },
})


--- Returns a LuaSnip node for eventual
---@param idx integer? Index for the top node
---@return SnipNodeT
local function node_for_maybe_fmt_msg(idx)
  return ls.choice_node(idx, {
    i(nil), -- for manual entry if wanted, or as a stoppoint for the choice node
    SU.myfmt {
      [[, "<msg>"<fmt_args>]],
      { msg = i(1, "TODO: custom msg!"), fmt_args = i(2) }
    },
  })
end

snip("ass", {desc = "assert!(…);"}, SU.myfmt {
  [[assert!(<expr><maybe_msg>);]],
  {
    expr = SU.insert_node_default_selection(1, [[expr]]),
    maybe_msg = node_for_maybe_fmt_msg(2),
  },
})

snip("assq", {desc = "assert_eq!(…);"}, SU.myfmt {
  [[assert_eq!(<expr>, <expected><maybe_msg>);]],
  {
    expr = SU.insert_node_default_selection(1, [[expr]]),
    expected = i(2, [["EXPECTED"]]),
    maybe_msg = node_for_maybe_fmt_msg(3),
  },
})

snip("assm", {desc = "assert!(matches!(…));"}, SU.myfmt {
  [[assert!(matches!(<expr>, <pattern>)<maybe_msg>);]],
  {
    expr = SU.insert_node_default_selection(1, [[expr]]),
    pattern = i(2, [[Pattern]]),
    maybe_msg = node_for_maybe_fmt_msg(3),
  },
})

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
