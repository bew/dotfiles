local M = {}

M.KeyRefMustExist_mt = {
  __index = function(self, key)
    error(_f("Unknown key", key))
  end,
}

return M
