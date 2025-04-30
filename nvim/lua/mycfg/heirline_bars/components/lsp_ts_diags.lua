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

---@param opts {hl: vim.api.keyset.highlight, sev: vim.diagnostic.Severity, icon: string}
local function single_diagnostic(opts)
  return {
    condition = function()
      local diags = vim.diagnostic.get(0, {severity = opts.sev})
      return #diags > 0
    end,
    _,
    {
      provider = function()
        local diags = vim.diagnostic.get(0, {severity = opts.sev})
        return opts.icon .. #diags
      end,
    },
    _,
    hl = function()
      opts.hl.bold = true
      return opts.hl
    end
  }
end

M.Diagnostics = {
  condition = function()
    local diags = vim.diagnostic.get(0, { severity = { "ERROR", "WARN", "HINT" } })
    return #diags > 0
  end,
  update = {
    "DiagnosticChanged",
    callback = function()
      -- Ensure the component is redrawn on update
      -- (otherwise it's only updated on cursor movement)
      vim.cmd.redrawstatus()
    end,
  },
  single_diagnostic {
    sev = "ERROR",
    icon = "E",
    hl = { ctermfg = 250, ctermbg = 124 },
  },
  single_diagnostic {
    sev = "WARN",
    icon = "W",
    hl = { ctermfg = 235, ctermbg = 214 },
  },
  single_diagnostic {
    sev = "HINT",
    icon = "H",
    hl = { ctermfg = 250, ctermbg = 24 },
  },
}

return M
