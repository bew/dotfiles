-- NOTE: this file is not under `tech_vim` because I want this to be available everywhere
-- (especially in vim & Lua files)

local _U = require"mycfg.hl_patterns.utils"
local hipatterns = require"mini.hipatterns"

---@type {[string]: mycfg.hl_patterns.PatternSpec}
local patterns = {}

-- e.g. #ffaa55
--      ^-- highlights the # here (needs 'termguicolors' enabled)
patterns.rgb_hex_colors = hipatterns.gen_highlighter.hex_color {
  style = "#", -- highlight the # sign
  filter = function(bufnr)
    local bufname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    return bufname ~= "__XtermColorTable__"
  end,
}

return patterns
