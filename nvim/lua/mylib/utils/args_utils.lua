local U_args = {}

--- Normalizes received table-args or multi-args to a table.
---   Allows the caller to pass it a set of args or a table of args, and always get a table of args
---   back to manipulate.
---@param ... any|any[] Args or table of args
---@return any[]
function U_args.normalize_multi_args(...)
  local nargs = select("#", ...)
  local first_arg = ({...})[1] -- note: nil when no args
  if nargs == 1 and type(first_arg) == "table" then
    return first_arg
  else
    return {...}
  end
end

--- Normalizes received opts by filling the blanks (at toplevel, no deep merge) with given defaults
---@param given_opts table? The given options
---@param default_opts table The default options
---@return table
function U_args.normalize_arg_opts_with_default(given_opts, default_opts)
  return vim.tbl_extend("force", default_opts, given_opts or {})
end

--- Normalizes a single item or a list of items to a list of item(s).
---@param item_or_items any|any[] A single item (must not be a table) or a list of items
---@return any[]
function U_args.normalize_arg_one_or_more(item_or_items)
  if type(item_or_items) == "table" then
    return item_or_items
  else
    return {item_or_items}
  end
end

return U_args
