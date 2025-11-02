local U_args = {}

---@alias mylib.Ty.NotInteger (string|boolean|(fun(...): ...)|table)
---@alias mylib.Ty.NotList<T> (string|number|boolean|(fun(...): ...)|{[mylib.Ty.NotInteger]: T})

--- Normalizes received multiple args or a single list of args, into a list of args.
---
---@generic T
---@param ... (T[])|mylib.Ty.NotList<T> Args or a single list of args
---@return T[]
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
---
---@generic T: table
---@param given_opts T? The given options
---@param default_opts T The default options
---@return T
function U_args.normalize_arg_opts_with_default(given_opts, default_opts)
  return vim.tbl_extend("force", default_opts, given_opts or {})
end

--- Normalizes a single item or a list of items to a list of item(s).
---
---@generic T
---@param item_or_items (T[])|mylib.Ty.NotList<T> A single item (must not be a list) or a list of items
---@return T[]
-- note: @overload doesn't support generics 😬
-- ISSUE: https://github.com/LuaLS/lua-language-server/issues/723
function U_args.normalize_arg_one_or_more(item_or_items)
  if type(item_or_items) == "table" and vim.islist(item_or_items) then
    return item_or_items
  else
    return {item_or_items}
  end
end

return U_args
