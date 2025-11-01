local hline_conditions = require"heirline.conditions"

local U = require"mylib.utils"
local UC = require"mylib.unicode"

local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE

local M = {}

M.LspActive = {
  condition = hline_conditions.lsp_attached,
  update = {"LspAttach", "LspDetach"},

  provider = function()
    local maybe_nb_clients = ""
    local nb_clients = #vim.tbl_keys(vim.lsp.get_clients({ bufnr = 0 }))
    if nb_clients > 1 then
      maybe_nb_clients = UC.superscript(tostring(nb_clients))
    end
    return "LSP" .. maybe_nb_clients
  end,
  hl = { ctermfg = 34, },
}

M.TreesitterStatus = {
  condition = function()
    return U.is_treesitter_available_here()
  end,
  provider = "TS",
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

---@param opts {hl: vim.api.keyset.highlight, sev: vim.diagnostic.SeverityInt, icon: string}
function M.mkDiagnosticForSeverity(opts)
  return {
    condition = function()
      local nb_diags = vim.diagnostic.count(0, {severity = opts.sev})[opts.sev] or 0
      return nb_diags > 0
    end,
    _,
    {
      provider = function()
        local nb_diags = vim.diagnostic.count(0, {severity = opts.sev})[opts.sev] or 0
        return opts.icon .. nb_diags
      end,
    },
    _,
    hl = function()
      opts.hl.bold = true
      return opts.hl
    end
  }
end

-- Show a checkmark when there is an LSP available and there's ZERO diagnostics ✨
M.ZeroDiagnosticsCheckmark = {
  condition = function()
    if not hline_conditions.lsp_attached() then return false end
    -- Check that there are ZERO diagnostics we're interested in
    local diags_by_sev = vim.diagnostic.count(0)
    local total_diags = vim.iter(diags_by_sev):fold(0, function(acc, it) return acc + it end)
    return total_diags == 0
  end,
  hl = { ctermfg = 35 },
  _,
  { provider = "󰄳 " },
  _,
}

M.Diagnostics = {
  update = {
    "LspAttach", -- to show checkmark early
    "LspDetach",
    "DiagnosticChanged",
    callback = function()
      -- Ensure the component is redrawn on update
      -- (otherwise it's only updated on cursor movement)
      vim.cmd.redrawstatus()
    end,
  },
  M.ZeroDiagnosticsCheckmark,
  {
    -- Only show this section if there is at least 1 diagnostic
    condition = function()
      local diags_by_sev = vim.diagnostic.count(0)
      local total_diags = vim.iter(diags_by_sev):fold(0, function(acc, it) return acc + it end)
      return total_diags > 0
    end,
    M.mkDiagnosticForSeverity {
      sev = vim.diagnostic.severity.ERROR,
      icon = "E",
      hl = { ctermfg = 250, ctermbg = 124 },
    },
    M.mkDiagnosticForSeverity {
      sev = vim.diagnostic.severity.WARN,
      icon = "W",
      hl = { ctermfg = 235, ctermbg = 214 },
    },
    M.mkDiagnosticForSeverity {
      sev = vim.diagnostic.severity.INFO,
      icon = "I",
      hl = { ctermfg = 250, ctermbg = 24 }, -- (?)
    },
    M.mkDiagnosticForSeverity {
      sev = vim.diagnostic.severity.HINT,
      icon = "H",
      hl = { ctermfg = 250, ctermbg = 24 },
    },
  },
}

return M
