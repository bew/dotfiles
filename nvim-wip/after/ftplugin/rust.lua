-- Force disable auto-comment-leader on 'o' or 'O'.
vim.opt_local.formatoptions:remove { "o" }

------ LSP Setup 🤔
-- TODO: setup https://github.com/mrcjkb/rustaceanvim
-- 👉 Need sth to disable snippets support 👀
--    Opened: https://github.com/mrcjkb/rustaceanvim/issues/544
local function start_lsp_server()
  vim.lsp.start {
    name = "rust-az",
    cmd = {"rust-analyzer"},
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
    -- TODO: replace with `vim.fs.root` when it's available!
    root_dir = vim.fs.dirname(vim.fs.find({".git"}, { upward = true })[1])
  }
end
if vim.fn.executable("rust-analyzer") == 1 then
  start_lsp_server()
else
  vim.notify("LSP not found")
end
