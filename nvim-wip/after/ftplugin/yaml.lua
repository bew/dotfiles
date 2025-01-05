
local function lsp_setup()
  vim.lsp.start {
    name = "yamlls",
    cmd = { "yaml-language-server", "--stdio" },
    capabilities = require"mylib.lsp".get_default_capabilities(),
    root_dir = vim.fs.root(0, { ".git" }),

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
end
if vim.fn.executable("yaml-language-server") == 1 then
  lsp_setup()
else
  vim.notify("LSP not found")
end
