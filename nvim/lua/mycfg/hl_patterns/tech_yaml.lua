local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
local patterns = {}

---@param pattern_spec mycfg.hl_patterns.PatternSpec
---@return mycfg.hl_patterns.PatternSpec
local ft_only = function(pattern_spec)
  return _U.pattern_for_ft_only({"yaml"}, pattern_spec)
end

-- e.g. `uses: some-org/some-repo/foo/bar/baz@version-rev`
--             ^^^^^^^^^^^^^^^^^^
patterns.yml_gha_workflow_uses_repo = ft_only {
  pattern = "uses: ()%w[%w_-]+/[%w_.-]+()",
  group = _U.define_hl("yml_gha_workflow_uses_repo", {
    ctermfg = 252,
    italic = true,
  }),
}
-- e.g. `uses: some-org/some-repo/foo/bar/baz@version-rev`
--                                           ^
patterns.yml_gha_workflow_uses_at_sym = ft_only {
  -- Same as previous, focused on the param name
  pattern = "uses: [^@]+()@()",
  group = _U.define_hl("yml_gha_workflow_uses_at_sym", {
    ctermfg = 242,
    bold = true,
  }),
}
-- e.g. `uses: some-org/some-repo/foo/bar/baz@version-rev`
--                                            ^^^^^^^^^^^
patterns.yml_gha_workflow_uses_rev = ft_only {
  -- Same as previous, focused on the param name
  pattern = "uses: [^@]+@().+()",
  group = _U.define_hl("yml_gha_workflow_uses_rev", {
    ctermfg = 208,
  }),
}

return patterns
