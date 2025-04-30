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
    return hline_conditions.buffer_matches{ filetype = {"alpha"} }
  end,

  C.nvim.WinNr,
  __WIDE_SPACE__,
  {
    provider = "          Do something cool !          ",
    hl = {
      ctermbg = 24,
      ctermfg = 254,
      cterm = { bold = true },
    },
  },
  __WIDE_SPACE__,
}
