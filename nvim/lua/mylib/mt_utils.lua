local U = require"mylib.utils"

local M = {}

M.KeyRefMustExist_mt = {
  __index = function(self, key)
    error(U.str_space_concat("Unknown key", key))
  end,
}

return M
