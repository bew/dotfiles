---@type vim.lsp.Config
return {
  filetypes = { "yaml", "json" },

  cmd = { "yaml-language-server", "--stdio" },
  single_file_support = true,
  settings = {
    -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
    redhat = { telemetry = { enabled = false } },

    yaml = {
      validate = true,
      hover = true,
      completion = true,
      schemaStore = {
        -- Auto-assigns JSON-Schema with files based on their name/path ✨
        enable = true,
        url = "https://www.schemastore.org/api/json/catalog.json",
      },
      schemas = {
        -- Set custom schemas for glob patterns
        -- ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
      },
    },
  },
}
