local ls = require"luasnip"
local ls_fmt = require"luasnip.extras.fmt".format_nodes
local U = require"mylib.utils"

local SU = {}

---@class SnipNodeT
---...

---@class SnipT
---@field env table
---...

---@class mysnips.FileTypeSetupArgs
---@field filetype string The filetype to extend
---@field inherits_from string[] The additional collections of snippets to use for `ft`

---@alias mysnips.ContextCondition
---| (fun(line_to_cursor: string, matched_trigger: string, captures): boolean)
---| any (for the magic condition objects, since LuaLS does not support metamethod checks..)

-- TMP, Until it is impl in LuaSnip!
---@class LS.SnipContext: table
---@field trig string
---@field trigEngine string
---@field condition? mysnips.ContextCondition
---@field resolveExpandParams? any

---@class mysnips.Context: LS.SnipContext
---@field desc? string Description of the snippet
---@field when? mysnips.ContextCondition
---@field rx? boolean Whether the trigger is a pattern
---@field resolver? any

---@class LS.FmtOpts
---@field trim_empty boolean
---@field dedent boolean
---@field delimiters string

---@class mysnips.FmtOpts: LS.FmtOpts

---@alias mysnips.MyFmtArgs {[1]: string, [2]: table, [3]: mysnips.FmtOpts?, opts: mysnips.FmtOpts?}

--- Set `filetype` as inheriting snippets from the given list of extra snippets collections.
---@param args mysnips.FileTypeSetupArgs Args table
SU.filetype_setup = function(args)
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
--- local snip = SU.get_snip_fn(MYSNIPPETS)
---
--- snip("hi!", { desc = "Hello? o/" }, {
---   t"Hello world!",
--- })
--- ```
--
-- FIXME: support multiple triggers
--   !!! luasnip doesn't seem to support to assign the same 'context' to 2 snippets :/
---@param list_of_snippets SnipT[]
SU.get_snip_fn = function(list_of_snippets)
  --- Define snippet!
  ---@param trigger string
  ---@param context mysnips.Context
  ---@param nodes SnipNodeT|SnipNodeT[]
  ---@param opts? table
  return function(trigger, context, nodes, opts)
    context.trig = trigger
    if context.rx then
      context.trigEngine = "pattern"
    end
    context.condition = context.when or nil
    context.resolveExpandParams = context.resolveExpandParams or context.resolver or nil
    -- IDEA: add feature system, to compose context features like resolveExpandParams 🤔
    -- I want to be able to define a snip like:
    -- snip(
    --   "trig!", {desc = "some desc", feats = {SF.ignore_spaces_after}},
    --   ...
    -- )
    -- Where `feats` is a list of 'features' aka functions that return set of context fields to be
    --   merged with snip context.
    --
    -- IDEA: Allow snip def with trig in context tbl (almost like ls.snippet):
    --   snip({"trig!", desc = ...}, ...)
    -- This would allow support for multi-trigger snippets like:
    --   snip({
    --     "trig!",
    --     {"other-trig!", feats = {weird_stuff_fn}},
    --     common = {desc = ..., when = common_condition_fn}
    --   }, ...)
    table.insert(list_of_snippets, ls.snippet(context, nodes, opts))
  end
end

------------------------------------
-- Snip top-level helpers

-- NOTE: functionally the same as `luasnip.fmta`, but using a table as only param instead of
--   separate arguments (helps with formatting & allows trailing comma on last param).
-- NOTE: fmt already returns a list of nodes and we can't nest thoses, so we need to pass
--   fmt(...) directly to snip (or as a choiceNode item).
--   ref: https://github.com/L3MON4D3/LuaSnip/issues/828#issuecomment-1472643275
---@param args mysnips.MyFmtArgs
SU.myfmt = function(args)
  -- args[1] is the fmt string,
  -- args[2] is the set of nodes,
  -- args[3] is the set of options,
  local opts = args.opts or args[3] or {}
  if opts.delimiters == nil then
    -- Use `<foo>` by default for placeholders instead of `{foo}`
    opts.delimiters = "<>"
  end
  args[3] = opts
  return ls_fmt(unpack(args))
end

--- Same as `myfmt`, disabling trim & dedent for the format string
---@param args mysnips.MyFmtArgs
SU.myfmt_no_strip = function(args)
  args.opts = args.opts or {}
  args.opts.trim_empty = false
  args.opts.dedent = false
  return SU.myfmt(args)
end

--- Same as `myfmt`, using `{}` delimiters (like the builtin luasnip fmt)
---@param args mysnips.MyFmtArgs
SU.myfmt_braces = function(args)
  args.opts = args.opts or {}
  args.opts.delimiters = "{}"
  return SU.myfmt(args)
end

---@return {row: integer, col: integer}
local function _get_cursor_pos0()
  local cur = vim.api.nvim_win_get_cursor(0)
  return {
    row = cur[1] - 1,
    col = cur[2],
  }
end

---@class mysnips.ResolverSpecForExpandParams
---@field delete_after_trig string|string[] Text patterns to ignore (delete) before snip expansion

--- Make fn for resolveExpandParams context option, following given spec
---@param spec mysnips.ResolverSpecForExpandParams
--
-- The `resolveExpandParams` snip ctx fn allows (among other things) to tweak what will be deleted
-- before snip expansion.
--
-- SEE: https://github.com/L3MON4D3/LuaSnip/discussions/1271
-- REF: https://github.com/L3MON4D3/LuaSnip/blob/33b06d72d220aa56/lua/luasnip/extras/postfix.lua#L13
SU.mk_expand_params_resolver = function(spec)
  spec = spec or {}
  local delete_after_trig_pats = U.args.normalize_arg_one_or_more(spec.delete_after_trig or {})

  return function(_snip, _line_to_cursor, matched, _captures)
    local pos0 = _get_cursor_pos0()
    local line = vim.api.nvim_get_current_line()
    local line_after_cursor = line:sub(vim.fn.col".")
    local longest_after_match = ""
    for _, pattern in ipairs(delete_after_trig_pats) do
      local match = line_after_cursor:match(pattern)
      if match and #match > #longest_after_match then
        longest_after_match = match
      end
    end
    return {
      clear_region = {
        from = {pos0.row, pos0.col - #matched}, -- from before snip match
        to = {pos0.row, pos0.col + #longest_after_match}, -- to after spaces
      }
    }
  end
end


------------------------------------
-- Node helpers

--- Returns whether the snippet has a previously-cut selection available.
---   to be used via snip.env.LS_SELECT_RAW and related snip env vars.
---@param snip SnipT
---@return boolean
SU.has_stored_selection = function(snip)
  -- REF: https://github.com/L3MON4D3/LuaSnip/issues/1030
  return snip.env.LS_SELECT_RAW and #snip.env.LS_SELECT_RAW > 0
end

--- Insert node that default to last visual (saved) selection if any, else given text
---@param index integer Snip node index
---@param default_text? string Default text if no stored selection to use
---@return SnipNodeT
SU.insert_node_default_selection = function(index, default_text)
  local default_text = default_text or ""
  return ls.dynamic_node(index, function(_, snip)
    -- Find top-level snippet (only one with non-nil `env`!)
    -- FIXME: For some reason `ls.get_active_snip()` returns None 👀
    -- local top_snip = ls.get_active_snip()
    while snip.parent do
      snip = snip.parent
    end

    local maybe_after_node = ls.text_node""
    if SU.has_stored_selection(snip) then
      -- override default text with last selection
      default_text = snip.env.LS_SELECT_DEDENT
      maybe_after_node = ls.insert_node(2) -- node after, to have a tabstop after injected selection
    end
    return ls.snippet_node(nil, {
      ls.insert_node(1, default_text),
      maybe_after_node,
    })
  end)
end

local node_key_ref = require"luasnip.nodes.key_indexer".new_key -- to use key indexed node refs
local node_absolute_ref = require"luasnip.nodes.absolute_indexer"
---@param ref string|table|integer
SU.node_ref = function(ref)
  if type(ref) == "string" then
    return node_key_ref(ref)
  elseif type(ref) == "table" then
    return node_absolute_ref(ref)
  else
    return ref
  end
end

return SU
