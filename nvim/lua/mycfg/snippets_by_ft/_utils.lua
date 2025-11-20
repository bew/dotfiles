local ls = require"luasnip"
local ls_fmt = require"luasnip.extras.fmt".format_nodes
local U = require"mylib.utils"

local SU = {}

---@class mysnips.Opts.FileTypeSetup
---@field filetype string The filetype to extend
---@field inherits_from string[] The additional collections of snippets to use for `ft`

---@class mysnips.SnipContext: LuaSnip.SnipContext
---@field when? LuaSnip.SnipContext.ConditionObj Sets both `condition` & `show_condition`
---  (shouldn't depend on the trigger! Only on `line_to_cursor`!)
---@field expand_when? LuaSnip.SnipContext.Condition Sets `condition` (overrides `when`)
---@field show_when? LuaSnip.SnipContext.ShowCondition Sets `show_condition` (overrides `when`)
---@field rx? boolean Whether the trigger is a pattern
---@field resolver? LuaSnip.ResolveExpandParamsFn

---@class mysnips.Opts.MyFmt
---@field [1] string
---@field [2] {[string]: LuaSnip.Node}
---@field [3] LuaSnip.Opts.Extra.Fmt?

---@class mysnips.Opts.MyFmtInner: mysnips.Opts.MyFmt
---@field opts LuaSnip.Opts.Extra.Fmt?

--- Set `filetype` as inheriting snippets from the given list of extra snippets collections.
---@param args mysnips.Opts.FileTypeSetup Args table
function SU.filetype_setup(args)
  vim.validate("filetype", args.filetype, "string")
  vim.validate("inherits_from", args.inherits_from, "table")

  local ft_snips_collections = {args.filetype}
  vim.list_extend(ft_snips_collections, args.inherits_from)
  -- Set which snippets collection to consider for the given filetype
  -- ref: https://github.com/L3MON4D3/LuaSnip/discussions/1003 and the DOC
  ls.filetype_set(args.filetype, ft_snips_collections)
end

--- Get a function that declares a snippet inside the given list_of_snippets table.
---
--- Usage:
--- ```lua
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
---@param list_of_snippets LuaSnip.Snippet[]
function SU.get_snip_fn(list_of_snippets)
  --- Define snippet!
  ---@param trigger string
  ---@param context mysnips.SnipContext
  ---@param nodes LuaSnip.Node|LuaSnip.Node[]
  ---@param opts? LuaSnip.Opts.Snippet
  return function(trigger, context, nodes, opts)
    context.trig = trigger
    if context.rx then
      context.trigEngine = "pattern"
    end
    context.condition = context.expand_when or context.when or nil
    context.show_condition = context.show_when or context.when or nil
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
--
-- NOTE: This hidden myfmt impl allows to have explicit `opts` internally,
--   without exposing it to the outside world.
--
---@param args mysnips.Opts.MyFmtInner
---@return LuaSnip.Node[]
function SU._myfmt_inner(args)
  -- args[1] is the fmt string (required),
  vim.validate("fmt-string", args[1], "string")
  -- args[2] is the set of nodes (required),
  vim.validate("nodes", args[2], "table")
  -- args.opts or args[3] is the set of options (optional),
  -- (NOTE: `args.opts` is used by `myfmt_*` helper functions)
  vim.validate("fmt-options", args.opts or args[3], "table", true)

  local opts = args.opts or args[3] or {}
  if opts.delimiters == nil then
    -- Use `<foo>` by default for placeholders instead of `{foo}`
    opts.delimiters = "<>"
  end
  args[3] = opts
  return ls_fmt(unpack(args))
end

--- Use a format string with placeholders to interpolate nodes.
---@param args mysnips.Opts.MyFmt
---@return LuaSnip.Node[]
function SU.myfmt(args)
  ---@cast args mysnips.Opts.MyFmtInner
  return SU._myfmt_inner(args)
end

--- Same as `myfmt`, disabling trim & dedent for the format string
---@param args mysnips.Opts.MyFmt
---@return LuaSnip.Node[]
function SU.myfmt_no_strip(args)
  ---@cast args mysnips.Opts.MyFmtInner
  args.opts = args.opts or {}
  args.opts.trim_empty = false
  args.opts.dedent = false
  return SU._myfmt_inner(args)
end

--- Same as `myfmt`, using `{}` delimiters (like the builtin luasnip fmt)
---@param args mysnips.Opts.MyFmt
---@return LuaSnip.Node[]
function SU.myfmt_braces(args)
  ---@cast args mysnips.Opts.MyFmtInner
  args.opts = args.opts or {}
  args.opts.delimiters = "{}"
  return SU._myfmt_inner(args)
end

--- Same as `myfmt`, using `{}` delimiters & disabling trim & dedent
---@param args mysnips.Opts.MyFmt
---@return LuaSnip.Node[]
function SU.myfmt_braces_no_strip(args)
  ---@cast args mysnips.Opts.MyFmtInner
  args.opts = args.opts or {}
  args.opts.delimiters = "{}"
  args.opts.trim_empty = false
  args.opts.dedent = false
  return SU._myfmt_inner(args)
end

---@class mysnips.Opts.SpecForResolveExpandParams
---@field delete_after_trig string|string[] Text patterns to ignore (delete) before snip expansion

--- Make fn for resolveExpandParams context option, following given spec
---@param spec mysnips.Opts.SpecForResolveExpandParams
---@return LuaSnip.ResolveExpandParamsFn
--
-- The `resolveExpandParams` snip ctx fn allows (among other things) to tweak what will be deleted
-- before snip expansion.
--
-- SEE: https://github.com/L3MON4D3/LuaSnip/discussions/1271
-- REF: https://github.com/L3MON4D3/LuaSnip/blob/33b06d72d220aa56/lua/luasnip/extras/postfix.lua#L13
function SU.mk_expand_params_resolver(spec)
  spec = spec or {}
  ---@type string[]
  local delete_after_trig_pats = U.args.normalize_arg_one_or_more(spec.delete_after_trig or {})

  return function(_snip, _line_to_cursor, matched, _captures)
    local cursor_pos = U.Pos0.from_vimpos"cursor"
    local _, line_after_cursor = U.get_line_around_cursor()
    local longest_after_match = ""
    for _, pattern in ipairs(delete_after_trig_pats) do
      local match = line_after_cursor:match(pattern)
      if match and #match > #longest_after_match then
        longest_after_match = match
      end
    end
    ---@type LuaSnip.ExpandParams
    return {
      clear_region = {
        from = {cursor_pos.row, cursor_pos.col - #matched}, -- from before snip match
        to = {cursor_pos.row, cursor_pos.col + #longest_after_match}, -- to after spaces
      }
    }
  end
end


------------------------------------
-- Node helpers

--- Returns whether the snippet has a previously-cut selection available.
---   to be used via snip.env.LS_SELECT_RAW and related snip env vars.
---@param snip LuaSnip.Snippet
---@return boolean
function SU.has_stored_selection(snip)
  -- REF: https://github.com/L3MON4D3/LuaSnip/issues/1030
  return snip.env.LS_SELECT_RAW and #snip.env.LS_SELECT_RAW > 0
end

--- Insert node that default to last visual (saved) selection if any, else given text
---@param index integer Snip node index
---@param default_text? string Default text if no stored selection to use
---@return LuaSnip.Node
function SU.insert_node_default_selection(index, default_text)
  local default_text = default_text or ""
  return ls.dynamic_node(index, function(_, parent)
    -- Get the top-level snippet (the only one with `env`!)
    local snip = parent.snippet

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
---@return LuaSnip.NodeRef
function SU.node_ref(ref)
  if type(ref) == "string" then
    return node_key_ref(ref)
  elseif type(ref) == "table" then
    return node_absolute_ref(ref)
  else
    return ref
  end
end

return SU
