local U = require"mylib.utils"
local _f = U.str_space_concat


local hline_conditions = require"heirline.conditions"
local hline_utils = require"heirline.utils"
local _ = { provider = " " }
local __WideSpacing__ = { provider = "%=" }

local function is_and_has_text(value)
  return type(value) == "string" and value ~= ""
end

local function unicode_or(unicode_variant, ascii_variant)
  if not is_and_has_text(vim.env.ASCII_ONLY) then
    return unicode_variant
  else
    return ascii_variant
  end
end

local function some_text_or(maybe_txt, default)
  -- small helper to avoid checking nil or empty string
  if is_and_has_text(maybe_txt) then
    return maybe_txt
  else
    return default
  end
end

local function white_with_bg(spec)
  if hline_conditions.is_active() then
    return { ctermbg = spec.active_ctermbg, ctermfg = 255, cterm = {bold = true} }
  else
    return { ctermbg = spec.inactive_ctermbg, ctermfg = 252, cterm = {bold = true} }
  end
end

local mode_default_hl = { ctermfg = 255, cterm = { bold = true } }
local function tbl_merge(default, ...)
  return vim.tbl_extend("force", default, ...)
end
local ModeInnerText_only = {
  provider = function(self)
    -- MUST be under `Mode` to have the correct variable set!
    return some_text_or(self.matching_mode_spec.text, "?!")
  end,
}
local Mode = {
  static = {
    mode_palette = {
      normal = tbl_merge(mode_default_hl, { ctermbg = 27 }),
      insert = tbl_merge(mode_default_hl, { ctermbg = 28 }),
      replace = tbl_merge(mode_default_hl, { ctermbg = 88 }),
      visual = tbl_merge(mode_default_hl, { ctermbg = 97 }),
      select = tbl_merge(mode_default_hl, { ctermbg = 202 }),
      command = tbl_merge(mode_default_hl, { ctermbg = 0 }),
      terminal = tbl_merge(mode_default_hl, { ctermbg = 28 }), -- same as insert
      shell = tbl_merge(mode_default_hl, { ctermbg = 0 }),
      unknown = tbl_merge(mode_default_hl, { ctermbg = 220, ctermfg = 0 }),
    },
    mode_specs = {
      n = {style="normal", text="N"},
      i = {style="insert", text="I"},
      R = {style="replace", text="R"},
      v = {style="visual", text="V"}, V = {style="visual", text="VL"}, [""] = {style="visual", text="VB"},
      s = {style="select", text="S"}, S = {style="select", text="SL"}, [""] = {style="select", text="SB"},
      c = {style="command", text="C"},
      t = {style="terminal", text="T"},
      ["!"] = {style="shell", text=":!"}, -- shell cmd is executing (no idea how to see that...)
      ["?"] = {style="unknown", text="??"},
    },
  },
  -- NOTE: This function is called whenever a component is evaluated
  -- (right after condition but before hl and provider).
  init = function(self)
    local mode = hline_conditions.is_active() and vim.fn.mode() or "n"
    self.matching_mode_spec = self.mode_specs[mode] or {}
  end,
  {
    -- Flexible components, contract early but keep visible
    -- If the N-th child doesn't have enough space, N+1-th child is tried.
    flexible = 100,
    {
      _,
      ModeInnerText_only,
      _,
    },
    {
      ModeInnerText_only,
      _,
    },
    ModeInnerText_only, -- limited space fallback
  },
  hl = function(self)
    -- NOTE: hl _could_ be done in a wrapper widget
    if hline_conditions.is_active() then
      return self.mode_palette[self.matching_mode_spec.style] or self.mode_palette.unknown
    else
      return { ctermbg = 235, ctermfg = 242 }
    end
  end,
}

local WinNr_only = {
  -- mycfg-feature:direct-win-focus
  provider = function()
    return vim.fn.winnr()
  end,
}
local WinNr = {
  -- Flexible components, contract early but keep visible
  -- If the N-th child doesn't have enough space, N+1-th child is tried.
  -- Ref: https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#flexible-components
  flexible = 100,
  {
    _,
    WinNr_only,
    _,
  },
  {
    WinNr_only,
    _,
  },
  WinNr_only, -- limited space fallback

  hl = { ctermfg = 242, cterm = { bold=true } },
}
local ModeOrWinNr = {
  -- Only first child where `(not condition or condition()) == true` will render!
  fallthrough = false,
  {
    condition = hline_conditions.is_active,
    Mode,
  },
  WinNr,
}

local function transform_path_to_2_parts(buf_name)
  -- Transform to 2-parts file path: ~/foo or foo/bar
  local basename = vim.fn.fnamemodify(buf_name, ":t")
  local parent_path = vim.fn.fnamemodify(buf_name, ":h")
  if parent_path == vim.env.HOME then
    return "~/" .. basename
  elseif parent_path == vim.fn.getcwd() then
    return "./" .. basename
  else
    local parent_name = vim.fn.fnamemodify(buf_name, ":h:t")
    return parent_name .. "/" .. basename
  end
end

local FileOutOfCwd = {
  provider = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    if not vim.startswith(buf_name, vim.fn.getcwd()) then
      return unicode_or(" ", "[EXT]")
    end
  end,
}

local FilenameTwoParts = {
  -- IDEA: It is possible with heirline to dynamically generate blocks (see the 'Navic' example),
  --       do a similar thing to have the path separators highlighted ?
  --       (and maybe try to cache it as much as possible if performance is too bad?)
  provider = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(buf_name) == 1 then
      return transform_path_to_2_parts(buf_name)
    else
      return some_text_or(buf_name, "[No Name]")
    end
  end,
  hl = function()
    return vim.bo.modified and { cterm = { bold = true } }
  end,
}

-- few simple blocks (simple.. for now)
local Changed = {
  provider = function()
    return vim.bo.modified and unicode_or(" ", "[+]")
  end,
  hl = function()
    return { ctermfg = 208 }
  end,
  on_click = {
    callback = function()
      local winid = vim.fn.getmousepos().winid
      vim.api.nvim_win_call(winid, function()
        -- Run 'write' in the context of the clicked window
        vim.cmd[[lockmarks write]]
      end)
    end,
    -- Should be unique(?). Not 100% sure what it's used for, and how..
    name = "statusline_buffer_write_action",
  },
}
local ReadOnly = {
  condition = function() return vim.bo.readonly end,

  provider = function()
    return unicode_or(" ", "[RO]")
  end,
  hl = function()
    if hline_conditions.is_active() then
      return { ctermfg = 203 } -- red
    else
      return { ctermfg = 232 } -- black
    end
  end,
}
local FileType_only = {
  provider = function()
    return vim.bo.filetype or "no ft"
  end,
}
local FileType = {
  flexible = 50,
  {
    FileType_only,
    _
  },
  { provider = "" }, -- limited space fallback to nothing
}
local CursorPos_only = {
  provider = function()
    -- Use nvim_strwidth to determine the cursor column (unicode-aware) ?
    -- Try to play with these lines for example:
    -- ```
    -- |example normal text - example normal text - example normal text|
    -- |░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░|
    -- ```
    -- Cursor column differs when on first vs second line.

    -- NOTE: %c is the byte-column of the cursor
    -- IDEA: It would be nice to also have the unicode-aware column when different than %c,
    --   to see the 'character' column.
    if vim.tbl_contains({"", "NONE", "none"}, vim.o.virtualedit) then
      return "%l:%02c"
    else
      -- Add virtual column (when different than %c), aka the screen-wise position of the cursor
      -- Ref: https://stackoverflow.com/a/13544885
      -- NOTE: It is not _always_ enabled, because it would appear too often,
      --   e.g. when on a wrapped line with 'linebreak' set.
      --
      -- FIXME: column info can be wrong when line wraps
      return "%l:%02c%V"
    end
  end,
}
local Ruler_only = { provider = "%P" }
local RulerAndCursorPos = {
  {
    {
      flexible = 50,
      {
        _,
        Ruler_only,
      },
      -- TODO: tiny ruler in one char (no spacer around, w/ braille?)
      { provider = "" }, -- limited space fallback to nothing
    },
    _,
    {
      -- Only first child where `(not condition or condition()) == true` will render!
      fallthrough = false,
      {
        condition = hline_conditions.is_active,
        CursorPos_only,
      },
      { provider = "L%l" }, -- Defaults to only the line
    },
    _,
  },
  hl = function()
    if hline_conditions.is_active() then
      return { ctermfg = 235, ctermbg = 244 }
    else
      return { ctermfg = 233, ctermbg = 242 }
    end
  end
}

local BufBasename = {
  provider = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    return vim.fn.fnamemodify(buf_name, ":t") -- keep only base name
  end,
}


--------------------------------------------------------------------------------
-- Per-use statuslines
--------------------------------------------------------------------------------

local SpecialStatuslines = { for_plugin = {} }

local CmdwinType = {
  provider = function()
    return vim.fn.getcmdwintype()
  end,
  hl = { ctermfg = "red", cterm = { bold = true } },
}
local CmdwinTypeDescription = {
  provider = function()
    local cmdwin_type = vim.fn.getcmdwintype()
    if cmdwin_type == ":" then
      return "Command history"
    elseif cmdwin_type == ">" then
      return "Debug mode history"
    elseif cmdwin_type == "/" or cmdwin_type == "?" then
      return "Search history"
    elseif cmdwin_type == "@" then
      return "Input history"
    elseif cmdwin_type == "-" then
      return "Ex :insert :append history"
    elseif cmdwin_type == "=" then
      return "Expression history"
    end
  end,
}
-- Looks like this: `/ Search history /`
SpecialStatuslines.Cmdwin = {
  condition = function()
    -- NOTE: using `nvim_buf_get_name` gives the same BUT preceded by CWD.
    --   `expand` always gives only that name.
    --   Also, `expand` gives that name only for the statusline of cmdwin.
    return vim.fn.expand("%") == "[Command Line]"
  end,

  Mode,
  _,
  {
    CmdwinType,
    _, CmdwinTypeDescription, _,
    CmdwinType,
  },
  __WideSpacing__,
  RulerAndCursorPos,
}

SpecialStatuslines.QuickfixOrLoc = {
  condition = function()
    return hline_conditions.buffer_matches{ buftype = { "quickfix" } }
  end,

  Mode,
  _,
  {
    condition = function()
      local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
      return wininfo.quickfix == 1 and wininfo.loclist == 0
    end,

    {
      provider = "QUICKFIX LIST",
      hl = { cterm = { bold = true } },
    },
    _,
    { provider = "(global)" },
    __WideSpacing__,
    {
      provider = function()
        local current_entry_idx1 = vim.fn.getqflist{ idx = 0 }.idx
        local nb_entries = vim.fn.getqflist{ size = true }.size
        return _f("Entry", current_entry_idx1, "of", nb_entries)
      end,
    },
  },
  {
    condition = function()
      local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
      return wininfo.quickfix == 1 and wininfo.loclist == 1
    end,

    {
      provider = "LOCATION LIST",
      hl = { cterm = { bold = true } },
    },
    _,
    { provider = "(local)" },
    __WideSpacing__,
    {
      provider = function()
        local current_entry_idx1 = vim.fn.getloclist(0, { idx = 0 }).idx
        local nb_entries = vim.fn.getloclist(0, { size = true }).size
        return _f("Entry", current_entry_idx1, "of", nb_entries)
      end,
    },
  },
  __WideSpacing__,
  RulerAndCursorPos,
}

SpecialStatuslines.Help = {
  condition = function()
    return hline_conditions.buffer_matches{ buftype = { "help" } }
  end,

  ModeOrWinNr,
  {
    provider = " HELP ",
    hl = function()
      return white_with_bg{ active_ctermbg = 91, inactive_ctermbg = 54 }
    end,
  },
  _,
  BufBasename,
  -- TODO: insert local keybinding help! (note: generate it?)
  __WideSpacing__,
  RulerAndCursorPos,
}

SpecialStatuslines.Man = {
  condition = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    return vim.startswith(buf_name, "man://")
  end,

  ModeOrWinNr,
  {
    provider = " Man ",
    hl = function()
      return white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
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
  __WideSpacing__,
  RulerAndCursorPos,
}

SpecialStatuslines.SplashStartup = {
  condition = function()
    return hline_conditions.buffer_matches{ filetype = {"alpha"} }
  end,

  WinNr,
  __WideSpacing__,
  {
    provider = "          Do something cool !          ",
    hl = {
      ctermbg = 26,
      ctermfg = 254,
      cterm = { bold = true },
    },
  },
  __WideSpacing__,
}

SpecialStatuslines.for_plugin.Neotree = {
  condition = function()
    -- NOTE: this is a Lua pattern, need to escape the `-`!
    return hline_conditions.buffer_matches{ filetype = {"neo%-tree"} }
  end,

  {
    provider = " Ntree ",
    hl = function()
      return white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
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
  __WideSpacing__,
  RulerAndCursorPos,
}

SpecialStatuslines.for_plugin.XtermColorTable = {
  condition = function()
    return hline_conditions.buffer_matches{ bufname = {"__XtermColorTable__"} }
  end,

  WinNr,
  __WideSpacing__,
  {
    provider = " XTerm color table ",
    hl = function()
      return white_with_bg{ active_ctermbg = 130, inactive_ctermbg = 94 }
    end,
  },
  __WideSpacing__,
}

local GeneralPurposeStatusline = {
  ModeOrWinNr,
  { -- File info block
    _,
    { FileOutOfCwd, FilenameTwoParts },
    _,
    Changed,
    ReadOnly,
    hl = function()
      if hline_conditions.is_active() then
        return { ctermfg = 253, ctermbg = 240 }
      else
        return { ctermfg = 250, ctermbg = 238 }
      end
    end,
  },
  __WideSpacing__,
  FileType,
  RulerAndCursorPos,
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

  SpecialStatuslines.Cmdwin,
  SpecialStatuslines.QuickfixOrLoc,
  SpecialStatuslines.Help,
  SpecialStatuslines.Man,
  SpecialStatuslines.SplashStartup,
  SpecialStatuslines.for_plugin.XtermColorTable,
  SpecialStatuslines.for_plugin.Neotree,
  GeneralPurposeStatusline, -- last fallback
}

local function setup()
  -- FIXME: doesn't behave well when no space to show whole statuline..
  require"heirline".setup({
    statusline = Statuslines,
  })
  -- TODO: I want to setup the 'statusline' option myself, and only call heirline for initialization.
  -- This would allow to setup local statuslines in some file / for some window, without putting
  -- that config in the global statusline.
end

return {
  setup = setup,
}
