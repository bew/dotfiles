local U = require"mylib.utils"
local C = require"mycfg.heirline_bars.components"
local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE
local __WIDE_SPACE__ = _U.__WIDE_SPACE__

--------------------------------

local c = {}

c.CmdwinType = {
  provider = function()
    return vim.fn.getcmdwintype()
  end,
  hl = { ctermfg = "red", cterm = { bold = true } },
}

c.CmdwinTypeDescription = {
  provider = function()
    local cmdwin_type = vim.fn.getcmdwintype()
    if cmdwin_type == ":" then
      return "Command history"
    elseif cmdwin_type == ">" then
      return "Debug mode history"
    elseif cmdwin_type == "/" or cmdwin_type == "?" then
      return "Search history"
    elseif cmdwin_type == "@" then
      return "Input history"
    elseif cmdwin_type == "-" then
      return "Ex :insert :append history"
    elseif cmdwin_type == "=" then
      return "Expression history"
    end
  end,
}

-- Looks like this: `/ Search history /`
return {
  condition = U.is_cmdwin,

  C.nvim.Mode,
  _,
  {
    c.CmdwinType,
    _, c.CmdwinTypeDescription, _,
    c.CmdwinType,
  },
  __WIDE_SPACE__,
  C.nvim.RulerAndCursorPos,
}
