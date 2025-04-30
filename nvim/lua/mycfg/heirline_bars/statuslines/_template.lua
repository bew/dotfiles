-- local hline_conditions = require"heirline.conditions"

local U = require"mylib.utils"
local _f = U.str_space_concat

local C = require"mycfg.heirline_bars.components"
local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE
local __WIDE_SPACE__ = _U.__WIDE_SPACE__

--------------------------------

return {
  condition = function()
    return true
  end,

  -- TODO: Implement your line here!
  C.nvim.ModeOrWinNr,
  _,
  { provider = "Start" },

  __WIDE_SPACE__,

  { provider = "End" },
}
