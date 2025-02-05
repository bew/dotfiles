local U = {}

--- Wrap pattern with word bounds before/after as needed if it starts/ends as a word,
---   to prevent matching the pattern inside another word.
---@param pattern string The pattern to wrap
---@return string
function U.keywordize(pattern)
  if pattern:match("^%w") then
    -- Start of pattern is a word, add frontier
    pattern = "%f[%w]()" .. pattern
  end
  if pattern:match("%w$") then
    -- End of pattern is a word, add frontier
    pattern = pattern .. "()%f[%W]"
  end
  return pattern
end

--- Define highlight for a pattern
---@param name string The ID for the pattern highlight (will be used as suffix for full hl group)
---@param hl_spec table The hl spec for the highlight (see `:h nvim_set_hl`)
---@return string The full highlight group name
function U.define_hl(name, hl_spec)
  local full_name = "hl_pattern." .. name
  vim.api.nvim_set_hl(0, full_name, hl_spec)
  return full_name
end

return U
