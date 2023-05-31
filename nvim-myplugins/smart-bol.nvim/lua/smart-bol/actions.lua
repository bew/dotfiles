local core = require"smart-bol.core"
local U = require"smart-bol.cursor_utils"

local M = {}

function M.move_to_bol()
  local start_pos = U.get_cursor()
  U.set_cursor(start_pos:with_col1(1))
end

function M.move_to_indented_bol()
  local start_pos = U.get_cursor()

  local line = vim.api.nvim_get_current_line()
  local indented_bol_col = core.get_pos_of_indented_bol(line)
  U.set_cursor(start_pos:with_col1(indented_bol_col))
end

-- TODO: write unit tests for actions!

-- TODO: support insert mode! (repeatable in a consistent way)
-- I can't find how to make an imap that when executed chooses between 2 movements and when repeated, does the same chosen movement, adapting to text (so no pre-defined number of builtin movements)

function M.do_smart_bol()
  local line = vim.api.nvim_get_current_line()
  local indented_bol_col = core.get_pos_of_indented_bol(line)

  local start_pos = U.get_cursor()

  if start_pos.col1 == indented_bol_col then
    -- print("do   BOL action")
    U.set_cursor(start_pos:with_col1(1))
  else
    -- print("do I-BOL action")
    U.set_cursor(start_pos:with_col1(indented_bol_col))
  end
end

return M