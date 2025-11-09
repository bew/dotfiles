---@type vim.lsp.Config
return {
  filetypes = { "terraform", "terraform-vars" },

  cmd = { "terraform-ls", "serve" },
  root_markers = { ".terraform", ".git" },
}
