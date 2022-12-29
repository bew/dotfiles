


local hline_conditions = require"heirline.conditions"
local hline_utils = require"heirline.utils"
local _ = { provider = " " }
local __WideSpacing__ = { provider = "%=" }

local function some_text_or(maybe_txt, default)
  -- small helper to avoid checking nil or empty string
  if maybe_txt ~= nil and maybe_txt ~= "" then
    return maybe_txt
  else
    return default
  end
end

local mode_default_hl = { ctermfg = 255, cterm = { bold = true } }
local function tbl_merge(default, ...)
  return vim.tbl_extend("force", default, ...)
end
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
  provider = function(self)
    local mode_text = some_text_or(self.matching_mode_spec.text, "?!")
    return " " .. mode_text .. " "
  end,
  hl = function(self)
    -- NOTE: hl _could_ be done in a wrapper widget
    if hline_conditions.is_active() then
      return self.mode_palette[self.matching_mode_spec.style] or self.mode_palette.unknown
    else
      return { ctermbg = 235, ctermfg = 242 }
    end
  end,
}

local CmdwinType = {
  provider = function()
    return vim.fn.getcmdwintype()
  end,
  hl = { ctermfg = "red", cterm = { bold = true } },
}
-- Looks like this: `/ Search history /`
local CmdwinTypeDescription = {
  condition = function()
    -- NOTE: using `nvim_buf_get_name` gives the same BUT preceded by CWD
    --       `expand` always gives only that name.
    return vim.fn.expand("%") == "[Command Line]"
  end,
  CmdwinType,
  _,
  {
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
        return "Old Ex :insert :append history"
      elseif cmdwin_type == "=" then
        return "Expression history"
      end
    end,
  },
  _,
  CmdwinType,
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
  provider = function(self)
    local buf_name = vim.api.nvim_buf_get_name(0)
    if not vim.startswith(buf_name, vim.fn.getcwd()) then
      -- FIXME: use a unicode symbol instead?
      return "[EXT] "
    end
  end,
}

local FilenameTwoParts = {
  -- IDEA: It is possible with heirline to dynamically generate blocks (see the 'Navic' example),
  --       do a similar thing to have the path separators highlighted ?
  --       (and maybe try to cache it as much as possible if performance is too bad?)
  provider = function(self)
    local buf_name = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(buf_name) == 1 then
      return transform_path_to_2_parts(buf_name)
    else
      return some_text_or(buf_name, "[No Name]")
    end
  end,
}

local SpecialFileDescription = {
  -- NOTE: We need a condition function to be properly skipped when fallthrough is
  --       used on the block that calls us.
  -- See: https://github.com/rebelot/heirline.nvim/issues/54
  condition = function(self)
    for _, child in ipairs(self) do
      if not child.condition or child:condition() then
        return true
      end
    end
  end,

  { -- when in a help file
    condition = function()
      return vim.bo.filetype == "help" and not vim.bo.modifiable
    end,
    -- TODO: also replace/remove 'mode' block and say it's a help file?
    -- (or make a completely separate statusline for help windows?)
    provider = function()
      local buf_name = vim.api.nvim_buf_get_name(0)
      return vim.fn.fnamemodify(buf_name, ":t") -- keep only base name
    end,
  },
  CmdwinTypeDescription, -- when the commandline window is open
  { -- when on the startup screen
    condition = function()
      return hline_conditions.buffer_matches{filetype = {"alpha"}}
    end,
    -- TODO(?): make a separate statusline for the startup screen?
    provider = function()
      return "  Do something cool !  "
    end,
  },
  { -- when in a man page
    condition = function()
      local buf_name = vim.api.nvim_buf_get_name(0)
      return vim.startswith(buf_name, "man://")
    end,
    provider = function()
      local buf_name = vim.api.nvim_buf_get_name(0)
      return buf_name:gsub("man://", "Man: ")
    end,
  },
}

-- few simple blocks (simple.. for now)
local Changed = {
  provider = function()
    return vim.bo.modified and "[+]"
  end,
}
local ReadOnly = {
  provider = function(self)
    return vim.bo.readonly and "[RO]"
  end,
}
local FileType = {
  provider = function(self)
    return vim.bo.filetype or "no ft"
  end,
}
local Ruler = { provider = "%P %l:%02v" }

local statusline = {
  Mode,
  { -- File info block
    {
      _,
      {
        SpecialFileDescription,
        { FileOutOfCwd, FilenameTwoParts }, -- fallback to this if not a special file
      },
      _,
      hl = function()
        if not vim.bo.modifiable then
          return { cterm = { italic = true } }
        end
      end,
    },
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
  { -- to quickely differenciate the statuslines!
    __WideSpacing__,
    { provider = " [go Lua, go!!]" },
  },
  __WideSpacing__,
  FileType,
  _,
  {
    _, Ruler, _,
    hl = function()
      if hline_conditions.is_active() then
        return { ctermfg = 236, ctermbg = 244 }
      else
        return { ctermfg = 236, ctermbg = 242 }
      end
    end
  },
}

local function setup()
  -- FIXME: doesn't behave well when no space to show whole statuline..
  require"heirline".setup({
    hl = function()
      if hline_conditions.is_active() then
        return { ctermfg = 244, ctermbg = 236 }
      else
        return { ctermfg = 241, ctermbg = 235 }
      end
    end,
    statusline,
  })
  -- TODO: I want to setup the statusline option myself, and only call heirline for initialization.
end

return {
  setup = setup,
}
