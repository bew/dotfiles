local make_cond_obj = require"luasnip.extras.conditions".make_condition

local M = {}

--- Get line before trigger
---@param line_to_cursor string
---@param matched_trigger string
M._get_line_to_trigger = function(line_to_cursor, matched_trigger)
	-- +1 because `string.sub("abcd", 1, -2)` -> abc
	return line_to_cursor:sub(1, -(#matched_trigger + 1))
end

--- Trigger is starting line, maybe after indent
M.start_of_line = require"luasnip.extras.conditions.expand".line_begin

--- Trigger is starting line, at first char
M.very_start_of_line = make_cond_obj(function(line_to_cursor, matched_trigger)
  local line_to_trigger = M._get_line_to_trigger(line_to_cursor, matched_trigger or "")
  return line_to_trigger:match("^$")
end)

--- Trigger is starting line, after indent
M.after_indent = make_cond_obj(function(line_to_cursor, matched_trigger)
  local line_to_trigger = M._get_line_to_trigger(line_to_cursor, matched_trigger or "")
  -- print("line_to_cursor:", vim.inspect(line_to_cursor), "line_to_trigger:", vim.inspect(line_to_trigger))
  return line_to_trigger:match("^ +$")
end)

---@param lua_pattern string Lua Pattern that the line before trigger should match
M.line_before_matches = function(lua_pattern)
  return make_cond_obj(function(line_to_cursor, matched_trigger)
    local line_to_trigger = M._get_line_to_trigger(line_to_cursor, matched_trigger or "")
    return line_to_trigger:match(lua_pattern)
  end)
end

return M
