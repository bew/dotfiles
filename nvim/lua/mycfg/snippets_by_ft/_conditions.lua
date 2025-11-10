local U = require"mylib.utils"

local make_cond_obj = require"luasnip.extras.conditions".make_condition

local M = {}

--- Returns a condition obj, true when line before trigger matches given pattern.
---
--- Can be used for `condition` & `show_condition`.
---
---@param lua_pattern string Lua Pattern that the line before trigger should match
---@return LuaSnip.SnipContext.ConditionObj
M.line_before_matches = function(lua_pattern)
  return make_cond_obj(function(line_to_cursor, matched_trigger)
    matched_trigger = matched_trigger or "" -- not set for `show_condition` functions
    -- +1 because `string.sub("abcd", 1, -2)` -> abc
    local line_to_trigger = line_to_cursor:sub(1, -(#matched_trigger + 1))
    return line_to_trigger:match(lua_pattern)
  end)
end

--- A condition obj, true when the trigger is at start of line (maybe after indent).
---
--- Better than `require"luasnip.extras.conditions.expand".line_begin` since it works for `show_condition` as well.
M.start_of_line = M.line_before_matches"^%s*$"

--- A condition obj, true when the trigger is at start of line, at the first char.
M.very_start_of_line = M.line_before_matches"^$"

--- A condition obj, true when the trigger is at start of line, AFTER 1+ indent.
M.after_indent = M.line_before_matches"^ +$"

--- A condition obj, true when TS is available in this buffer.
M.ts_available = make_cond_obj(function()
  return U.ts.is_available_here()
end)
--- A condition obj, true when TS is NOT available in this buffer.
M.ts_not_available = M.ts_available:inverted()

--- Returns a condition obj, true when current TS node is one of the given node types.
---
--- NOTE: Assumes that TS is available (always returns false otherwise),
---   better to have `M.ts_available` before this condition for proper TS/not-TS handling.
---
---@param node_types string[]
---@return LuaSnip.SnipContext.ConditionObj
M.only_in_ts_node_type = function(node_types)
  return make_cond_obj(function()
    local node = U.ts.try_get_node_at_cursor()
    if not node then return false end
    return vim.list_contains(node_types, node:type())
  end)
end

return M
