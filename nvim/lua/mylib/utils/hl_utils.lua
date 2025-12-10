----------------------------------------------------------+
--    IDEA: Move out of utils, into a `hl_system` ?     --|
-- ---------------------------------------------------- --|
--    /!\ TODO: Write unit tests for all of this /!\    --|
----------------------------------------------------------+

--- This function converts the output type of nvim_get_hl into a compatible input type for
--- nvim_set_hl.
---
--- note: I'm very surprised that these outputs/input types are _not_ compatible by default...
---
---@param hl_info vim.api.keyset.get_hl_info
---@return vim.api.keyset.highlight
local function _get_hl_to_api_highlight(hl_info)
  hl_info.cterm = hl_info.cterm or {}
  -- note: Some fields are omitted, like `altfont`, `special` (dup of `sp`)
  --   I don't think they are necessary.
  ---@type vim.api.keyset.highlight
  return {
    -- style-related
    bold = hl_info.bold or hl_info.cterm.bold,
    strikethrough = hl_info.strikethrough or hl_info.cterm.strikethrough,
    italic = hl_info.italic or hl_info.cterm.italic,
    reverse = hl_info.reverse or hl_info.cterm.reverse,
    nocombine = hl_info.nocombine or hl_info.cterm.nocombine,

    -- terminal-related
    ctermfg = hl_info.ctermfg or hl_info.cterm.ctermfg,
    ctermbg = hl_info.ctermbg or hl_info.cterm.ctermbg,

    -- GUI colors
    blend = hl_info.blend,
    fg = hl_info.fg,
    bg = hl_info.bg,

    -- underline-related
    sp = hl_info.sp, --(?) diff with `special` ?
    underline = hl_info.underline or hl_info.cterm.underline,
    undercurl = hl_info.undercurl or hl_info.cterm.undercurl,
    underdouble = hl_info.underdouble or hl_info.cterm.underdouble,
    underdotted = hl_info.underdotted or hl_info.cterm.underdotted,
    underdashed = hl_info.underdashed or hl_info.cterm.underdashed,

    -- extra
    default = hl_info.default,
    link = hl_info.link,
    global_link = nil, --(?)
  }
end

local M = {}

---@class mylib.hl.HlGroup: vim.api.keyset.highlight
---  note: this base class is the most complete type with hl fields at toplevel (easiest to use)
---  (FUTURE) This class will contain hl manipulation/transformation functions!
M.HlGroup = { _type = "HlGroup" }
M.HlGroup.mt = { __index = M.HlGroup }

---@class mylib.hl.HlGroupNamed: mylib.hl.HlGroup
---@field name string The group name
M.HlGroupNamed = setmetatable({ _type = "HlGroupNamed" }, { __index = M.HlGroup })
M.HlGroupNamed.mt = { __index = M.HlGroupNamed }

--- Get a HlGroup instance, by name or from a raw hlspec.
---
--- If a name is present in group_spec, a HlGroupNamed instance will be returned.
---
---@param group_spec string|vim.api.keyset.highlight|mylib.hl.HlGroup|mylib.hl.HlGroupNamed HL group
---  name or highlight spec.
---@return mylib.hl.HlGroup|mylib.hl.HlGroupNamed
---
---@overload fun(group_spec: vim.api.keyset.highlight|mylib.hl.HlGroup): mylib.hl.HlGroup
---@overload fun(group_spec: string): mylib.hl.HlGroupNamed
---@overload fun(group_spec: mylib.hl.HlGroupNamed): mylib.hl.HlGroupNamed
function M.group(group_spec)
  local name ---@type string?
  local group ---@type vim.api.keyset.highlight
  if type(group_spec) == "string" then
    -- Find an existing group by name
    name = group_spec
    local get_hl_group_info = vim.api.nvim_get_hl(0, { name = group_spec })
    group = _get_hl_to_api_highlight(get_hl_group_info)
  else
    name = rawget(group_spec, "name")
    group = group_spec
  end
  -- note: Here we upcast the vim.api.keyset.highlight to a HlGroup (compatible!)
  ---@cast group mylib.hl.HlGroup

  if name then
    ---@cast group +mylib.hl.HlGroupNamed
    group.name = name
    return setmetatable(group, M.HlGroupNamed.mt)
  else
    return setmetatable(group, M.HlGroup.mt)
  end
end

--- Set HlGroup with an existing group or a name & a hl spec.
---
---@param group_name string
---@param hlspec vim.api.keyset.highlight|mylib.hl.HlGroup
function M.set(group_name, hlspec)
  if rawget(hlspec, "name") ~= group_name then
    -- note: nvim_set_hl _really_ doesn't like when we set "Foo" with another name in hlspec
    --   (this can happen when we use a group hlspec to set another group)
    --   So we make sure we get a fresh copy, un-named.
    hlspec = vim.deepcopy(hlspec)
    ---@diagnostic disable-next-line: inject-field
    hlspec.name = nil
  end
  -- print("setting hl", group_name, "to", vim.inspect(hlspec)) -- DEBUG
  vim.api.nvim_set_hl(0, group_name, hlspec)
  return M.group(group_name)
end

--- Apply the group
function M.HlGroupNamed:apply()
  M.set(self.name, self)
end

--- Get a fresh copy of the HlGroup
---@return mylib.hl.HlGroup
function M.HlGroup:fresh_copy()
  return M.group(vim.deepcopy(self))
end

--- Get a fresh copy of the HlGroup
--- note: the new group won't be named, to be usable anywhere
---@return mylib.hl.HlGroup
function M.HlGroupNamed:fresh_copy()
  local copy = vim.deepcopy(self)
  copy.name = nil -- strip the name, we don't know how this group is going to be used!
  return M.group(copy)
end

--- Returns a new HlGroup with the given hlspec applied on top of self
---@param hlspec vim.api.keyset.highlight
---@return mylib.hl.HlGroup|mylib.hl.HlGroupNamed
function M.HlGroup:with(hlspec)
  ---@type vim.api.keyset.highlight
  local hlspec = vim.tbl_extend("force", self, hlspec)
  return M.group(hlspec)
end

return M
