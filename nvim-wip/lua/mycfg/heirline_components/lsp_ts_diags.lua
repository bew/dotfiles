local hline_conditions = require"heirline.conditions"

local UC = require"mylib.unicode"

local M = {}

M.LspActive = {
  condition = hline_conditions.lsp_attached,
  update = {"LspAttach", "LspDetach"},

  provider = function()
    local maybe_nb_clients = ""
    local nb_clients = #vim.tbl_keys(vim.lsp.get_active_clients({ bufnr = 0 }))
    if nb_clients > 1 then
      maybe_nb_clients = UC.superscript(tostring(nb_clients))
    end
    return "LSP" .. maybe_nb_clients
  end,
  -- TODO: change color based on LSP status
  --   Would need to track a number of progress messages 🤔
  --   See https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workDoneProgress and following objects
  hl = { ctermfg = 34, },
}

M.TreesitterStatus = {
  condition = function()
    -- GRR: There is no (@v0.9) builtin/simple way to check if the current buffer has a parser
    -- without triggering an error.
    local success = pcall(vim.treesitter.get_parser)
    return success
  end,

  provider = function()
    return "TS"
  end,
  hl = function()
    if vim.o.syntax ~= "" then
      -- TS is NOT used for syntax highlighting
      return { ctermfg = 244 }
    else
      -- TS is used for syntax highlighting
      return { ctermfg = 34 }
    end
  end,
}

return M
