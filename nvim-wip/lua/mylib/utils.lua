local M = {}

function M.filter_list(tbl, filter_fn)
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

-- Helper function to concat and return strings like print
-- ```
-- local _f = U.str_concat
-- error(_f("foo", some_var, "baz"))
-- ```
function M.str_concat(...)
  local final_str = ""
  for idx, str_part in ipairs({...}) do
    if idx ~= 1 then final_str = final_str .. " " end
    final_str = final_str .. str_part
  end
  return final_str
end

-- Helper functions to surround a str with 2 parts
-- ```
-- local _s = U.str_surround
-- print("foo", _s("(", thing, ")"), "bar")
--
-- local _q = U.str_simple_quote_surround
-- print("foo", _q(thing), "bar")
-- ```
function M.str_surround(before, str, after)
  return before .. str .. after
end
function M.str_simple_quote_surround(str)
  return M.str_surround("'", str, "'")
end

return M
