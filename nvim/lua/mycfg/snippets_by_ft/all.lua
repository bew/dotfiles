-- vim:set ft=lua.luasnip:
local ls = require"luasnip"
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

local SNIPS = {}
local snip = SU.get_snip_fn(SNIPS)

local i = ls.insert_node ---@diagnostic disable-line: unused-local
local t = ls.text_node ---@diagnostic disable-line: unused-local

-- Start of snippets definitions

local CUSTOM_INTERPRETERS_BY_FILETYPE = {
  python = "python3",
  rust = "cargo-script",
  nix = {"nix eval -f", "nix eval --raw -f"},
  ps1 = "pwsh", -- powershell
  -- note: add more as needed 😉
}
snip("#!", { desc = "Interpreter shebang!" }, SU.myfmt {
  [[#!/usr/bin/env<env_arg> <interpreter>]],
  {
    interpreter = ls.dynamic_node(1, function()
      local filetype = vim.api.nvim_get_option_value("filetype", {})
      local interpreter
      if not filetype or filetype == "" then
        interpreter = "bash"
      else
        filetype = vim.split(filetype, "%.")[1] -- only first ft is useful
        interpreter = CUSTOM_INTERPRETERS_BY_FILETYPE[filetype] or filetype
      end
      local node
      if type(interpreter) == "string" then
        node = i(1, interpreter)
      elseif type(interpreter) == "table" then
        local nodes = vim.iter(interpreter):map(function(interpreter_item)
          return i(nil, interpreter_item)
        end):totable()
        node = ls.choice_node(1, nodes)
      else
        node = t"unreacheable?"
      end
      return ls.snippet_node(nil, node)
    end),
    env_arg = ls.function_node(function(args)
      local interpreter_node_text = args[1][1] ---@type string
      if interpreter_node_text:find(" ") then
        -- This is necessary for `env` to split interpreter line by spaces
        -- (otherwise whole rest of the line is considered as the binary name)
        return " -S"
      else
        return ""
      end
    end, {SU.node_ref(1)}),
  }
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

snip("lorem", { desc = "Lorem paragraph", rx = true }, ls.function_node(function()
  local lorem_paragraphs = require"myassets.lorem_paragraphs"
  return lorem_paragraphs[1]
end))

snip("lorem(%d+)", { desc = "Lorem 2+ paragraphs", rx = true }, ls.function_node(function(_args, snip)
  local lorem_paragraphs = require"myassets.lorem_paragraphs"
  local count = tonumber(snip.env.LS_CAPTURE_1)
  local lines = {}
  -- note: starting at 0 makes it easier to use modulo operator to get valid table index
  for n = 0, (count -1) do
    table.insert(lines, "") -- blank line
    table.insert(lines, lorem_paragraphs[(n % #lorem_paragraphs) +1])
  end
  table.remove(lines, 1) -- remove first blank line
  vim.print(lines)
  return lines
end))

-- End of snippets definitions

return SNIPS, {} -- snippets, autosnippets
