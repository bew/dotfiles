-- NOTE: this file is not under `tech_vim` because I want this to be available everywhere
-- (especially in vim & Lua files)

local _U = require"mycfg.hl_patterns.utils"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
local patterns = {}

patterns.cterm_color = {
  -- note: Matches:
  -- - `ctermfg=42`
  -- - `ctermfg = 42`
  pattern = {
    "ctermfg=%d+",
    "ctermfg = %d+",
    "ctermbg=%d+",
    "ctermbg = %d+",
  },
  group = "", -- no highlight, only extmark
  extmark_opts = function(_, match)
    local color = match:match "%d+$" -- find color ID at the end
    local hl_group = _U.define_hl("term"..color, {
      ctermfg = tonumber(color),
    })
    return {
      hl_mode = "combine", -- combine with bg color
      virt_text = { { "⬤ ", hl_group } },
      virt_text_pos = "eol",
    }
  end,
}

patterns.underline_color = {
  pattern = {
    -- e.g. guisp=#02a724 (in a `hi FooGroup …` statement)
    "guisp=()#%x%x%x%x%x%x()%f[%X]",
    -- e.g. sp = "#008080" (in a `vim.api.nvim_set_hl(…)` call)
    [[sp = "()#%x%x%x%x%x%x()%f[%X]"]],
  },
  group = function(_, match)
    local hex = match:lower():sub(2)
    return _U.define_hl("underline_rgb_"..hex, {
      sp = "#"..hex,
      underline = true,
    })
  end,
}

return patterns
