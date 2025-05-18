local hline_conditions = require"heirline.conditions"

local U = require"mylib.utils"
local _f = U.fmt.str_space_concat

local C = require"mycfg.heirline_bars.components"
local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE
local __WIDE_SPACE__ = _U.__WIDE_SPACE__

--------------------------------

return {
  condition = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    return vim.startswith(buf_name, "man://")
  end,

  C.nvim.ModeOrWinNr,
  {
    provider = " Man ",
    hl = function()
      return C.utils.white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
    end,
  },
  {
    _,
    {
      provider = function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        return buf_name:gsub("man://", "")
      end,
    },
    _,

    -- NOTE: This is the same hl fn as for general purpose's file info component
    hl = function()
      if hline_conditions.is_active() then
        return { ctermfg = 253, ctermbg = 240 }
      else
        return { ctermfg = 250, ctermbg = 238 }
      end
    end,
  },
  __WIDE_SPACE__,
  C.nvim.RulerAndCursorPos,
}
