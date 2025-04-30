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
    return hline_conditions.buffer_matches{ buftype = { "help" } }
  end,

  C.nvim.ModeOrWinNr,
  {
    provider = " HELP ",
    hl = function()
      return C.utils.white_with_bg{ active_ctermbg = 91, inactive_ctermbg = 54 }
    end,
  },
  _,
  C.fs.BufBasename,
  _,
  {
    provider = function()
      if not vim.o.readonly and vim.o.modifiable then
        return "(editable)"
      else
        return _U.unicode_or(" ", "[RO]")
      end
    end,
    on_click = {
      name = "statusline_on_click_help_toggle_editable",
      callback = function()
        vim.cmd[[set ro! modifiable!]]
      end,
    },
    hl = function()
      if not vim.o.readonly and vim.o.modifiable then
        return { ctermfg = 250 }
      end
    end,
  },
  _,
  C.nvim.Changed,

  __WIDE_SPACE__,

  C.lsp_ts_diags.TreesitterStatus,
  _,
  C.nvim.RulerAndCursorPos,
}
