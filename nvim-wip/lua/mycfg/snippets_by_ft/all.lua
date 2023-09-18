-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local U = require"mycfg.snippets_by_ft._utils"

local SNIPS = {}
local snip = U.get_snip_fn(SNIPS)

local i = ls.insert_node
local t = ls.text_node

-- Start of snippets definitions

snip("#!", { desc = "Generic shebang" }, {
  t"#!/usr/bin/env ", i(1, "bash"),
})

snip("modeline", { desc = "vim modeline" }, U.myfmt{
  [[vim:set ft=<filetype>:]],
  { filetype = i(1) },
})

-- Companion example snippet for the store-selection action (see DOC.md of LuaSnip)
snip("selected_text_debug", { desc = "debug selected lines" }, ls.function_node(function(args, snip)
  local res, env = {}, snip.env
  table.insert(res, "Selected Text (current line is " .. env.TM_LINE_NUMBER .. "):")
  for _, ele in ipairs(env.LS_SELECT_RAW) do table.insert(res, ele) end
  return res
end, {}))


-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
