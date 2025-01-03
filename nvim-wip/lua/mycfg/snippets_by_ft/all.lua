-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

snip("#!", { desc = "Generic shebang" }, {
  t"#!/usr/bin/env ", i(1, "bash"),
})

snip("modeline", { desc = "vim modeline" }, SU.myfmt{
  [[vim:set ft=<filetype>:]],
  { filetype = i(1) },
})

-- Companion example snippet for the store-selection action (see DOC.md of LuaSnip)
snip("selected_text_debug", { desc = "debug selected lines" }, ls.function_node(function(_args, snip)
  local res, env = {}, snip.env
  table.insert(res, "Selected Text (current line is " .. env.TM_LINE_NUMBER .. "):")
  for _, ele in ipairs(env.LS_SELECT_RAW) do table.insert(res, ele) end
  return res
end, {}))


-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
