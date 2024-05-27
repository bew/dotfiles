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
--
-- FIXME: support multiple triggers
--   !!! luasnip doesn't seem to support to assign the same 'context' to 2 snippets :/
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

U.insert_node_default_selection = function(index, default_text)
  local default_text = default_text or ""
  return ls.dynamic_node(index, function(_, snip)
    local env = snip.env
    -- NOTE: Would be better to have a `has_selected_text` function to check this, so my code don't
    -- need to depend on the default/empty value of LS_SELECT_RAW when there are no 'stored' selection.
    --
    --   There is `require"luasnip.extras.conditions.show".has_selected_text` but it always seems to
    --   return `false` when in a snippet..
    --   And it feels weird to import something from such a specific module for a check that is not
    --   specific to show conditions..
    --
    -- => Opened: https://github.com/L3MON4D3/LuaSnip/issues/1030
    if env.LS_SELECT_RAW and env.LS_SELECT_RAW ~= "" then
      -- override default text with last selection
      default_text = env.LS_SELECT_RAW
    end
    return ls.snippet_node(nil, {
      ls.insert_node(1, default_text),
    })
  end)
end

return U
