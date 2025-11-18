-- note: this complements the lsp configs from rustaceanvim plugin

---@type vim.lsp.Config
return {
  -- ref: https://rust-analyzer.github.io/book/configuration.html
  settings = {
    -- Prefer to use `Self` over the type name when inserting a type.
    -- (e.g. in "fill match arms" assist)
    ["rust-analyzer.assist.preferSelf"] = true, -- (default: false)
    -- Number of enum variants to display in hover.
    ["rust-analyzer.hover.show.enumVariants"] = 10, -- (default: 5)
    -- Number of struct/enum/union fields to display in hover.
    ["rust-analyzer.hover.show.fields"] = 10, -- (default: 5)
    -- Disable import insertion to merge new imports into single path glob imports like `use std::fmt::*;`.
    ["rust-analyzer.imports.merge.glob"] = false,
  },
}
