local hline_conditions = require"heirline.conditions"
local external_components = require"heirline-components.all".component

local libU = require"mylib.utils"
local _f = libU.str_space_concat

local my = require"mycfg.heirline_components"
local U = my.U
local _ = U.SPACE
local __WIDE_SPACE__ = U.__WIDE_SPACE__

--------------------------------------------------------------------------------
-- Per-use statuslines
--------------------------------------------------------------------------------

local SpecialBufStatuslines = {}
local PluginStatuslines = {}

-- Looks like this: `/ Search history /`
SpecialBufStatuslines.Cmdwin = {
  condition = function()
    -- NOTE: using `nvim_buf_get_name` gives the same BUT preceded by CWD.
    --   `expand` always gives only that name.
    --   Also, `expand` gives that name only for the statusline of cmdwin.
    return vim.fn.expand("%") == "[Command Line]"
  end,

  my.nvim.Mode,
  _,
  {
    my.nvim.CmdwinType,
    _, my.nvim.CmdwinTypeDescription, _,
    my.nvim.CmdwinType,
  },
  __WIDE_SPACE__,
  my.nvim.RulerAndCursorPos,
}

---@class myst.ListlineInfo
---@field get_list_info (fun(what: any): any)
---@field condition (fun(wininfo: any): boolean)
---@field name string
---@field scope string

local LIST = {
  ---@type myst.ListlineInfo
  qflist = {
    get_list_info = vim.fn.getqflist,
    condition = function(wininfo)
      return wininfo.quickfix == 1 and wininfo.loclist == 0
    end,
    name = "QUICKFIX LIST",
    scope = "global",
  },
  ---@type myst.ListlineInfo
  loclist = {
    get_list_info = function(what)
      return vim.fn.getloclist(0, what)
    end,
    condition = function(wininfo)
      return wininfo.quickfix == 1 and wininfo.loclist == 1
    end,
    name = "LOCATION LIST",
    scope = "local",
  },
}
---@param list myst.ListlineInfo
local function make_list_line(list)
  return {
    condition = function()
      local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
      return list.condition(wininfo)
    end,

    {
      provider = list.name,
      hl = { cterm = { bold = true } },
    },
    _,
    { provider = "(" .. list.scope .. ")" },
    __WIDE_SPACE__,
    {
      provider = function()
        local current_entry_idx1 = list.get_list_info{ idx = 0 }.idx
        local nb_entries = list.get_list_info{ size = true }.size
        return _f("Entry", current_entry_idx1, "of", nb_entries)
      end,
    },
    __WIDE_SPACE__,
    {
      provider = function()
        local list_nr = list.get_list_info{ nr = 0 }.nr
        local nb_lists = list.get_list_info{ nr = "$" }.nr
        return libU.str_concat("List n°", list_nr, "/", nb_lists)
      end
    },
    _,
  }
end
SpecialBufStatuslines.QuickfixOrLoc = {
  condition = function()
    return hline_conditions.buffer_matches{ buftype = { "quickfix" } }
  end,

  my.nvim.Mode,
  _,
  make_list_line(LIST.qflist),
  make_list_line(LIST.loclist),
  my.nvim.RulerAndCursorPos,
}

SpecialBufStatuslines.Help = {
  condition = function()
    return hline_conditions.buffer_matches{ buftype = { "help" } }
  end,

  my.nvim.ModeOrWinNr,
  {
    provider = " HELP ",
    hl = function()
      return U.white_with_bg{ active_ctermbg = 91, inactive_ctermbg = 54 }
    end,
  },
  _,
  my.fs.BufBasename,
  -- TODO: insert local keybinding help! (note: generate it?)
  __WIDE_SPACE__,
  my.nvim.RulerAndCursorPos,
}

SpecialBufStatuslines.Man = {
  condition = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    return vim.startswith(buf_name, "man://")
  end,

  my.nvim.ModeOrWinNr,
  {
    provider = " Man ",
    hl = function()
      return U.white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
    end,
  },
  {
    _,
    {
      provider = function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        return buf_name:gsub("man://", "")
      end,
    },
    _,

    -- NOTE: This is the same hl fn as for general purpose's file info component
    hl = function()
      if hline_conditions.is_active() then
        return { ctermfg = 253, ctermbg = 240 }
      else
        return { ctermfg = 250, ctermbg = 238 }
      end
    end,
  },
  __WIDE_SPACE__,
  my.nvim.RulerAndCursorPos,
}

PluginStatuslines.SplashStartup = {
  condition = function()
    return hline_conditions.buffer_matches{ filetype = {"alpha"} }
  end,

  my.nvim.WinNr,
  __WIDE_SPACE__,
  {
    provider = "          Do something cool !          ",
    hl = {
      ctermbg = 26,
      ctermfg = 254,
      cterm = { bold = true },
    },
  },
  __WIDE_SPACE__,
}

PluginStatuslines.Neotree = {
  condition = function()
    -- NOTE: this is a Lua pattern, need to escape the `-`!
    return hline_conditions.buffer_matches{ filetype = {"neo%-tree"} }
  end,

  {
    provider = " Ntree ",
    hl = function()
      return U.white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
    end,
  },
  {
    _,
    {
      provider = function()
        local buf_name = vim.api.nvim_buf_get_name(0)
        buf_name = vim.fn.fnamemodify(buf_name, ":t") -- remove cwd
        -- buf_name looks like `neo-tree TheSourceName`
        return buf_name:gsub("^neo%-tree ", "")
      end,
    },
    _,

    -- NOTE: This is the same hl fn as for general purpose's file info component
    hl = function()
      if hline_conditions.is_active() then
        return { ctermfg = 253, ctermbg = 240 }
      else
        return { ctermfg = 250, ctermbg = 238 }
      end
    end,
  },
  __WIDE_SPACE__,
  my.nvim.RulerAndCursorPos,
}

PluginStatuslines.XtermColorTable = {
  condition = function()
    return hline_conditions.buffer_matches{ bufname = {"__XtermColorTable__"} }
  end,

  my.nvim.WinNr,
  __WIDE_SPACE__,
  {
    provider = " XTerm color table ",
    hl = function()
      return U.white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
    end,
  },
  __WIDE_SPACE__,
}

PluginStatuslines.CodeCompanionAI = {
  condition = function()
    return hline_conditions.buffer_matches{ filetype = {"codecompanion"} }
  end,

  my.nvim.ModeOrWinNr,
  {
    provider = " CodeCompanion Chat ",
    hl = function()
      return U.white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
    end,
  },
  _,
  {
    provider = function()
      local chat = require"codecompanion".buf_get_chat(0)
      local current_adapter = chat.adapter.name
      -- note: `adapter.schema` is the set of parameters for this adapter, and `model` is a standard
      --   parameter across all adapters in the plugin.
      --   `default`
      local current_model = chat.adapter.schema.model.default
      return require"mylib.utils".str_concat(current_adapter, " (", current_model, ")")
    end,
    on_click = {
      name = "heirline_codecompanion_adapter_on_click",
      callback = function()
        local chat = require"codecompanion".buf_get_chat(0)
        require"codecompanion.strategies.chat.keymaps".change_adapter.callback(chat)
      end,
    },
  },

  __WIDE_SPACE__,
  {
    provider = function()
      local chat = require"codecompanion".buf_get_chat(0)
      return "Prompt n°".. chat.cycle
    end
  },
  _,
  my.nvim.RulerAndCursorPos,
}

local GeneralPurposeStatusline = {
  my.nvim.ModeOrWinNr,
  { -- File info block
    _,
    { my.fs.FileOutOfCwd, my.fs.FilenameTwoParts },
    _,
    my.nvim.Changed,
    my.nvim.ReadOnly,
    hl = function()
      if hline_conditions.is_active() then
        return { ctermfg = 253, ctermbg = 240 }
      else
        return { ctermfg = 250, ctermbg = 238 }
      end
    end,
  },
  external_components.diagnostics(),
  __WIDE_SPACE__,
  external_components.lsp({ lsp_client_names = false }), -- LSP progress messages
  {
    condition = my.lsp_ts_diags.LspActive.condition,
    my.lsp_ts_diags.LspActive,
    _,
  },
  {
    condition = my.lsp_ts_diags.TreesitterStatus.condition,
    my.lsp_ts_diags.TreesitterStatus,
    _,
  },
  my.nvim.FileType,
  my.nvim.RulerAndCursorPos,
}

local Statuslines = {
  hl = function()
    if hline_conditions.is_active() then
      return { ctermfg = 246, ctermbg = 236 }
    else
      return { ctermfg = 242, ctermbg = 235 }
    end
  end,

  -- Only first child where `(not condition or condition()) == true` will render!
  fallthrough = false,

  SpecialBufStatuslines.Cmdwin,
  SpecialBufStatuslines.QuickfixOrLoc,
  SpecialBufStatuslines.Help,
  SpecialBufStatuslines.Man,
  PluginStatuslines.SplashStartup,
  PluginStatuslines.XtermColorTable,
  PluginStatuslines.Neotree,
  PluginStatuslines.CodeCompanionAI,
  GeneralPurposeStatusline, -- last fallback
}

local function get_heirline_setup_opts()
  -- FIXME: doesn't behave well when no space to show whole statuline..
  return {
    statusline = Statuslines,
  }
  -- TODO: I would like to setup the 'statusline' option myself, and only call heirline for
  -- initialization. This would allow to setup local statuslines in some file / for some window,
  -- without putting that config in the global statusline.
end

return {
  get_heirline_setup_opts = get_heirline_setup_opts,
}
