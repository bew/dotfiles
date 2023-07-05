local U = require"smart-bol.utils"

local M = {}

--- Get position of beginning of line after spaces
---@param line string
---@return integer Column of beginning of <text>
function M.get_pos_of_indented_bol(line)
  -- format of line: `<spaces><text>`
  local text_first_pos = line:find("[^ \t]")
  if text_first_pos then
    -- There is <text>, give its position
    return text_first_pos
  else
    -- There is no <text>, give end of line
    return U.eol_col1_for_mode(line)
  end
end

return M
