local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround

local M = {}

M.KeyRefMustExist_mt = {
  __index = function(self, key)
    error(_f("Unknown key", _q(key), "accessed on a KeyRefMustExist-backed table, rest of table is:", vim.inspect(self)))
  end,
}

return M
