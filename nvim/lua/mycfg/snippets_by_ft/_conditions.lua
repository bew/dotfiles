local U = require"mylib.utils"
local _q = U.fmt.str_simple_quote_surround

local make_cond_obj = require"luasnip.extras.conditions".make_condition

local M = {}

--- Loose cache of trigger guesses for given line_to_cursor
--- (to avoid useless re-computations when all `show_condition` are tested in completion)
---@type table<string,string>
local _cache_for_trigger_guesses = setmetatable({}, { __mode = "kv" })

--- Lua patterns to guess snip trigger for `line_before_matches` when called from `show_condition`.
---
--- NOTE: Many snips don't have a `when` condition or are not using `line_before_matches`, so their
--- trigger do NOT need to be guessed.
local _MY_PATTERNS_TO_GUESS_SNIP_TRIGGER = {
  -- This pattern should match most of my snips
  "[a-z]+$",
  -- The following patterns for edge cases, with various symbols
  "%s*%-%-+ ?@?$", -- `---@`, for Lua doc snips
  "%s+:[a-z]+$", -- `:p`, for Python docstring Snips
  "%$$", -- `$`, for some str interpolation snips
}

--- Try to guess the trigger from the current `line_to_cursor`.
---
--- NOTE: This is necessary when trying to get the `line_to_trigger` in a `show_condition`
--- implementation, because we don't YET have a matched trigger.
---
---@param line_to_cursor string
---@return string _ Guessed trigger, or ""
local function _guess_trigger(line_to_cursor)
  if _cache_for_trigger_guesses[line_to_cursor] then
    return _cache_for_trigger_guesses[line_to_cursor]
  end
  local guessed_trig ---@type string
  for _, pat in ipairs(_MY_PATTERNS_TO_GUESS_SNIP_TRIGGER) do
    guessed_trig = line_to_cursor:match(pat)
    if guessed_trig then
      break
    end
  end
  _cache_for_trigger_guesses[line_to_cursor] = guessed_trig or ""
  return guessed_trig or ""
end

--- Returns a condition obj, true when line before trigger matches given pattern.
---
--- Can be used for `condition` & `show_condition`.
---
---@param lua_pattern string Lua Pattern that the line before trigger should match
---@return LuaSnip.SnipContext.ConditionObj
M.line_before_matches = function(lua_pattern)
  return make_cond_obj(function(line_to_cursor, matched_trigger)
    -- `matched_trigger` is NOT set for `show_condition` functions,
    -- we need to _guess_ the trigger to remove it for `line_to_trigger` to have a useful value.
    if not matched_trigger then
      matched_trigger = _guess_trigger(line_to_cursor)
      -- print("guessed trigger for", _q(line_to_cursor), "->", _q(matched_trigger)) -- DEBUG
    end
    -- +1 because `string.sub("abcd", 1, -2)` -> abc
    local line_to_trigger = line_to_cursor:sub(1, -(#matched_trigger + 1))
    -- print("line_to_cursor:", _q(line_to_cursor)) -- DEBUG
    -- print("line_to_trigger:", _q(line_to_trigger)) -- DEBUG
    return not not line_to_trigger:match(lua_pattern)
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
