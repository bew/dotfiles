-- Argslist layout
-- --------------------------------------------------------------------
-- Lay the argument list files out as tabs / splits / vsplits.

local M = {}

---@alias mycfg.ArgsLayout "tabs"|"splits"|"vsplits"

--- Layout order used by `M.get_next_layout`.
---@type mycfg.ArgsLayout[]
local LAYOUT_CYCLE = { "tabs", "splits", "vsplits" }

--- Return the current argument list (files passed on the command line).
---@return string[]
function M.get_args()
  return vim.fn.argv()
end

--- Normalize a path to an absolute one, so path comparisons are stable.
---@param path string Path to normalize
---@return string
local function to_abs_path(path)
  return vim.fn.fnamemodify(path, ":p")
end

--- Build a lookup set of the absolute paths of all args (O(1) membership).
---@param args string[] Argument list paths
---@return table<string, true>
local function make_arg_path_set(args)
  local set = {}
  for _, arg in ipairs(args) do
    set[to_abs_path(arg)] = true
  end
  return set
end

--- List the normal (non-floating) windows of a given tabpage.
--- Floating windows (which-key, notifications, …) are excluded.
---@param tabpage integer Tabpage handle
---@return integer[] winids
local function get_normal_tab_wins(tabpage)
  local winids = {}
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    if vim.api.nvim_win_get_config(winid).relative == "" then
      table.insert(winids, winid)
    end
  end
  return winids
end

--- List the normal (non-floating) windows of all tabpages, in order.
---@return integer[] winids
local function get_normal_windows()
  local winids = {}
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    vim.list_extend(winids, get_normal_tab_wins(tabpage))
  end
  return winids
end

--- Return the absolute path of the buffer displayed in a window.
---@param winid integer Window handle
---@return string
local function get_win_buf_path(winid)
  return to_abs_path(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(winid)))
end

--- Whether any normal window displays a buffer that is not part of the args.
---@param arg_path_set table<string, true> Absolute paths of all args
---@return boolean
local function has_non_arg_windows(arg_path_set)
  for _, winid in ipairs(get_normal_windows()) do
    if not arg_path_set[get_win_buf_path(winid)] then
      return true
    end
  end
  return false
end

--- Check whether every arg is already displayed in the given arrangement.
---@param layout mycfg.ArgsLayout Arrangement to check for
---@param args string[] Argument list paths
---@param arg_path_set table<string, true> Absolute paths of all args
---@return boolean
local function is_open_in(layout, args, arg_path_set)
  local arg_count = #args
  if arg_count == 0 then
    return true
  end

  if layout == "tabs" then
    local tabpages = vim.api.nvim_list_tabpages()
    if #tabpages ~= arg_count then
      return false
    end
    for _, tabpage in ipairs(tabpages) do
      local winids = get_normal_tab_wins(tabpage)
      if #winids ~= 1 or not arg_path_set[get_win_buf_path(winids[1])] then
        return false
      end
    end
    return true
  end

  -- splits / vsplits: all args in a single tab
  if #vim.api.nvim_list_tabpages() ~= 1 then
    return false
  end
  local winids = get_normal_windows()
  if #winids ~= arg_count then
    return false
  end
  for _, winid in ipairs(winids) do
    if not arg_path_set[get_win_buf_path(winid)] then
      return false
    end
  end

  -- `winlayout()` root is "col" for horizontal splits, "row" for vertical ones
  local expected_root = layout == "splits" and "col" or "row"
  return vim.fn.winlayout()[1] == expected_root
end

--- Whether the args are currently laid out in the given arrangement.
---@param layout mycfg.ArgsLayout Arrangement to check for
---@return boolean
function M.is_open_in(layout)
  local args = M.get_args()
  return is_open_in(layout, args, make_arg_path_set(args))
end

--- Return the next layout in the cycle, based on the current arrangement.
--- Falls back to the first layout when none is recognized.
---@return mycfg.ArgsLayout
function M.get_next_layout()
  local current_index = 0
  for i, layout in ipairs(LAYOUT_CYCLE) do
    if M.is_open_in(layout) then
      current_index = i
      break
    end
  end
  return LAYOUT_CYCLE[current_index % #LAYOUT_CYCLE + 1]
end

--- Return the buffer number for an arg, creating an unloaded buffer if needed.
---@param arg string Argument path
---@return integer bufnr
local function get_arg_bufnr(arg)
  local bufnr = vim.fn.bufnr(arg)
  if bufnr == -1 then
    bufnr = vim.fn.bufadd(arg)
  end
  return bufnr
end

--- Close every window of the current tab except the current one.
local function close_other_windows()
  local current_win = vim.api.nvim_get_current_win()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if winid ~= current_win then
      vim.api.nvim_win_close(winid, true)
    end
  end
end

--- Detect args whose swap file clashes with another editor instance.
--- Loading is attempted with the stock `shortmess`, so `bufload()` raises the
--- swap error which is caught here; the buffers stay unloaded for the layout.
---@param args string[] Argument list paths
---@return string[] conflicted_args
local function find_swap_conflicts(args)
  local conflicts = {}
  for _, arg in ipairs(args) do
    local bufnr = get_arg_bufnr(arg)
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      local ok = pcall(vim.fn.bufload, bufnr)
      if not ok then
        table.insert(conflicts, arg)
      end
    end
  end
  return conflicts
end

--- Open every arg in its own tab page (one window per tab).
---@param args string[] Argument list paths
local function open_args_in_tabs(args)
  close_other_windows()
  vim.cmd[[silent tabonly]]
  vim.api.nvim_set_current_buf(get_arg_bufnr(args[1]))
  for i = 2, #args do
    vim.cmd.tabnew(vim.fn.fnameescape(args[i]))
  end
  vim.api.nvim_set_current_tabpage(vim.api.nvim_list_tabpages()[1])
end

--- Open every arg as a split of a single tab page, keeping arg order.
---@param args string[] Argument list paths
---@param split_cmd "split"|"vsplit" Split command: horizontal or vertical
local function open_args_in_single_tab_splits(args, split_cmd)
  close_other_windows()
  vim.cmd[[silent tabonly]]
  vim.api.nvim_set_current_buf(get_arg_bufnr(args[1]))
  for i = 2, #args do
    -- NOTE: "belowright" is the split modifier for below (horizontal) or
    --   right (vertical), which keeps the arg order (top->bottom / left->right).
    vim.api.nvim_cmd({
      cmd = split_cmd,
      args = { vim.fn.fnameescape(args[i]) },
      mods = { split = "belowright" },
    }, {})
  end
  vim.cmd[[wincmd =]]
end

--- Lay the argument list out in the given arrangement.
--- No-op when already arranged this way, or when non-arg windows are open.
--- Args with an existing swap file are still opened, then reported.
---@param layout mycfg.ArgsLayout Arrangement to apply
---@return boolean ok Whether the argslist is in the requested arrangement
function M.open_args_in(layout)
  local args = M.get_args()
  if #args <= 1 then
    return false
  end

  local arg_path_set = make_arg_path_set(args)
  if has_non_arg_windows(arg_path_set) then
    vim.notify(
      "Argslist layout: refusing to re-layout while non-arg windows are open",
      vim.log.levels.WARN
    )
    return false
  end

  if is_open_in(layout, args, arg_path_set) then
    return true
  end

  local conflicts = find_swap_conflicts(args)

  -- Swap prompts cannot be answered from the layout code, so open all args with
  -- the ATTENTION message suppressed and report the conflicted files afterwards.
  local shortmess = vim.api.nvim_get_option_value("shortmess", {})
  vim.api.nvim_set_option_value("shortmess", shortmess .. "A", {})
  local ok, err = pcall(function()
    if layout == "tabs" then
      open_args_in_tabs(args)
    elseif layout == "splits" then
      open_args_in_single_tab_splits(args, "split")
    elseif layout == "vsplits" then
      open_args_in_single_tab_splits(args, "vsplit")
    end
  end)
  vim.api.nvim_set_option_value("shortmess", shortmess, {})

  if not ok then
    vim.notify("Argslist layout: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end

  if #conflicts > 0 then
    vim.notify(
      "Argslist layout: existing swap file(s), opened anyway: "
        .. table.concat(conflicts, ", "),
      vim.log.levels.WARN
    )
  end

  return true
end

--- Open multiple CLI file args in tabs, on startup.
function M.setup_autocmd()
  vim.api.nvim_create_autocmd("VimEnter", {
    desc = "Open multiple CLI file args in tabs",
    -- Nested so the tab opens fire FileType for the newly displayed buffers.
    nested = true,
    callback = function()
      if #M.get_args() <= 1 then
        return
      end
      if vim.api.nvim_buf_get_name(0) == "" then
        return
      end
      M.open_args_in("tabs")
    end,
  })
end

return M
