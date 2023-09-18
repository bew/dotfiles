local ls = require"luasnip"
local fmt = require"luasnip.extras.fmt".format_nodes

local U = {}

--- Set `filetype` as inheriting snippets from the given list of extra snippets collections.
---@param args Args table
---  @field filetype string The filetype to extend
---  @field inherits_from []string The additional collections of snippets to use for `ft`
U.filetype_setup = function(args)
  -- TODO: validate!
  vim.validate({
    opt_filetype = { args.filetype, "string" },
    opt_inherits_from = { args.inherits_from, "table" },
  })

  local ft_snips_collections = {args.filetype}
  vim.list_extend(ft_snips_collections, args.inherits_from)
  -- Set which snippets collection to consider for the given filetype
  -- ref: https://github.com/L3MON4D3/LuaSnip/discussions/1003 and the DOC
  ls.filetype_set(args.filetype, ft_snips_collections)
end

--- Get a function that declares a snippet inside the given list_of_snippets table.
---
--- Usage:
--- ```
--- local MYSNIPPETS = {}
--- local snip = U.get_snip_fn(MYSNIPPETS)
---
--- snip("hi!", { desc = "Hello? o/" }, {
---   t"Hello world!",
--- })
--- ```
U.get_snip_fn = function(list_of_snippets)
  return function(trigger, context, ...)
    context.trig = trigger
    table.insert(list_of_snippets, ls.snippet(context, ...))
  end
end

-- NOTE: functionally the same as `luasnip.fmta`, but using a table as only param instead of
--   separate arguments (helps with formatting & allows trailing comma on last param).
-- NOTE: fmt already returns a list of nodes and we can't nest thoses, so we need to pass
--   fmt(...) directly to snip (or as a choiceNode item).
--   ref: https://github.com/L3MON4D3/LuaSnip/issues/828#issuecomment-1472643275
U.myfmt = function(args)
  -- args[1] is the fmt string,
  -- args[2] is the set of nodes,
  -- args[3] is the set of options,
  args[3] = args[3] or {}
  if args[3].delimiters == nil then
    -- Use `<foo>` by default for placeholders instead of `{foo}`
    args[3].delimiters = "<>"
  end
  return fmt(unpack(args))
end

return U
