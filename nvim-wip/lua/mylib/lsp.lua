local U = require"mylib.utils"

local M = {}

function M.get_default_capabilities()
  local completer_capabilities = {}
  if U.is_module_available"cmp_nvim_lsp" then
    completer_capabilities = require"cmp_nvim_lsp".default_capabilities()
  end
  return vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    completer_capabilities,
    {
      -- Disable snippets in completion candidates
      textDocument = { completion = { completionItem = { snippetSupport = false } } }
    }
  )
end

return M
