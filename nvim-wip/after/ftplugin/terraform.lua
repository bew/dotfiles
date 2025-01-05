
local function lsp_setup()
  vim.lsp.start {
    name = "terraform-ls",
    cmd = { 'terraform-ls', 'serve' },
    filetypes = { 'terraform', 'terraform-vars' },
    capabilities = require"mylib.lsp".get_default_capabilities(),
    root_dir = vim.fs.root(0, {
      ".terraform",
      ".git",
    }),
  }
end
if vim.fn.executable("terraform-ls") == 1 then
  lsp_setup()
else
  vim.notify("LSP not found")
end
