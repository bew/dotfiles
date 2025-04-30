local _U = require"mycfg.heirline_bars.components.utils"

local M = {}

---@param buf_name string
---@return string
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

-- IDEA: Add a similar component for files that are not readable, but have their buffer editable/modifiable/...
-- (waiting to be written)
M.FileOutOfCwd = {
  provider = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    if not vim.startswith(buf_name, vim.fn.getcwd()) then
      return _U.unicode_or(" ", "[EXT]")
    end
  end,
}

M.FilenameTwoParts = {
  -- IDEA: It is possible with heirline to dynamically generate blocks (see the 'Navic' example),
  --       do a similar thing to have the path separators highlighted ?
  --       (and maybe try to cache it as much as possible if performance is too bad?)
  provider = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    if vim.fn.filereadable(buf_name) == 1 then
      return transform_path_to_2_parts(buf_name)
    else
      -- IDEA: Add a case when the buf_name is in pwd (color? front unicode char?),
      -- to not just have a big bufname just because it's not saved on disk yet.
      return _U.some_text_or(buf_name, "[No Name]")
    end
  end,
  hl = function()
    return vim.bo.modified and { cterm = { bold = true } }
  end,
}

M.BufBasename = {
  provider = function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    return vim.fn.fnamemodify(buf_name, ":t") -- keep only base name
  end,
}

return M
