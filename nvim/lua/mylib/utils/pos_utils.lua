local U_fmt = require"mylib.utils.fmt_utils"
local _f = U_fmt.str_space_concat
local _q = U_fmt.str_simple_quote_surround

---@class mylib.Pos0
---@field row integer
---@field col integer
local Pos0 = {}

--- Create a new Pos0
---@param pos0 {row: integer, col: integer}
---@return mylib.Pos0
function Pos0.new(pos0)
  return setmetatable(pos0, { __index = Pos0 })
end

--- Create a new Pos0 from cursor position or given vim position str (like "v" or "'k")
---@param kind "pos"|"cursor"
function Pos0.from_vimpos(kind, ...)
  if kind == "cursor" then
    local cursor_pos10 = vim.api.nvim_win_get_cursor(#{...} == 0 and 0 or ...)
    return Pos0.new{ row = cursor_pos10[1] -1, col = cursor_pos10[2] }
  elseif kind == "pos" then
    ---       <bufnr>  <lnum1>   <col1>  <offset>
    ---@type [integer, integer, integer, integer]
    local posinfo = vim.fn.getpos(...)
    return Pos0.new{ row = posinfo[2] -1, col = posinfo[3] -1 }
  end
  error(_f("Pos0.from_vimpos: Unknown kind", _q(kind)))
end

--- Create a new Pos0 with applied delta
---@param pos0_delta {row?: integer, col?: integer}
---@return mylib.Pos0
function Pos0:with_delta(pos0_delta)
  return Pos0.new({
    row = self.row + (pos0_delta.row or 0),
    col = self.col + (pos0_delta.col or 0),
  })
end

return {
  Pos0 = Pos0,
}
