local TabStateManager = require"tab-zoom-win.tab_state_manager"
local WinIndicator = require"tab-zoom-win.win_indicator"

local M = {}

--- Save tab layout
local function save_tab_layout()
  TabStateManager.save_state {
    layout_restore_cmds = vim.fn.winrestcmd(),
    indicator_win = WinIndicator.open_new()
  }
end

--- Do zoom the current window
local function do_zoom()
  vim.cmd.wincmd"|"
  vim.cmd.wincmd"_"
end

---@alias twz.Action "nothing-to-zoom"|"zoom"|"restore"

---@return twz.Action
local function get_next_action()
  if vim.fn.winnr("$") == 1 then
    -- Last window ID is 1 (the first), there is only one window
    vim.notify("Only 1 window, nothing to zoom!", vim.log.levels.INFO)
    return "nothing-to-zoom"
  end

  if not TabStateManager.has_state() then
    return "zoom"
  else
    return "restore"
  end
end

local function restore_tab_layout()
  local state = TabStateManager.get_state()
  vim.api.nvim_exec2(state.layout_restore_cmds, { output = false })
  state.indicator_win:cleanup()
end

--- Toggle zoom window in the current tab
--- Call once to zoom the window & save tab layout
--- Call again to restore the tab layout (which restores the windows to their original size)
function M.toggle_zoom()
  local next_action = get_next_action()
  if next_action == "nothing-to-zoom" then
    -- Last window ID is 1 (the first), there is only one window
    vim.notify("Only 1 window, nothing to zoom!", vim.log.levels.INFO)
    return
  end

  if next_action == "zoom" then
    save_tab_layout()
    do_zoom()
  elseif next_action == "restore" then
    restore_tab_layout()
    TabStateManager.reset_state()
  else
    assert(false, "FAIL: Unknown action '"..next_action.."'")
  end
end

return M
