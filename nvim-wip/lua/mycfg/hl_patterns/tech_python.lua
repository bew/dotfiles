local _U = require"mycfg.hl_patterns.utils"

local patterns = {}

patterns.py_docstring_param = {
  pattern = ":param [%w_]*:",
  group = "@comment.documentation.emph",
}
patterns.py_docstring_param_name = {
  -- Same as previous, focused on the param name
  pattern = ":param ()[%w_]*():",
  group = _U.define_hl("py_docstring_param_name", {
    -- bold = true,
    italic = true,
    underdotted = true,
  }),
}

patterns.py_docstring_raises = {
  -- :raises Foo:
  -- :raises Foo, Bar:
  pattern = ":raises [%w_, ]*:",
  group = "@comment.documentation.emph.exception",
}
patterns.py_docstring_raises_excs = {
  pattern = ":raises ()[%w_, ]*():",
  group = _U.define_hl("py_docstring_raises_excs", {
    bold = true,
  }),
}

patterns.py_docstring_return = {
  pattern = ":return:",
  group = "@comment.documentation.emph.return",
}

return patterns
