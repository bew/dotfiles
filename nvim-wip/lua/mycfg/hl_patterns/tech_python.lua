local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
local patterns = {}

---@param pattern_spec mycfg.hl_patterns.PatternSpec
---@return mycfg.hl_patterns.PatternSpec
local ft_only = function(pattern_spec)
  return _U.pattern_for_ft_only({"python"}, pattern_spec)
end

patterns.py_docstring_param = ft_only {
  pattern = ":param [%w_]*:",
  group = "@comment.documentation.emph",
}
patterns.py_docstring_param_name = ft_only {
  -- Same as previous, focused on the param name
  pattern = ":param ()[%w_]*():",
  group = _U.define_hl("py_docstring_param_name", {
    italic = true,
    underdotted = true,
  }),
}

patterns.py_docstring_raises = ft_only {
  -- :raises Foo:
  -- :raises Foo, Bar:
  pattern = ":raises [%w_, ]*:",
  group = "@comment.documentation.emph.exception",
}
patterns.py_docstring_raises_excs = ft_only {
  pattern = ":raises ()[%w_, ]*():",
  group = _U.define_hl("py_docstring_raises_excs", {
    italic = true,
    underdotted = true,
  }),
}

patterns.py_docstring_return = ft_only {
  pattern = ":return:",
  group = "@comment.documentation.emph.return",
}

return patterns
