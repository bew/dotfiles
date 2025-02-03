-- Force disable auto-comment-leader on 'o' or 'O'.
vim.opt_local.formatoptions:remove { "o" }

-- LSP Setup
local function lsp_setup()
  vim.lsp.start {
    name = "lua_ls",
    cmd = {"lua-language-server"},
    capabilities = require"mylib.lsp".get_default_capabilities(),
    single_file_support = true,
    root_dir = vim.fs.root(0, {
      "stylua.toml",
      ".git",
    }),

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
      },
    },
  }
end
if vim.fn.executable("lua-language-server") == 1 then
  lsp_setup()
else
  vim.notify("LSP not found")
end
