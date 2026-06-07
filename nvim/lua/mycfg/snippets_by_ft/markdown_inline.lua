-- vim:set ft=lua.luasnip:
local SU = require"mycfg.snippets_by_ft._utils" -- Snip Utils

SU.filetype_setup {
  filetype = "markdown_inline", -- same as current collection
  inherits_from = {"markdown"},
}
