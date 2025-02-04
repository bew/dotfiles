local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.Pattern}
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
