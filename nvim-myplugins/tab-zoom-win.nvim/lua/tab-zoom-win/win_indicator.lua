---@class twz.WinIndicator
---@field winid integer
---@field bufnr integer
local WinIndicator = {}
WinIndicator.mt = {}
WinIndicator.mt.__index = WinIndicator

local ZOOMED_INDICATOR_HL = "TabWinZoomIndicator"
local ZOOMED_INDICATOR_MSG = "  TAB: WIN ZOOMED  "

--- Open indicator window in the screen corner
---@return twz.WinIndicator
function WinIndicator.open_new()
  -- Create scratch Buffer
  local bufnr = vim.api.nvim_create_buf(--[[listed:]]false, --[[scratch:]]true)

  -- Create Window in the corner
  ---@type vim.api.keyset.win_config
  local win_opts = {
    style = "minimal",
    relative = "editor", -- the global grid
    anchor = "NE",
    width = #ZOOMED_INDICATOR_MSG,
    height = 1,
    row = 0,
    col = vim.api.nvim_get_option_value("columns", {}),
    focusable = false,
    zindex = 99, -- just below builtin widgets
  }
  local winid = vim.api.nvim_open_win(bufnr, --[[enter:]]false, win_opts)

  -- Config
  vim.api.nvim_set_hl(0, ZOOMED_INDICATOR_HL, { ctermfg = 232, ctermbg = 220, bold = true })
  vim.api.nvim_set_option_value("winhl", "Normal:" .. ZOOMED_INDICATOR_HL, { scope = "local", win = winid })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, --[[strict_indexing:]]true, {
    ZOOMED_INDICATOR_MSG,
  })

  local win_indicator = {
    winid = winid,
    bufnr = bufnr,
  }
  return setmetatable(win_indicator, WinIndicator.mt)
end

function WinIndicator:cleanup()
  if self.winid and vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_win_close(self.winid, --[[force:]]true)
  end
  if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, {})
  end
end

return WinIndicator
