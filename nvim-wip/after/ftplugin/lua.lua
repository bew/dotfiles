-- Force disable auto-comment-leader on 'o' or 'O'.
vim.opt_local.formatoptions:remove { "o" }

-- LSP Setup
local function lsp_setup()
  vim.lsp.start {
    name = "lua_ls",
    cmd = {"lua-language-server"},
    -- TODO: Move this in a central location in config (it's not specific!)
    capabilities = vim.tbl_deep_extend(
      "force",
      vim.lsp.protocol.make_client_capabilities(),
      require"cmp_nvim_lsp".default_capabilities(),
      {
        -- Disable snippets in completion candidates
        textDocument = { completion = { completionItem = { snippetSupport = false } } }
      }
    ),
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
