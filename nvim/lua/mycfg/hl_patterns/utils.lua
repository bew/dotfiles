local U = require"mylib.utils"

local _U = {}

--- Wrap pattern with word bounds before/after as needed if it starts/ends as a word,
---   to prevent matching the pattern inside another word.
---@param pattern string The pattern to wrap
---@return string
function _U.keywordize(pattern)
  if pattern:match("^[%a]") then
    -- Start of pattern is a word, add frontier
    -- note: frontier means:
    --   from `not in set 'letters'` to `in set 'letters'`
    pattern = "%f[%a_-]()" .. pattern
  end
  if pattern:match("%a$") then
    -- End of pattern is a word, add frontier
    -- note: frontier means:
    --   from `not in set 'not letters'` to `in set 'not letters'`
    pattern = pattern .. "()%f[^%a_-]"
  end
  return pattern
end
-- Test cases:
--   should match `META`
--   should match `META`
--   should match `(META)`
--   should fail  `_META`
--   should fail  `META_`
--   should fail  `_META_`

--- Define & return highlight for a pattern
---@param name string The ID for the pattern highlight (will be used as suffix for full hl group)
---@param hl_spec vim.api.keyset.highlight The hl spec for the highlight (see `:h nvim_set_hl`)
---@return string The full highlight group name
function _U.define_hl(name, hl_spec)
  local full_name = "hl_pattern." .. name
  U.hl.set(full_name, hl_spec)
  return full_name
end

--- Wrap the given pattern spec to enable it only in buffers with one of the allowed filetype
---@param allowed_filetypes string[] Allowed filetypes for buffer
---@param pattern_spec mycfg.hl_patterns.PatternSpec
---@return mycfg.hl_patterns.PatternSpec
function _U.pattern_for_ft_only(allowed_filetypes, pattern_spec)
  local original_patterns = pattern_spec.pattern
  pattern_spec.pattern = function(bufnr)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    if vim.tbl_contains(allowed_filetypes, ft) then
      -- Current buffer has an authorized filetype, return the patterns
      if type(original_patterns) == "function" then
        return original_patterns(bufnr)
      else
        return original_patterns
      end
    end
    return nil
  end
  return pattern_spec
end

return _U
