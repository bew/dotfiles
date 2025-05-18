
local SR = {}

---@alias HookT (fun(state: table): nil)
---@alias HooksT {save: HookT, restore: HookT}

local builtin_hooks_for_cursor = {
  save = function(state)
    state.cursor_pos = vim.api.nvim_win_get_cursor(0)
  end,
  restore = function(state)
    vim.api.nvim_win_set_cursor(0, state.cursor_pos)
  end
}

---@param registers_to_backup string[]
local mk_builtin_hooks_for_registers = function(registers_to_backup)
  return {
    save = function(state)
      state.register_backups = {}
      for _, regname in ipairs(registers_to_backup) do
        state.register_backups[regname] = vim.fn.getreginfo(regname)
      end
    end,
    restore = function(state)
      for _, regname in ipairs(registers_to_backup) do
        vim.fn.setreg(regname, state.register_backups[regname])
      end
    end
  }
end

---@class HooksOpts
---@field save? HookT Hook called to save some context to given state
---@field restore? HookT Hook called to restore some context from given state
---@field save_registers? string[] List of registers to save/restore (builtin hooks)
---@field save_cursor? boolean Whether to save/restore current cursor (builtin hooks)

--- Save/Restore anything and run arbitrary function in-between
---   Allows the function to use registers, marks, move cursor around... given we write the
---   code to save/restore it.
---
---@generic T: any
---
---@param hooks HooksOpts
---@param fn (fun(): T?) Function to execute in the middle
---@return T
function SR.save_run_restore(hooks, fn)
  ---@type HooksT[]
  local sets_of_hooks = {}
  if hooks.save_registers then
    table.insert(sets_of_hooks, mk_builtin_hooks_for_registers(hooks.save_registers))
  end
  if hooks.save_cursor then
    table.insert(sets_of_hooks, builtin_hooks_for_cursor)
  end
  if hooks.save and hooks.restore then
    table.insert(sets_of_hooks, hooks)
  end

  local state = {}
  vim.tbl_map(function(hooks) hooks.save(state) end, sets_of_hooks)
  local success, ret_or_err = pcall(fn)
  vim.tbl_map(function(hooks) hooks.restore(state) end, sets_of_hooks) -- always restore after call
  if not success then
    error(ret_or_err)
  end
  return ret_or_err
end

return SR
