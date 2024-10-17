
-- FIXME: Split up this file by topics?
-- => It's actually a bit difficult due to some functions being used everywhere
--   (like U.normalize_* or U.str_*) and the amount of re-use & cross referencing between functions.
--
-- TODO: write tests for all utils!!

local U = {}

U.save_run_restore = require"mylib.save_restore_utils".save_run_restore

function U.iter_chars(str)
  local i = 0
  local len = #str
  return function()
    i = i + 1
    if i > len then return nil end
    return i, str:sub(i, i)
  end
end

function U.filter_list(tbl, filter_fn)
  vim.validate{
    tbl={tbl, "table"},
    filter_fn={filter_fn, "function"},
  }
  local ret = {}
  for _, item in ipairs(tbl) do
    if filter_fn(item) then
      table.insert(ret, item)
    end
  end
  return ret
end

--- Normalizes received table-args or multi-args to a table.
---   Allows the caller to pass it a set of args or a table of args, and always get a table of args
---   back to manipulate.
---@param ... any|any[] Args or table of args
---@return any[]
function U.normalize_multi_args(...)
  local first_arg = ({...})[1] -- note: nil when no args
  if type(first_arg) == "table" then
    return first_arg
  else
    return {...}
  end
end

--- Normalizes received opts by filling the blanks (at toplevel, no deep merge) with given defaults
---@alias OptsT {[string]: any}
---@param given_opts? OptsT The given options
---@param default_opts OptsT The default options
---@return OptsT
function U.normalize_arg_opts_with_default(given_opts, default_opts)
  return vim.tbl_extend("force", default_opts, given_opts or {})
end

--- Normalizes a single item or a list of items to a list of item(s).
---@param item_or_items any|any[] A single item (must not be a table) or a list of items
---@return any[]
function U.normalize_arg_one_or_more(item_or_items)
  if type(item_or_items) == "table" then
    return item_or_items
  else
    return {item_or_items}
  end
end

--- Helper function to concat/join strings together with spaces like print
--- ```
--- -- Useful to format string without having to add spaces everywhere before/after variables
--- local _f = U.str_space_concat
--- error(_f("foo", some_var, "baz"))
--- _f{
---   "some", sets_of, "strings",
---   "and", more,
--- }
--- ```
function U.str_space_concat(...)
  local strs = U.normalize_multi_args(...)
  local final_str = ""
  for idx, item in ipairs(strs) do
    if idx ~= 1 then final_str = final_str .. " " end
    final_str = final_str .. tostring(item)
  end
  return final_str
end

--- Helper function to concat/join strings together (without spaces)
--- ```
--- -- Useful to write complex regexes on multiple lines
--- U.str_concat("foo", some_var)
--- U.str_concat{
---   "^"
---   "(",
---   foo,
---   ")$",
--- }
--- ```
function U.str_concat(...)
  local strs = U.normalize_multi_args(...)
  local final_str = ""
  for idx, item in ipairs(strs) do
    final_str = final_str .. tostring(item)
  end
  return final_str
end

--- Helper functions to surround a str with 2 parts
--- ```
--- local _s = U.str_surround
--- print("foo", _s("(", thing, ")"), "bar")
---
--- local _q = U.str_simple_quote_surround
--- print("foo", _q(thing), "bar")
--- ```
function U.str_surround(before, str, after)
  return before .. tostring(str) .. after
end
function U.str_simple_quote_surround(str)
  return U.str_surround("'", str, "'")
end

--- Checks if the given module is available
---@param module_name string The module to check
---@return bool
function U.is_module_available(module_name)
  local module_available = pcall(require, module_name)
  return module_available
end

--- Returns whether the given char is part of a keyword according to {option}'iskeyword'.
---@param char string Character to check
---@return bool
function U.char_is_keyword(char)
  return vim.fn.match(char:sub(1, 1), [[^\k$]]) ~= -1
end

--- Set current search with the given text but without moving the cursor,
---   as if we made a search and moved the cursor back to position.
---
---@param text string|string[] The text to search,
---  will be escaped if opts.escaped is false (the default)
---@param opts.escaped bool Whether the given text was already escaped
---@param opts.with_bounds boolean|{before: boolean, after: boolean}
---  Whether to add word bounds before/after text (none by default)
function U.set_current_search(text, opts)
  local text_lines = U.normalize_arg_one_or_more(text)
  local opts = U.normalize_arg_opts_with_default(opts, {
    escaped = false, -- by default, assume it's not
    with_bounds = false,
  })
  -- normalize opts.with_bounds to structured data
  if type(opts.with_bounds) == "boolean" then
    opts.with_bounds = { before = opts.with_bounds, after = opts.with_bounds }
  end
  local search_payload
  do -- process given text
    if not opts.escaped then
      text_lines = vim.tbl_map(U.escape_text_for_search, text_lines)
    end
    -- note: `\n` must not be escaped for multiline search, so we join lines after escapes
    search_payload = table.concat(text_lines, [[\n]])
    assert(search_payload, "Nothing to search!")
  end
  -- add bounds before/after text
  if opts.with_bounds.before then
    search_payload = [[\<]] .. search_payload
  end
  if opts.with_bounds.after then
    search_payload = search_payload .. [[\>]]
  end
  -- set as current (exact, no magic) search
  vim.fn.setreg("/", [[\V]] .. search_payload)
  vim.fn.histadd("search", vim.fn.getreg("/"))
  vim.o.hlsearch = true
end

--- Escape given text for (exact) search
--- NOTE: since this is for exact search (nomagic), there is very little to escape (:
---@param text string The text to escape
function U.escape_text_for_search(text)
  return vim.fn.escape(text, [[/\]])
end

--- Asserts we are currently in Visual mode, optionally in a specific visual mode kind
---@param goal string Reason why visual mode is needed, for better error msg
---@param restrict_visual_kind? string[] Restrict which kind of visual mode is allowed
---  (defaults to all)
---@return string visual_kind The actual active kind of visual mode
function U.assert_visual_mode(goal, restrict_visual_kind)
  local mode_char_to_visual_kind = {
    ["v"] = "visualchar",
    ["V"] = "visualline",
    [""] = "visualblock",
  }
  if not restrict_visual_kind then
    restrict_visual_kind = vim.tbl_values(mode_char_to_visual_kind)
  end
  local visual_kind = mode_char_to_visual_kind[vim.fn.mode()]
  if not visual_kind then
    -- let's not try to handle cases here, just raise
    error(U.str_concat("Cannot ", goal, ", not in visual mode"))
  end
  if not vim.tbl_contains(restrict_visual_kind, visual_kind) then
    -- let's not try to handle cases here, just raise
    error(U.str_space_concat{
      U.str_concat("Cannot ", goal, ","),
      "not in accepted visual mode: was", visual_kind,
      "but only accepts: ", table.concat(restrict_visual_kind, " or "),
    })
  end
  return visual_kind
end

--- Returns lines of current visual selection
---
--- NOTES:
---   - does NOT preserve Visual mode, ends in Normal mode
---   - preserves cursor position
---
---@return string[]
function U.get_visual_selection_lines()
  -- NOTE: Visual selection is a pain to get reliably while handling all cases.
  -- See this PR that attempts to add a vim.get_visual_selection() function:
  --   https://github.com/neovim/neovim/pull/13896
  U.assert_visual_mode("get visual lines")
  -- Register 'v' is used to copy visual selection in (easiest way to get visual selection)
  -- We also save/restore the cursor as yank would move it
  return U.save_run_restore({ save_registers = {"v"}, save_cursor = true }, function()
    vim.cmd[[noautocmd normal! "vy]]
    return vim.fn.getreginfo("v").regcontents
  end)
end

---@alias Pos0Like {row: integer, col: integer}
---
---@class Pos0
---@field row: integer
---@field col: integer
local Pos0 = {}
---@param pos0 Pos0Like
---@return Pos0
function Pos0.new(pos0)
  return setmetatable(pos0, { __index = Pos0 })
end
---@param pos0_delta.row? integer
---@param pos0_delta.col? integer
---@return Pos0
function Pos0:with_delta(pos0_delta)
  return Pos0.new({
    row = self.row + (pos0_delta.row or 0),
    col = self.col + (pos0_delta.col or 0),
  })
end
-- Expose Pos0 class
U.Pos0 = Pos0

--- Get the start & end positions of the current visual selection, must be called from Visual mode.
---@return {start_pos0: Pos0, end_pos0: Pos0}
function U.get_visual_start_end_pos0()
  -- limit to visualchar & visualline (don't need for visualblock for now)
  local visual_mode_kind = U.assert_visual_mode("get visual start/end", {"visualchar", "visualline"})

  -- get current cursor pos
  local cursor_pos10 = vim.api.nvim_win_get_cursor(0)
  local cursor_pos0 = Pos0.new{ row = cursor_pos10[1] -1, col = cursor_pos10[2] }
  -- get other side of visual selection
  local other_side_posinfo = vim.fn.getpos("v")
  local other_side_pos0 = Pos0.new{ row = other_side_posinfo[2] -1, col = other_side_posinfo[3] -1 }

  -- start_pos0 is the top-left corner
  local start_pos0 = Pos0.new{
    row = math.min(cursor_pos0.row, other_side_pos0.row),
    col = math.min(cursor_pos0.col, other_side_pos0.col),
  }
  -- end_pos0 is the bottom-right corner
  local end_pos0 = Pos0.new{
    row = math.max(cursor_pos0.row, other_side_pos0.row),
    col = math.max(cursor_pos0.col, other_side_pos0.col),
  }

  if visual_mode_kind == "visualline" then
    start_pos0.col = 0
    end_pos0.col = vim.v.maxcol
  end
  -- print(U.str_space_concat{
  --   "visual_mode_kind", vim.inspect(visual_mode_kind),
  --   "cursor_pos0", vim.inspect{cursor_pos0.row, cursor_pos0.col},
  --   "other_side_pos0", vim.inspect{other_side_pos0.row, other_side_pos0.col},
  --   "start_pos0", vim.inspect{start_pos0.row, start_pos0.col},
  --   "end_pos0", vim.inspect{end_pos0.row, end_pos0.col},
  -- })
  return {
    start_pos0 = start_pos0,
    end_pos0 = end_pos0,
  }
end

--- Get char at given 0-indexed buffer position, or nil if out of bound
---@param pos0 Pos0 The 0-indexed position of char to get
---@return string?
-- FIXME: need to consider byte/char/unicode ?
function U.try_get_buf_char_at_pos0(pos0)
  if pos0.row < 0 or vim.fn.line("$") <= pos0.row then
    return nil -- row out of bound
  end
  local line = vim.api.nvim_buf_get_lines(0, pos0.row, pos0.row +1, false)[1]
  if pos0.col < 0 or #line <= pos0.col then
    return nil -- col out of bound
  end
  return line:sub(pos0.col +1, pos0.col +1)
end

--- Feed the given keys as if typed (sync call).
---   This is basically a nice wrapper around nvim_feedkeys
---@param keys string
---@param opts.remap bool Whether to use mappings if any
---@param opts.replace_termcodes bool Whether termcodes like `\<esc>` should be replaced
function U.feed_keys_sync(keys, opts)
  local opts = U.normalize_arg_opts_with_default(opts, {
    remap = false,
    replace_termcodes = false,
  })

  if opts.replace_termcodes then
    keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
  end

  local feedkeys_mode = ""
  if opts.remap then
    feedkeys_mode = feedkeys_mode .. "m" -- remap
  else
    feedkeys_mode = feedkeys_mode .. "n" -- noremap
  end
  feedkeys_mode = feedkeys_mode .. "x" -- execute right away
  feedkeys_mode = feedkeys_mode .. "!" -- do not auto-end insert mode

  -- escape_ks=false : keys should have gone through nvim_replace_termcodes already
  vim.api.nvim_feedkeys(keys, feedkeys_mode, false)
end

return U
