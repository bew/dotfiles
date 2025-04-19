-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

snip("b", { desc = "bold text" }, SU.myfmt {
  [[**<text>**]],
  {
    text = SU.insert_node_default_selection(1),
  },
})

snip("em", { desc = "italic (emph) text" }, SU.myfmt {
  [[_<text>_]],
  {
    text = SU.insert_node_default_selection(1),
  },
})

snip("ln", { desc = "link" }, SU.myfmt {
  "[<desc>](<target>)",
  {
    desc = i(1),
    target = SU.insert_node_default_selection(2),
  },
})

snip("com", { desc = "HTML comment" }, SU.myfmt_braces {
  [[<!-- {text} -->]],
  {
    text = SU.insert_node_default_selection(1),
  },
})

---@param kind string
---@param restore_body boolean
local function get_nodes_gfm_panel(kind, restore_body)
  local body_node
  if restore_body then
    body_node = ls.restore_node(2, "body")
  else
    body_node = i(2)
  end
  return SU.myfmt_braces {
    [[
      > [!{kind}]
      > {body}
    ]],
    {
      kind = t(kind),
      body = body_node,
    }
  }
end
-- FIXME: broken..
-- snip("panel", { desc = "GFM panels (info/…)" }, ls.choice_node(1, {
--   get_nodes_gfm_panel("NOTE", true),
--   get_nodes_gfm_panel("TIP", true),
--   get_nodes_gfm_panel("IMPORTANT", true),
--   get_nodes_gfm_panel("WARNING", true),
--   get_nodes_gfm_panel("CAUTION", true),
--   get_nodes_gfm_panel("BUG", true),
-- }, { restore_cursor = true --[[ Seemlessly keep cursor pos across choice branches ]] }), {
--     stored = { body = i(nil) }
-- })
snip("panel", { desc = "GFM panels (info/…)" }, SU.myfmt_braces {
  [[
    > [!{kind}]
    > {body}
  ]],
  {
    kind = ls.choice_node(1, {
      t"NOTE",
      t"TIP",
      t"IMPORTANT",
      t"WARNING",
      t"CAUTION",
      t"BUG",
    }),
    body = i(2),
  }
})
snip("note", { desc = "GFM note panel" }, get_nodes_gfm_panel("NOTE", false))
snip("info", { desc = "GFM note panel" }, get_nodes_gfm_panel("TIP", false))
snip("imp", { desc = "GFM note panel" }, get_nodes_gfm_panel("IMPORTANT", false))
snip("warn", { desc = "GFM note panel" }, get_nodes_gfm_panel("WARNING", false))
snip("bug", { desc = "GFM note panel" }, get_nodes_gfm_panel("BUG", false))

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
