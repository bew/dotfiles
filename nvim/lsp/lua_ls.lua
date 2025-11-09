---@type vim.lsp.Config
return {
  filetypes = { "lua", "lua.luasnip" },

  cmd = {"lua-language-server"},
  single_file_support = true,
  root_markers = { "stylua.toml", ".git" },

  -- All available settings: https://luals.github.io/wiki/settings/
  settings = {
    Lua = {
      completion = {
        keywordSnippet = "Disable",
        showWord = "Disable",
        workspaceWord = "Disable",
      },
      ["diagnostics.disable"] = {
        "redefined-local",
        "unused-vararg",
        "trailing-space",
      },
      diagnostics = {
        -- Ignore unused local variable starting with _ (e.g. `_ctx`)
        unusedLocalExclude = {"_*"},
      },
      ["format.enable"] = false,
      ["semantic.variable"] = false, -- TS does already a good job with code highlights
      -- Don't expand aliases in Hover, to avoid potentially looong function signatures
      ["hover.expandAlias"] = false,
    },
  },
}
