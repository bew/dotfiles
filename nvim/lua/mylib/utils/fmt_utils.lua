local U_args = require"mylib.utils.args_utils"

local U_fmt = {}

--- Helper function to concat/join strings together with spaces like print
--- ```
--- -- Useful to format string without having to add spaces everywhere before/after variables
--- local _f = U.fmt.str_space_concat
--- error(_f("foo", some_var, "baz"))
--- _f{
---   "some", sets_of, "strings",
---   "and", more,
--- }
--- ```
---@param ... string|any
---@return string
function U_fmt.str_space_concat(...)
  local strs = U_args.normalize_multi_args(...)
  local final_str = ""
  for idx, item in ipairs(strs) do
    if idx ~= 1 then final_str = final_str .. " " end
    final_str = final_str .. tostring(item)
  end
  return final_str
end

--- Helper function to concat/join strings together (without spaces)
--- ```
--- -- Useful to write complex regexes on multiple lines
--- U.fmt.str_concat("foo", some_var)
--- U.fmt.str_concat{
---   "^"
---   "(",
---   foo,
---   ")$",
--- }
--- ```
---@param ... string|any
---@return string
function U_fmt.str_concat(...)
  local strs = U_args.normalize_multi_args(...)
  local final_str = ""
  for _idx, item in ipairs(strs) do
    final_str = final_str .. tostring(item)
  end
  return final_str
end

--- Helper functions to surround a str with 2 parts
--- ```
--- local _s = U.fmt.str_surround
--- print("foo", _s("(", thing, ")"), "bar")
---
--- local _q = U.fmt.str_simple_quote_surround
--- print("foo", _q(thing), "bar")
--- ```
---@param before string
---@param str string
---@param after string
---@return string
function U_fmt.str_surround(before, str, after)
  return before .. str .. after
end

--- Helper function to surround given str (or tostring-able) with simple-quotes
---@param str any
---@return string
function U_fmt.str_simple_quote_surround(str)
  return U_fmt.str_surround("'", tostring(str), "'")
end

return U_fmt
