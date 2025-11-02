local M = {}

---@class smartbol.NormalizedPos11
---@field line1 integer Line number (1-indexed)
---@field col1 integer Column number (1-indexed)
---
---@field with_col1 fun(self: smartbol.NormalizedPos11, col1: integer): smartbol.NormalizedPos11
local meta_NormalizedPos11 = {
  __index = {
    with_col1 = function(self, col1)
      return { line1 = self.line1, col1 = col1 }
    end,
  },
}

--- Returns the normalized position of the cursor
---@return smartbol.NormalizedPos11
function M.get_cursor()
  local cursor_pos10 = vim.api.nvim_win_get_cursor(0) -- {1, 0}-indexted
  local normalized_pos = {
    line1 = cursor_pos10[1],
    col1 = cursor_pos10[2] +1,
  }
  return setmetatable(normalized_pos, meta_NormalizedPos11)
end

--- Set cursor to the given normalized position
---@param pos smartbol.NormalizedPos11 Target position of the cursor
function M.set_cursor(pos)
  vim.api.nvim_win_set_cursor(0, {pos.line1, pos.col1 -1}) -- {1, 0}-indexted
end

--- Returns whether given line is fully blank
---@param line string
---@return boolean
function M.is_line_blank(line)
  return line:find("^[ \t]*$") ~= nil
end

--- Returns the EOL column based on the mode (handle difference between normal/insert)
---@param line string
---@return integer
function M.eol_col1_for_mode(line)
  local in_insert_mode = vim.api.nvim_get_mode().mode[1] == "i"
  if #line == 0 then
    return 1
  elseif in_insert_mode then
    -- In insert mode, EOL col is after last char compared to normal mode
    return #line + 1
  else
    return #line
  end
end

return M
