local U_fmt = require"mylib.utils.fmt_utils"
local _f = U_fmt.str_space_concat
local _q = U_fmt.str_simple_quote_surround

local U_mt = {}

U_mt.KeyRefMustExist_mt = {
  __index = function(self, key)
    error(_f("Unknown key", _q(key), "accessed on a KeyRefMustExist-backed table, rest of table is:", vim.inspect(self)))
  end,
}

--- Returns the given table, with metatable to error when accessing a key that doesn't exist
---@generic T: table
---@param tbl T
---@return T
function U_mt.checked_table_index(tbl)
  return setmetatable(tbl, U_mt.KeyRefMustExist_mt)
end

return U_mt
