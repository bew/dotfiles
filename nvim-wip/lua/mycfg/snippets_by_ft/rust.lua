-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local U = require"mycfg.snippets_by_ft._utils"

local SNIPS = {}
local snip = U.get_snip_fn(SNIPS)

local i = ls.insert_node

-- Start of snippets definitions

snip("an", {desc = "Annotation #[…]"}, U.myfmt {
  "#[<annotation>]",
  { annotation = i(1, "annotation") },
})

snip("and", {desc = "Derive annotation #[derive(…)]"}, U.myfmt {
  "#[derive(<derives>)]",
  { derives = i(1) },
})


-- Type helpers

snip("ok", {desc = "Ok(…)"}, U.myfmt {
  "Ok(<value>)",
  { value = i(1, "()") },
  -- FIXME: default to last selected text if any
})

snip("opt", {desc = "Option<…>"}, U.myfmt_braces {
  "Option<{type}>",
  { type = i(1, "type") },
  -- FIXME: default to last selected text if any
})

snip("vec", {desc = "vec![…] literal"}, U.myfmt {
  "vec![<values>]",
  { values = i(1) }
})

snip("db", {desc = "Debug! dbg!(…)"}, U.myfmt {
  "dbg!(<thing>)",
  { thing = i(1) }
  -- FIXME: when not in an expression, add `;` at the end 🙏
})


-- Test helpers

snip("modt", {desc = "Module for unit tests"}, U.myfmt {
  [[
    #[cfg(test)]
    mod tests {
    	use super::*;

    	<body>
    }
  ]],
  { body = i(1) },
})

snip("fnt", {desc = "Unit test function"}, U.myfmt {
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

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
