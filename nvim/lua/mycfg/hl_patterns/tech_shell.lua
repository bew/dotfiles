local U = require"mylib.utils"
local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
local patterns = {}

---@param pattern_spec mycfg.hl_patterns.PatternSpec
---@return mycfg.hl_patterns.PatternSpec
local ft_only = function(pattern_spec)
  return _U.pattern_for_ft_only({"bash", "sh", "zsh"}, pattern_spec)
end

-- e.g. Options like `-o` or `--option`
-- Match only the option name in `--option=value`
-- Does NOT match:
-- - in a word, like `text--not-option`
-- - in a string (TS), like `"string! --not-option"`
-- - in a parameter expansion, like `${VAR:-not-option}`
-- NOTE: This cannot be done with a custom Treesitter highlight query, because partial node
--   highlight is not supported.
patterns.shell_dashed_option_name = ft_only {
  -- note: the frontier pattern ensures there is no word or other dash before the first dash
  --   it also prevents a few other symbols that can give wrong highlight in non-TS buffers
  pattern = "%f[%w|:-]()%-%-?%w[%w_-]*=?()",
  group = function(bufnr, _match, data)
    local node = U.ts.try_get_node_at_cursor {
      bufnr = bufnr,
      pos = { data.line -1, data.from_col -1 },
    }
    -- note: all relevant option nodes have TS node type `word`
    if node and node:type() ~= "word" then
      return nil
    end
    return "@variable.parameter.argument"
  end,
}

return patterns
