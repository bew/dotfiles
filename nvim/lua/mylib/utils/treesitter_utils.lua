local U_ts = {}

--- Returns whether a Treesitter parser is available for the current buf
function U_ts.is_available_here()
  local success, _parser = pcall(vim.treesitter.get_parser)
  return success
end

---@class mylib.Opts.try_get_ts_node: vim.treesitter.get_node.Opts
---@field show_warning? boolean Show warning when no TS or no node

--- Try get Treesitter node at cursor, after checking TS is available here & parsing the file
---@param opts? mylib.Opts.try_get_ts_node
---@return TSNode?
function U_ts.try_get_node_at_cursor(opts)
  local opts = opts or {}
  local show_warning = opts.show_warning
  if opts.show_warning ~= nil then
    -- remove custom field, to pass to TS' get_node
    opts.show_warning = nil
  end
  ---@cast opts vim.treesitter.get_node.Opts

  if not U_ts.is_available_here() then
    if show_warning then
      vim.notify("!! Treesitter not available here..", vim.log.levels.ERROR)
    end
    return
  end

  vim.treesitter.get_parser():parse() -- ensure tree is parsed
  local node = vim.treesitter.get_node(opts)
  if not node then
    if show_warning then
      vim.notify("!! No Treesitter node here 👀", vim.log.levels.ERROR)
    end
    return
  end

  return node
end

--- Collect parents of given TSNode
---@param node TSNode
---@param opts? {until_node_type?: string}
---@return TSNode[]
function U_ts.collect_node_parents(node, opts)
  opts = opts or {}

  local parents = {} ---@type TSNode[]
  local node = node:parent() ---@type TSNode?
  -- Collect parent nodes until no more parent, or until the first 'class_definition' node
  while node do
    table.insert(parents, 1, node) -- prepend to the list of parents
    if opts.until_node_type and node:type() == opts.until_node_type then
      break
    end
    node = node:parent()
  end

  -- For DEBUG:
  -- local parent_types = vim.iter(parents):map(function(p) return p:type() end):totable()
  -- vim.print(parent_types)

  return parents
end

return U_ts
