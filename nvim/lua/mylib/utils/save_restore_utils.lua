
local SR = {}

-- /!\ Generic classes are not supported :/
-- (ISSUE: https://github.com/LuaLS/lua-language-server/issues/734)
-- Otherwise we could have been generic on the hook's StateT for the hook funcs 👀
--
---@class mylib.save_restore.Hooks
---@field save mylib.save_restore.HookFn
---@field restore mylib.save_restore.HookFn

---@alias mylib.save_restore.HookFn fun(state: table)

---@type mylib.save_restore.Hooks
local builtin_hooks_for_cursor = {
  save = function(state)
    state.cursor_pos = vim.api.nvim_win_get_cursor(0)
  end,
  restore = function(state)
    vim.api.nvim_win_set_cursor(0, state.cursor_pos)
  end
}

---@param registers_to_backup string[]
---@return mylib.save_restore.Hooks
local function mk_builtin_hooks_for_registers(registers_to_backup)
  return {
    save = function(state)
      state._saved_registers = {}
      for _, regname in ipairs(registers_to_backup) do
        state._saved_registers[regname] = vim.fn.getreginfo(regname)
      end
    end,
    restore = function(state)
      for _, regname in ipairs(registers_to_backup) do
        vim.fn.setreg(regname, state._saved_registers[regname])
      end
    end
  }
end

---@class mylib.Opts.save_restore.Hooks
---@field save? mylib.save_restore.HookFn Hook called to save some context to given state
---@field restore? mylib.save_restore.HookFn Hook called to restore some context from given state
---@field save_registers? string[] List of registers to save/restore (builtin hooks)
---@field save_cursor? boolean Whether to save/restore current cursor (builtin hooks)

--- Save/Restore anything and run arbitrary function in-between.
---
--- Allows the inner function to use registers, marks, move cursor around... given we write the code
--- to save/restore it.
---
---@generic T
---@param hooks mylib.Opts.save_restore.Hooks
---@param fn (fun(): T?) Function to execute in the middle
---@return T
function SR.save_run_restore(hooks, fn)
  ---@type mylib.save_restore.HookFn[]
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
