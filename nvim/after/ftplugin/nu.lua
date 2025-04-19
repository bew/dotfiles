
local function lsp_setup()
  vim.lsp.start {
    name = "nu-lsp",
    cmd = {"nu", "--lsp"},
    capabilities = require"mylib.lsp".get_default_capabilities(),
    root_dir = vim.fs.root(0, ".git")
  }
end
if vim.fn.executable("nu") == 1 then
  lsp_setup()
else
  vim.notify("LSP not found")
end
