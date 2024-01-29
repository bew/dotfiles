
-- FIXME: Split up this file by topics?
-- => It's actually a bit difficult due to some functions being used everywhere
--   (like U.normalize_* or U.str_*) and the amount of re-use & cross referencing between functions.
--
-- TODO: write tests for all utils!!

local U = {}

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
  local feedkeys_mode = ""
  if opts.remap then
    feedkeys_mode = feedkeys_mode .. "m" -- remap
  else
    feedkeys_mode = feedkeys_mode .. "n" -- noremap
  end
  feedkeys_mode = feedkeys_mode .. "x" -- execute right away
  feedkeys_mode = feedkeys_mode .. "!" -- do not auto-end insert mode

  -- escape_ks=false : keys should have gone through nvim_replace_termcodes already
  vim.api.nvim_feedkeys(keys, "nx", false)
end

return U
