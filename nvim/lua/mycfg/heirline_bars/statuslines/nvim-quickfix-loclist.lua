local hline_conditions = require"heirline.conditions"

local U = require"mylib.utils"
local _f = U.str_space_concat

local C = require"mycfg.heirline_bars.components"
local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE
local __WIDE_SPACE__ = _U.__WIDE_SPACE__

--------------------------------

---@class myst.QfLocListInfo
---@field get_list_info (fun(what: any): any)
---@field condition (fun(wininfo: any): boolean)
---@field name string
---@field scope string

local LIST = {
  ---@type myst.QfLocListInfo
  qflist = {
    get_list_info = vim.fn.getqflist,
    condition = function(wininfo)
      return wininfo.quickfix == 1 and wininfo.loclist == 0
    end,
    name = "QUICKFIX LIST",
    scope = "global",
  },
  ---@type myst.QfLocListInfo
  loclist = {
    get_list_info = function(what)
      return vim.fn.getloclist(0, what)
    end,
    condition = function(wininfo)
      return wininfo.quickfix == 1 and wininfo.loclist == 1
    end,
    name = "LOCATION LIST",
    scope = "local",
  },
}
---@param list myst.QfLocListInfo
local function make_list_line(list)
  return {
    condition = function()
      local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
      return list.condition(wininfo)
    end,

    {
      provider = list.name,
      hl = { cterm = { bold = true } },
    },
    _,
    { provider = "(" .. list.scope .. ")" },
    __WIDE_SPACE__,

    {
      provider = function()
        return list.get_list_info{ title = 0 }.title
      end,
      hl = { cterm = { italic = true } },
    },

    __WIDE_SPACE__,
    {
      provider = function()
        local current_entry_idx1 = list.get_list_info{ idx = 0 }.idx
        local nb_entries = list.get_list_info{ size = true }.size
        return _f("Entry", current_entry_idx1, "of", nb_entries)
      end,
    },
    { provider = " ¦ " },
    {
      provider = function()
        local list_nr = list.get_list_info{ nr = 0 }.nr
        local nb_lists = list.get_list_info{ nr = "$" }.nr
        return U.str_concat("List n°", list_nr, "/", nb_lists)
      end
    },
    _,
  }
end

return {
  condition = function()
    return hline_conditions.buffer_matches{ buftype = { "quickfix" } }
  end,

  C.nvim.ModeOrWinNr,
  _,
  make_list_line(LIST.qflist),
  make_list_line(LIST.loclist),
  C.nvim.RulerAndCursorPos,
}
