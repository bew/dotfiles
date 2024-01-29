local U = {}

function U.filter_list(tbl, filter_fn)
  vim.validate{
    tbl={tbl, "table"},
    filter_fn={filter_fn, "function"},
  }
  local ret = {}
  for _, item in ipairs(tbl) do
    if filter_fn(item) then
      table.insert(ret, item)
    end
  end
  return ret
end

-- Helper function to concat/join strings together with spaces like print
-- ```
-- -- Useful to format string without having to add spaces everywhere before/after variables
-- local _f = U.str_space_concat
-- error(_f("foo", some_var, "baz"))
-- ```
-- TODO(?): Might be nice to allow a table as single param,
--   so I can have trailing comma for the last item to concat!
function U.str_space_concat(...)
  local final_str = ""
  for idx, item in ipairs({...}) do
    if idx ~= 1 then final_str = final_str .. " " end
    final_str = final_str .. tostring(item)
  end
  return final_str
end

-- Helper function to concat/join strings together (without spaces)
-- ```
-- -- Useful to write complex regexes on multiple lines
-- U.str_concat(
--   "^"
--   "(",
--   foo,
--   ")$"
-- )
-- ```
-- TODO(?): Might be nice to allow a table as single param,
--   so I can have trailing comma for the last item to concat!
function U.str_concat(...)
  local final_str = ""
  for idx, item in ipairs({...}) do
    final_str = final_str .. tostring(item)
  end
  return final_str
end

--- Helper functions to surround a str with 2 parts
--- ```
--- local _s = U.str_surround
--- print("foo", _s("(", thing, ")"), "bar")
---
--- local _q = U.str_simple_quote_surround
--- print("foo", _q(thing), "bar")
--- ```
function U.str_surround(before, str, after)
  return before .. tostring(str) .. after
end
function U.str_simple_quote_surround(str)
  return U.str_surround("'", str, "'")
end

--- Checks if the given module is available
---@param module_name string The module to check
---@return bool
function U.is_module_available(module_name)
  local module_available = pcall(require, module_name)
  return module_available
end

return U
