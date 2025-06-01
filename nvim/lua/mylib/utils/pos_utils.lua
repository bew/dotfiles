local U_mt = require"mylib.utils.mt_utils"
local U_fmt = require"mylib.utils.fmt_utils"
local _f = U_fmt.str_space_concat
local _q = U_fmt.str_simple_quote_surround

---@alias mylib.RangePos0 {start_pos: mylib.Pos0, end_pos: mylib.Pos0}

--- A (0, 0)-indexed normalized position, to simplify reasoning and comparisons
---@class mylib.Pos0
---@field row integer
---@field col integer
local Pos0 = U_mt.checked_table_index{}
Pos0.mt = {}
Pos0.mt.__index = Pos0

---@param self mylib.Pos0
---@param other mylib.Pos0
---@return boolean
function Pos0.mt:__eq(other)
  if not type(other) == "table" then
    return false
  end
  return self.row == other.row and self.col == other.col
end

--- Create a new Pos0
---@param pos0 {row: integer, col: integer}
---@return mylib.Pos0
function Pos0.new(pos0)
  return setmetatable(pos0, Pos0.mt)
end

---@alias mylib.Pos0FromVimposKind
--- | "pos" A vim position str (like "v", or "'k")
--- | "pos11" A vim position table (1,1)-indexed
--- | "cursor" The current cursor position

--- Create a new Pos0 from cursor position, given vim position str, or given position table.
--- Returns nil if the resulting position is invalid
---@param kind mylib.Pos0FromVimposKind Kind of vimpos, or how to interpret rest of args
---@param ... any See `kind`
---@return mylib.Pos0?
function Pos0.try_from_vimpos(kind, ...)
  local pos ---@type mylib.Pos0
  if kind == "cursor" then
    local cursor_pos10 = vim.api.nvim_win_get_cursor(#{...} == 0 and 0 or ...)
    pos = Pos0.new{ row = cursor_pos10[1] -1, col = cursor_pos10[2] }
  elseif kind == "pos" then
    ---       <bufnr>  <lnum1>   <col1>  <offset>
    ---@type [integer, integer, integer, integer]
    local posinfo = vim.fn.getpos(...)
    pos = Pos0.new{ row = posinfo[2] -1, col = posinfo[3] -1 }
  elseif kind == "pos11" then
    -- (1, 1)-indexed position (e.g. from vim fn like `searchpos`)
    ---@type [integer, integer]
    local pos11 = ...
    pos = Pos0.new{ row = pos11[1] -1, col = pos11[2] -1 }
  else
    error(_f("Pos0.try_from_vimpos: Unknown kind", _q(kind)))
  end
  if not pos:is_valid() then
    return nil
  end
  return pos
end

--- Same as `Pos0.try_from_vimpos`, but raises if pos obj couldn't be created (aka was invalid)
---@param kind mylib.Pos0FromVimposKind
---@return mylib.Pos0
function Pos0.from_vimpos(kind, ...)
  local maybe_pos = Pos0.try_from_vimpos(kind, ...)
  if not maybe_pos then
    error(_f("Pos0.from_vimpos: Got invalid pos for kind", _q(kind), "args:", ...))
  end
  return maybe_pos
end

--- Whether the position is valid (has positive numbers)
---@return boolean
function Pos0:is_valid()
  return self.row >= 0 and self.col >= 0
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

--- Returns a (1,0)-indexed position
---@return [integer, integer]
function Pos0:to_1_0_indexed()
  return {self.row +1, self.col}
end

--- Check whether position is within an inclusive range (start pos -> end pos)
---@param range mylib.RangePos0
---@return boolean
function Pos0:is_within_incl_range(range)
  local start_pos, end_pos = range.start_pos, range.end_pos
  -- Handle single-line matches
  if start_pos.row == end_pos.row then
    return (
      self.row == start_pos.row
      and start_pos.col <= self.col
      and self.col <= end_pos.col
    )
  end

  -- Handle multi-line matches
  return (
    (start_pos.row < self.row or (start_pos.row == self.row and start_pos.col <= self.col))
    and (self.row < end_pos.row or (self.row == end_pos.row and self.col <= end_pos.col))
  )
end

return {
  Pos0 = Pos0,
}
