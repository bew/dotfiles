-- Content overview: LSP document symbols, filtered to structural kinds and rendered with a
-- colored `[Kind]` prefix.

local M = {}

---@alias ContentOverview.Kind string One of `vim.lsp.protocol.SymbolKind`'s names.

---@class ContentOverview.Config
---@field kinds table<ContentOverview.Kind, boolean> Symbol kinds to keep in the overview.
---@field kind_highlights table<ContentOverview.Kind, string> Highlight group per kind (by name).
---@field filter fun(item: table, bufnr: integer): boolean Extra per-entry filter; false drops it.

-- Control-flow keywords that lua-language-server wrongly reports as `Package` symbols.
local LUA_KEYWORDS = {
  ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
  ["end"] = true, ["for"] = true, ["function"] = true, ["goto"] = true, ["if"] = true,
  ["in"] = true, ["local"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
  ["return"] = true, ["then"] = true, ["while"] = true,
}

---@type ContentOverview.Config
M.default_config = {
  -- Only structural kinds: skip leaf/literal symbols (String, Number, Boolean, Variable, …).
  kinds = {
    File          = true,
    Module        = true,
    Namespace     = true,
    Package       = true,
    Class         = true,
    Method        = true,
    Property      = true,
    Field         = true,
    Constructor   = true,
    Enum          = true,
    Interface     = true,
    Function      = true,
    Struct        = true,
    EnumMember    = true,
    TypeParameter = true,
  },
  -- Reuses standard highlight groups, so colors follow the active colorscheme.
  kind_highlights = {
    File          = "Directory",
    Module        = "Directory",
    Namespace     = "Directory",
    Package       = "Directory",
    Class         = "Type",
    Method        = "Function",
    Property      = "Identifier",
    Field         = "Identifier",
    Constructor   = "Function",
    Enum          = "Constant",
    Interface     = "Type",
    Function      = "Function",
    Struct        = "Structure",
    EnumMember    = "Constant",
    TypeParameter = "Type",
  },
  filter = function(item, bufnr)
    if item.kind ~= "Package" or vim.bo[bufnr].filetype ~= "lua" then
      return true
    end
    -- item.text is `[Kind] <name> …`; drop `Package` entries named after a keyword.
    local name = item.text and item.text:match("^%[[%w]+%]%s*(%S+)")
    return name == nil or not LUA_KEYWORDS[name]
  end,
}

local config = M.default_config

--- Open the filtered document-symbol list as a loclist, coloring each `[Kind]` prefix.
---@param list table List produced by the LSP document-symbol handler (title/items/context).
---@param bufnr integer Buffer the overview was requested for.
local function open_overview(list, bufnr)
  local items = {}
  for _, item in ipairs(list.items or {}) do
    if item.kind and config.kinds[item.kind] and config.filter(item, bufnr) then
      items[#items + 1] = item
    end
  end
  vim.fn.setloclist(0, {}, " ", { title = list.title, items = items, context = list.context })
  vim.cmd.lopen()
  -- Use window-local matches rather than extmarks: matches store a pattern, not positions, so
  -- they survive loclist rerenders (`:lolder`/`:lnewer`) without re-application. Extmarks would
  -- be dropped whenever Neovim replaces the rendered loclist lines.
  local winid = vim.api.nvim_get_current_win()
  local matched_kinds = {}
  for _, item in ipairs(items) do
    if not matched_kinds[item.kind] then
      matched_kinds[item.kind] = true
      local hl = config.kind_highlights[item.kind] or "Comment"
      vim.api.nvim_win_call(winid, function()
        vim.fn.matchadd(hl, "\\["..item.kind.."\\]", 10)
      end)
    end
  end
end

--- Show the content overview of the current buffer.
--- Prefers a buffer-local `gO` override when one exists (e.g. the Treesitter TOC in
--- markdown/help/man buffers); otherwise falls back to LSP document symbols.
--- Notifies when no overview is available for the buffer.
function M.show()
  -- Buffer-local `gO` overrides win over LSP document symbols.
  local gO_map = vim.fn.maparg("gO", "n", false, true)
  if type(gO_map) == "table" and gO_map.buffer == 1 then
    -- `mx!` = remap + run immediately, i.e. a synchronous feed of the override.
    vim.api.nvim_feedkeys(vim.keycode("gO"), "mx!", false)
    return
  end
  local clients = vim.lsp.get_clients({ bufnr = 0, method = "textDocument/documentSymbol" })
  if not next(clients) then
    vim.notify("!! Content overview NOT available for this file 👀 !!", vim.log.levels.ERROR)
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.buf.document_symbol {
    on_list = function(list) open_overview(list, bufnr) end,
  }
end

---@param given_cfg? ContentOverview.Config
function M.setup(given_cfg)
  config = vim.tbl_deep_extend("force", M.default_config, given_cfg or {})
end

return M
