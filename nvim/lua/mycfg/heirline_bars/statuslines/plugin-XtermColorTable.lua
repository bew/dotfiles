local hline_conditions = require"heirline.conditions"

local U = require"mylib.utils"
local _f = U.str_space_concat

local C = require"mycfg.heirline_bars.components"
local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE
local __WIDE_SPACE__ = _U.__WIDE_SPACE__

--------------------------------

return {
  condition = function()
    return hline_conditions.buffer_matches{ bufname = {"__XtermColorTable__"} }
  end,

  C.nvim.WinNr,
  __WIDE_SPACE__,
  {
    provider = " XTerm color table ",
    hl = function()
      return C.utils.white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
    end,
  },
  __WIDE_SPACE__,
}
