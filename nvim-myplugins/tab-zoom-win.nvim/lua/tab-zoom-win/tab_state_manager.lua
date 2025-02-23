---@class twz.State
---@field layout_restore_cmds string
---@field indicator_win twz.WinIndicator

local M = {
  ---@type {[integer]: twz.State}
  states_per_tab = {},
}

--- Set the current tab state
---@param state twz.State
function M.save_state(state)
  -- NOTE: we cannot save the state in `vim.t.some_tab_var` because values assigned there are
  --   stripped from Lua state like metatables.
  -- 👉 To ensure we always have access to full Lua tables/objects with metatables we need to store
  --   the state in our own location.
  local tabid = vim.api.nvim_get_current_tabpage()
  M.states_per_tab[tabid] = state
end

--- Get the current tab state
---@return twz.State
function M.get_state()
  local tabid = vim.api.nvim_get_current_tabpage()
  return M.states_per_tab[tabid]
end

--- Reset the state
function M.reset_state()
  local tabid = vim.api.nvim_get_current_tabpage()
  M.states_per_tab[tabid] = nil
end

--- Returns whether we have state in current tab
---@return boolean
function M.has_state()
  local tabid = vim.api.nvim_get_current_tabpage()
  return M.states_per_tab[tabid] ~= nil
end

return M
