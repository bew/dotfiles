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
    return hline_conditions.buffer_matches{ filetype = {"codecompanion"} }
  end,

  C.nvim.ModeOrWinNr,
  {
    provider = " CodeCompanion Chat ",
    hl = function()
      return C.utils.white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
    end,
  },
  _,
  {
    provider = function()
      local chat = require"codecompanion".buf_get_chat(0)
      local current_adapter = chat.adapter.name
      -- note: `adapter.schema` is the set of parameters for this adapter, and `model` is a standard
      --   parameter across all adapters in the plugin.
      --   `default`
      local current_model = chat.adapter.schema.model.default
      return require"mylib.utils".str_concat(current_adapter, " (", current_model, ")")
    end,
    on_click = {
      name = "statusline_on_click_codecompanion_adapter",
      callback = function()
        local chat = require"codecompanion".buf_get_chat(0)
        require"codecompanion.strategies.chat.keymaps".change_adapter.callback(chat)
      end,
    },
  },

  __WIDE_SPACE__,
  {
    provider = function()
      local chat = require"codecompanion".buf_get_chat(0)
      return "Prompt n°".. chat.cycle
    end
  },
  _,
  C.nvim.RulerAndCursorPos,
}
