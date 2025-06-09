local U = require"mylib.utils"
local _f = U.fmt.str_space_concat

local C = require"mycfg.heirline_bars.components"
local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE
local __WIDE_SPACE__ = _U.__WIDE_SPACE__

--------------------------------

---@class myst.QfLocListInfo
---@field get_list_info (fun(what: any): any)
---@field condition (fun(): boolean)
---@field name string
---@field scope string

local LIST = {
  ---@type myst.QfLocListInfo
  qflist = {
    get_list_info = U.qf.get_list_fns"qf".get_info,
    condition = U.qf.is_qflist,
    name = "QUICKFIX LIST",
    scope = "global",
  },
  ---@type myst.QfLocListInfo
  loclist = {
    get_list_info = U.qf.get_list_fns"loc".get_info,
    condition = U.qf.is_loclist,
    name = "LOCATION LIST",
    scope = "local",
  },
}
---@param list myst.QfLocListInfo
local function make_list_line(list)
  return {
    condition = list.condition,

    {
      provider = list.name,
      hl = { cterm = { bold = true } },
    },
    _,
    { provider = "(" .. list.scope .. ")" },
    _,
    C.nvim.ReadOnlyMaybeEditable,
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
        return U.fmt.str_concat("List n°", list_nr, "/", nb_lists)
      end
    },
    _,
  }
end

return {
  condition = function()
    return U.qf.is_qf_buf()
  end,

  C.nvim.ModeOrWinNr,
  _,
  make_list_line(LIST.qflist),
  make_list_line(LIST.loclist),
  C.nvim.RulerAndCursorPos,
}
