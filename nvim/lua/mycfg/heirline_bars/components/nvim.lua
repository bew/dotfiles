local hline_conditions = require"heirline.conditions"

local _U = require"mycfg.heirline_bars.components.utils"
local _ = _U.SPACE

local M = {}

local mode_default_hl = { ctermfg = 255, cterm = { bold = true } }
local function tbl_merge(default, ...)
  return vim.tbl_extend("force", default, ...)
end

local ModeInnerText_only = {
  provider = function(self)
    -- MUST be under `Mode` to have the correct variable set!
    return _U.some_text_or(self.matching_mode_spec.text, "?!")
  end,
}

M.Mode = {
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
    local winnr = vim.fn.winnr()
    local after = ""
    -- local winid = vim.fn.win_getid(winnr) -- helps win DEBUG
    -- after = " (ID:"..winid..")" -- helps win DEBUG
    return winnr .. after
  end,
}

M.WinNr = {
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

M.ModeOrWinNr = {
  -- Only first child where `(not condition or condition()) == true` will render!
  fallthrough = false,
  {
    condition = hline_conditions.is_active,
    M.Mode,
  },
  M.WinNr,
}

-- few simple blocks (simple.. for now)
M.Changed = {
  provider = function()
    return vim.bo.modified and _U.unicode_or(" ", "[+]")
  end,
  hl = function()
    return { ctermfg = 208 }
  end,
  on_click = {
    name = "statusline_on_click_buffer_write",
    callback = _U.on_click_in_win_context(function()
      vim.cmd[[lockmarks write]]
    end),
  },
}

--- For use for buffers that are usually editable
M.MaybeReadOnly = {
  condition = function() return vim.bo.readonly end,

  provider = function()
    return _U.unicode_or(" ", "[RO]")
  end,
  hl = function()
    if hline_conditions.is_active() then
      return { ctermfg = 203 }
    else
      return { ctermfg = 160 }
    end
  end,
}

--- For use for buffers that are usually read-only, but may be editable
M.ReadOnlyMaybeEditable = {
  provider = function()
    if not vim.o.readonly and vim.o.modifiable then
      return "!editable!"
    else
      return _U.unicode_or(" ", "[RO]")
    end
  end,
  hl = function()
    if not vim.o.readonly or not vim.o.modifiable then
      return { ctermfg = 203, bold = true }
    else
      return { ctermfg = 160 }
    end
  end,
}

--- For use for buffers that are usually read-only, but may be editable on-demand with a click
M.ReadOnlyMaybeEditableWithToggle = {
  M.ReadOnlyMaybeEditable,
  on_click = {
    name = "statusline_on_click_toggle_editable",
    callback = _U.on_click_in_win_context(function()
      if vim.o.readonly then
        -- save options & make editable
        vim.b._was_readonly = vim.o.readonly
        vim.b._was_modifiable = vim.o.modifiable
        vim.o.readonly = false
        vim.o.modifiable = true
      else
        -- restore
        vim.o.readonly = vim.b._was_readonly
        vim.o.modifiable = vim.b._was_modifiable
      end
    end),
  },
}

local FileType_only = {
  provider = function()
    return vim.bo.filetype or "no ft"
  end,
}

M.FileType = {
  flexible = 50,
  {
    FileType_only,
    _
  },
  { provider = "" }, -- when limited space, fallback to nothing
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

M.RulerAndCursorPos = {
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

return M
