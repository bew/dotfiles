-- Force disable auto-comment-leader on 'o' or 'O'.
vim.opt_local.formatoptions:remove { "o" }

-- TODO: Remap some insert-mode keys to disable/enable auto-pairing based on
--       the presence of char before or not:
--       Example:
--       * `impl│`    then `<`  should become `impl<│>`     (autopair)
--       * `if foo │` then `<`  should become `if foo <│`   (no autopair)
--       * `foo: &│`  then `'`  should become `foo: &'│`    (no autopair)
--       * `just(│)`  then `'`  should become `just('│')`   (autopair)

------ LSP Setup 🤔
local function lsp_setup()
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
  lsp_setup()
else
  vim.notify("LSP not found")
end
