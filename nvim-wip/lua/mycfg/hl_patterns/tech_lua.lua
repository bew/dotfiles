local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
local patterns = {}

---@param pattern_spec mycfg.hl_patterns.PatternSpec
---@return mycfg.hl_patterns.PatternSpec
local ft_only = function(pattern_spec)
  return _U.pattern_for_ft_only({"lua"}, pattern_spec)
end

patterns.lua_LuaCATS_attr = ft_only {
  -- note: Match `---@foo`
  pattern = "%-%-%-()@%w+()",
  group = _U.define_hl("lua_LuaCATS_attr", {
    ctermfg = 202,
  }),
}

return patterns
