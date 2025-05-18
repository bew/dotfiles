
-- local hline_conditions = require"heirline.conditions"

local U = require"mylib.utils"
local _f = U.fmt.str_space_concat

local C = require"mycfg.heirline_bars.components"
local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE
local __WIDE_SPACE__ = _U.__WIDE_SPACE__

--------------------------------

return {
  condition = function()
    return vim.o.filetype == "no-neck-pain"
  end,
  -- basically nothing ¯\_(ツ)_/¯
  __WIDE_SPACE__,
}
