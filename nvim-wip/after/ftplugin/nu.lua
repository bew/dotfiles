
local function lsp_setup()
  vim.lsp.start {
    name = "nu-lsp",
    cmd = {"nu", "--lsp"},
    -- TODO: Move this in a central location in config (it's not specific to Rust!)
    capabilities = vim.tbl_deep_extend(
      "force",
      vim.lsp.protocol.make_client_capabilities(),
      require"cmp_nvim_lsp".default_capabilities(),
      {
        -- Disable snippets in completion candidates
        textDocument = { completion = { completionItem = { snippetSupport = false } } }
      }
    ),
    root_dir = vim.fs.root(0, ".git")
  }
end
if vim.fn.executable("nu") == 1 then
  lsp_setup()
else
  vim.notify("LSP not found")
end
