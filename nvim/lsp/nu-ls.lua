-- https://www.nushell.sh/
-- https://github.com/nushell/nushell
-- (no dedicated page on the LSP 👀 @2026-06)

---@type vim.lsp.Config
return {
  filetypes = { "nu", "nu.conf" },

  cmd = {"nu", "--lsp"},
}
