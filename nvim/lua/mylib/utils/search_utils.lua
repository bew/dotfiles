local U_args = require"mylib.utils.args_utils"
local Pos0 = require"mylib.utils.pos_utils".Pos0

local U_search = {}

---@class mylib.Opts.CurrentSearchSetter
---@field escaped? boolean Whether the given text was already escaped
---@field with_bounds? boolean|{before: boolean, after: boolean}

--- Set current search with the given text but without moving the cursor,
---   as if we made a search and moved the cursor back to position.
---
---@param text string|string[] The text to search,
---  will be escaped if opts.escaped is false (the default)
---@param opts? mylib.Opts.CurrentSearchSetter
---  Whether to add word bounds before/after text (none by default)
function U_search.set_current_search(text, opts)
  local text_lines = U_args.normalize_arg_one_or_more(text)
  local opts = U_args.normalize_arg_opts_with_default(opts, {
    escaped = false, -- by default, assume it's not
    with_bounds = false,
  })
  -- normalize opts.with_bounds to structured data
  local with_bounds_opt = opts.with_bounds -- (note: var necessary for type narrowing)
  if type(with_bounds_opt) == "boolean" then
    opts.with_bounds = { before = with_bounds_opt, after = with_bounds_opt }
  end
  local search_payload
  do -- process given text
    if not opts.escaped then
      text_lines = vim.tbl_map(U_search.escape_text_for_search, text_lines)
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
---@param opts {allow_backslash: boolean}
---@return string
function U_search.escape_text_for_search(text, opts)
  local to_escape = [[/]]
  if not (opts and opts.allow_backslash) then
    to_escape = to_escape .. [[\]]
  end
  return vim.fn.escape(text, to_escape)
end

--- Find positions of match containing the cursor
---@param pattern string Search pattern
---@param pos mylib.Pos0 Position where to search for a match
---@return mylib.RangePos0?
function U_search.try_get_match_range_near(pattern, pos)
  local saved_cursor = vim.api.nvim_win_get_cursor(0) -- (1,0)-indexed API pos
  local saved_view = vim.fn.winsaveview()
  local function restore_things()
    vim.api.nvim_win_set_cursor(0, saved_cursor)
    vim.fn.winrestview(saved_view)
  end

  -- Set cursor at pos, as `searchpos` works around cursor pos
  vim.api.nvim_win_set_cursor(0, {pos.row+1, pos.col})

  -- Search for closest start pos for match
  ---@type mylib.Pos0
  local start_pos = (function()
    -- Try search for match at pos
    local maybe_match_here = Pos0.try_from_vimpos("pos11", vim.fn.searchpos(pattern, "nc"))
    if maybe_match_here and maybe_match_here == pos then
      return maybe_match_here
    end

    -- Otherwise, try search for last match (pos might be on it, or not)
    return Pos0.try_from_vimpos("pos11", vim.fn.searchpos(pattern, "ncb"))
  end)()
  if not start_pos then
    -- Didn't find any match, no range
    restore_things()
    return nil
  end

  -- Move cursor to start pos to find the end pos of this match
  vim.api.nvim_win_set_cursor(0, start_pos:to_1_0_indexed())
  local end_pos = Pos0.from_vimpos("pos11", vim.fn.searchpos(pattern, "nce"))

  restore_things()
  return { start_pos = start_pos, end_pos = end_pos }
end

--- Check if cursor is on a search match (supports multiline)
---@param pos mylib.Pos0 Position to check
---@return boolean
function U_search.is_pos_on_search_match(pos)
  if vim.fn.searchcount().total == 0 then
    -- Early return, there are zero match in the file
    return false
  end

  local pattern = vim.fn.getreg("/")
  -- note: missing pattern already handled by searchcount's early return above

  -- Try get near match range
  local range = U_search.try_get_match_range_near(pattern, pos)
  if not range then
    return false
  end

  -- Check if pos is within match range
  return pos:is_within_incl_range(range)
end

---@param pattern string
---@return mylib.Pos0[]
function U_search.get_pos_for_all_search_results(pattern)
  ---@type mylib.Pos0[]
  local positions = {}
  local saved_cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, Pos0.new{row=0, col=0}:to_1_0_indexed())
  while true do
    local pos = Pos0.try_from_vimpos("pos11", vim.fn.searchpos(pattern, 'W'))
    if not pos then
      break
    end
    table.insert(positions, pos)
    -- Move cursor forward to avoid infinite loop
    vim.api.nvim_win_set_cursor(0, pos:to_1_0_indexed())
  end
  vim.api.nvim_win_set_cursor(0, saved_cursor)
  return positions
end

return U_search
