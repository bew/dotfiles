local ls = require"luasnip"

local U = {}

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

return U
