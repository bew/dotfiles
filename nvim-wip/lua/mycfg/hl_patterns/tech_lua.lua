local _U = require"mycfg.hl_patterns.utils"

local patterns = {}

patterns.lua_LuaCATS_attr = {
  -- note: Match `---@foo`
  pattern = function(bufnr)
    if vim.bo[bufnr].filetype ~= "lua" then return nil end
    return "^%s*%-%-%-()@%w+()"
  end,
  group = _U.define_hl("lua_LuaCATS_attr", {
    ctermfg = 202,
  }),
}

return patterns
