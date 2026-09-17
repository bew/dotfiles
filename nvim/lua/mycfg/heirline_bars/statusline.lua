local hline_conditions = require"heirline.conditions"
local external_components = require"heirline-components.all".component

local U = require"mylib.utils"
local _f = U.fmt.str_space_concat

local C = require"mycfg.heirline_bars.components"
local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE
local __WIDE_SPACE__ = _U.__WIDE_SPACE__

local GeneralPurposeStatusline = {
  C.nvim.ModeOrWinNr,
  { -- File info block
    _,
    { C.fs.FileOutOfCwd, C.fs.FilenameTwoParts },
    _,
    C.nvim.Changed,
    C.nvim.MaybeReadOnly,
    hl = function()
      if hline_conditions.is_active() then
        return { ctermfg = 253, ctermbg = 240 }
      else
        return { ctermfg = 250, ctermbg = 238 }
      end
    end,
  },
  C.lsp_ts_diags.Diagnostics,

  -- e.g. `5 cursors`
  -- e.g. `2 cursors (+5 off)`
  -- TODO: extract into a dedicated heirline component!
  {
    condition = function()
      local mc = U.is_module_available"multicursor-nvim" and require"multicursor-nvim"
      return hline_conditions.is_active() and mc and mc.hasCursors()
    end,

    _,
    {
      -- WARN: this is not called enough times, especially not called when I clear all cursors ><
      -- OPENED: https://github.com/jake-stewart/multicursor.nvim/issues/155
      -- I tried to impl an autocmd based on SafeState as suggested
      -- => did NOT work as expected, in weird ways...

      provider = function()
        local mc = require"multicursor-nvim"
        local enabled_count = mc.numEnabledCursors()
        local disabled_count = mc.numDisabledCursors()
        vim.notify("in component provider! enabled? " .. tostring(disabled_count > 0) .. " enabled:"..tostring(enabled_count) .. " disabled:"..tostring(disabled_count))
        local ret = _f(enabled_count, "cursors")
        if disabled_count > 0 then
          ret = ret .. U.fmt.str_concat(" (+", disabled_count, " off)")
        end
        return ret
      end,
      hl = function()
        if require"multicursor-nvim".cursorsEnabled() then
          return { ctermfg = 202, bold = true, italic = true }
        else
          return { ctermfg = 247, italic = true }
        end
      end,
    },
  },

  __WIDE_SPACE__,

  external_components.lsp({ lsp_client_names = false }), -- LSP progress messages
  {
    condition = C.lsp_ts_diags.LspActive.condition,
    C.lsp_ts_diags.LspActive,
    _,
  },
  {
    condition = C.lsp_ts_diags.TreesitterStatus.condition,
    C.lsp_ts_diags.TreesitterStatus,
    _,
  },
  C.nvim.FileType,
  C.nvim.RulerAndCursorPos,
}

return {
  -- Default fg/bg for the lines
  hl = function()
    if hline_conditions.is_active() then
      return { ctermfg = 246, ctermbg = 236 }
    else
      return { ctermfg = 242, ctermbg = 235 }
    end
  end,

  -- Only first child where `(not condition or condition()) == true` will render!
  fallthrough = false,

  -- Statuslines for builtin special buffers
  require"mycfg.heirline_bars.statuslines.nvim-cmdwin",
  require"mycfg.heirline_bars.statuslines.nvim-quickfix-loclist",
  require"mycfg.heirline_bars.statuslines.nvim-help",
  require"mycfg.heirline_bars.statuslines.nvim-man",

  -- Statuslines for plugin buffers
  require"mycfg.heirline_bars.statuslines.plugin-SplashStartup",
  require"mycfg.heirline_bars.statuslines.plugin-Neotree",
  require"mycfg.heirline_bars.statuslines.plugin-XtermColorTable",
  require"mycfg.heirline_bars.statuslines.plugin-CodeCompanionAI",
  require"mycfg.heirline_bars.statuslines.plugin-NoNeckPain",

  -- General purpose statusline
  GeneralPurposeStatusline, -- last fallback
}
