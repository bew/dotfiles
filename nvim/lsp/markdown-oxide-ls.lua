-- https://github.com/Feel-ix-343/markdown-oxide

-- Ensure that dynamicRegistration is enabled! This allows the LS to take into account actions like the
-- Create Unresolved File code action, resolving completions for unindexed code blocks, ...
-- ref: <https://github.com/Feel-ix-343/markdown-oxide#Neovim>
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = true

---@type vim.lsp.Config
return {
  filetypes = { "markdown" },

  cmd = { "markdown-oxide" },
  single_file_support = true,

  capabilities = capabilities,
}
