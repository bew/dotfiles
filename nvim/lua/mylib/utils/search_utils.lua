local U_args = require"mylib.utils.args_utils"

local U_search = {}

---@class mylib.CurrentSearchSetterOpts
---@field escaped? boolean Whether the given text was already escaped
---@field with_bounds? boolean|{before: boolean, after: boolean}

--- Set current search with the given text but without moving the cursor,
---   as if we made a search and moved the cursor back to position.
---
---@param text string|string[] The text to search,
---  will be escaped if opts.escaped is false (the default)
---@param opts? mylib.CurrentSearchSetterOpts
---  Whether to add word bounds before/after text (none by default)
function U_search.set_current_search(text, opts)
  local text_lines = U_args.normalize_arg_one_or_more(text)
  local opts = U_args.normalize_arg_opts_with_default(opts, {
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
---@return string
function U_search.escape_text_for_search(text)
  return vim.fn.escape(text, [[/\]])
end

return U_search
