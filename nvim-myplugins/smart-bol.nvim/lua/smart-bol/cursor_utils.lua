local M = {}

---@class NormalizedPos11
---@field line1 integer Line number (1-indexed)
---@field col1 integer Column number (1-indexed)
local meta_NormalizedPos11 = {
  __index = {
    with_col1 = function(self, col1)
      return { line1 = self.line1, col1 = col1 }
    end,
  },
}

---Returns the normalized position of the cursor
---@return NormalizedPos11
function M.get_cursor()
  local cursor_pos10 = vim.api.nvim_win_get_cursor(0) -- {1, 0}-indexted
  local normalized_pos = {
    line1 = cursor_pos10[1],
    col1 = cursor_pos10[2] +1,
  }
  return setmetatable(normalized_pos, meta_NormalizedPos11)
end

---Set cursor to the given normalized position
---@param pos NormalizedPos11 Target position of the cursor
function M.set_cursor(pos)
  vim.api.nvim_win_set_cursor(0, {pos.line1, pos.col1 -1}) -- {1, 0}-indexted
end

return M
