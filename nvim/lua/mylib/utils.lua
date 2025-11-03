
-- /!\ TODO: write tests for all utils!!

local U = {}

--- Args-related utils
U.args = require"mylib.utils.args_utils"
--- Formatting-related utils
U.fmt = require"mylib.utils.fmt_utils"
--- Visual-related utils
U.visual = require"mylib.utils.visual_utils"
--- {qf,loc}list-related utils
U.qf = require"mylib.utils.qf_utils"
--- FS-related utils
U.fs = require"mylib.utils.fs_utils"
--- Search-related utils
U.search = require"mylib.utils.search_utils"
--- Treesitter-related utils
U.treesitter = require"mylib.utils.treesitter_utils"
--- HL-related utils
U.hl = require"mylib.utils.hl_utils"

--- Metatable-related utils
U.mt = require"mylib.utils.mt_utils"

U.save_run_restore = require"mylib.utils.save_restore_utils".save_run_restore
-- Pos0 class
U.Pos0 = require"mylib.utils.pos_utils".Pos0

---@param str string A string to iterate on
---@return Iter
function U.iter_chars(str)
  local i = 0
  local len = #str
  return vim.iter(function()
    i = i + 1
    if i > len then return nil end
    return i, str:sub(i, i)
  end)
end

---@generic T, U
---@param list table<T>
---@param fn fun(T): U?
---@return table<U>
function U.filter_map_list(list, fn)
  vim.validate("list", list, "table")
  vim.validate("fn", fn, "function")
  local ret = {}
  for _, item in ipairs(list) do
    local new_item = fn(item)
    if new_item ~= nil then
      table.insert(ret, new_item)
    end
  end
  return ret
end

---@param ... any[]
---@return any[]
function U.concat_lists(...)
  local res = {}
  for _, list in ipairs(U.args.normalize_multi_args(...)) do
    for _, item in ipairs(list) do
      table.insert(res, item)
    end
  end
  return res
end

--- Checks if the given module is available
---@param module_name string The module to check
---@return boolean
function U.is_module_available(module_name)
  local module_available = pcall(require, module_name)
  return module_available
end

-- FIXME: rename all usages to use `U.treesitter.is_available_here` instead
function U.is_treesitter_available_here()
  local success, _parser = pcall(vim.treesitter.get_parser)
  return success
end

--- Returns whether the given char is part of a keyword according to {option}'iskeyword'.
---@param char string Character to check
---@return boolean
function U.char_is_keyword(char)
  return vim.fn.match(char:sub(1, 1), [[^\k$]]) ~= -1
end

--- Get char at given 0-indexed buffer position, or nil if out of bound
---@param pos0 mylib.Pos0 The 0-indexed position of char to get
---@return string?
-- FIXME: need to consider byte/char/unicode ?
function U.try_get_char_at_pos0(pos0)
  if pos0.row < 0 or vim.fn.line("$") <= pos0.row then
    return nil -- row out of bound
  end
  local line = vim.api.nvim_buf_get_lines(0, pos0.row, pos0.row +1, false)[1]
  if pos0.col < 0 or #line <= pos0.col then
    return nil -- col out of bound
  end
  return line:sub(pos0.col +1, pos0.col +1)
end

---@class mylib.Opts.FeedKeys
---@field remap? boolean Whether to use mappings if any
---@field replace_termcodes? boolean Whether termcodes like `\<esc>` should be replaced
---@field as_if_typed? boolean Handle keys as if typed (matters for undo/folds/..)
---@field immediately? boolean Run the keys immediately without waiting for more keys (fails in insert mode unless force_immediately_from_insert=true)
---@field force_immediately_from_insert? boolean Force immediately=true even in insert mode (/!\)

--- Feed the given keys as if typed (sync call).
---   This is basically a nice wrapper around nvim_feedkeys
---@param keys string
---@param opts? mylib.Opts.FeedKeys
function U.feed_keys_sync(keys, opts)
  ---@type mylib.Opts.FeedKeys
  local opts = U.args.normalize_arg_opts_with_default(opts, {
    remap = false,
    replace_termcodes = false,
    as_if_typed = false,
    -- By default, run the keys immediately unless we're in insert mode
    immediately = vim.fn.mode() ~= "i",
    force_immediately = false,
  })

  if opts.replace_termcodes then
    keys = vim.keycode(keys)
  end

  local feedkeys_mode = ""
  if opts.remap then
    feedkeys_mode = feedkeys_mode .. "m" -- remap
  else
    feedkeys_mode = feedkeys_mode .. "n" -- noremap
  end
  if opts.as_if_typed then
    feedkeys_mode = feedkeys_mode .. "t" -- handle keys as if typed
  end

  if opts.immediately and vim.fn.mode() == "i" and not opts.force_immediately_from_insert then
    -- ref: https://www.perplexity.ai/search/when-using-nvim-feedkeys-what-QXdsjNYfRraSFcECWkSlQw
    error("feed_keys_sync: Passing `immediately=true` is disabled in insert mode to avoid weird behavior.. Use `force_immediately_from_insert=true` to force")
  end

  if opts.immediately then
    feedkeys_mode = feedkeys_mode .. "x!"
  end

  -- escape_ks=false : keys should have gone through nvim_replace_termcodes already
  vim.api.nvim_feedkeys(keys, feedkeys_mode, false)
end

--- Switch to normal mode from any mode reliably
function U.switch_to_normal_mode()
  -- The best way to switch to normal mode according to `:h CTRL-\_CTRL-N` (in `:h mode-switching`):
  --   The command <C-\><C-N> can be used to go to Normal mode from ANY other mode.
  --   This can be used to make sure Vim is in Normal mode, without causing a beep like <Esc> would.
  U.feed_keys_sync([[<C-\><C-n>]], { replace_termcodes = true })
end

--- Returns whether current window is the cmdline-window
---@return boolean
function U.is_cmdwin()
  return vim.fn.getcmdwintype() ~= ""
end

--- Get line before & after the cursor
---@return string, string
function U.get_line_around_cursor()
  local line = vim.api.nvim_get_current_line()
  local _row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
  return line:sub(1, col0), line:sub(col0 +1)
end

return U
