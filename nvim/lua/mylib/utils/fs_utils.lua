-------------------------------------------------------------
-- FS-related utils

local U_fs = {}

--- Returns whether the given path is a local directory
---@param path string
---@return boolean
function U_fs.path_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

-- NOTE: inspired from https://github.com/stevearc/quicker.nvim/blob/master/lua/quicker/fs.lua
---Check if OS path is absolute
---@param path string
---@return boolean
function U_fs.is_absolute(path)
  if path:match[[\]] then
    -- on windows
    return path:match[[^%a:\]]
  else
    return vim.startswith(path, "/")
  end
end

---@param path string
---@return string
function U_fs.make_path_absolute(path)
  return vim.fn.fnamemodify(path, ":p")
end

-- NOTE: inspired from https://github.com/stevearc/quicker.nvim/blob/master/lua/quicker/fs.lua
--- Simplify the given path relative to current or given dir
---@param path string
---@param relative_to? string Shorten relative to this path (default cwd)
---@return string
function U_fs.simplify_path(path, relative_to)
  if not relative_to then
    return vim.fn.fnamemodify(path, ":p:~:.")
  end
  -- FIXME: can we simplify this impl?
  local rel_path ---@type string?
  if U_fs.is_subpath(relative_to, path) then
    local idx = #relative_to + 1
    -- Trim the dividing slash if it's not included in relative_to
    if not vim.endswith(relative_to, "/") and not vim.endswith(relative_to, [[\]]) then
      idx = idx + 1
    end
    rel_path = path:sub(idx)
    if rel_path == "" then
      rel_path = "."
    end
  end
  local home_path = vim.fn.fnamemodify(path, ":p:~")
  if not rel_path or #home_path < #rel_path then
    -- Home path is shorter
    return home_path
  end
  return rel_path or path
end

-- NOTE: inspired from https://github.com/stevearc/quicker.nvim/blob/master/lua/quicker/fs.lua
--- Returns true if 'root <= candidate', meaning that the candidate is a subpath of root, or if they are the same path.
---@param root string
---@param candidate string
---@return boolean
function U_fs.is_subpath(root, candidate)
  if candidate == "" then
    return false
  end
  local root = vim.fs.normalize(U_fs.make_path_absolute(root))
  -- Trim trailing "/" from the root
  if root:find("/", -1) then
    root = root:sub(1, -2)
  end
  candidate = vim.fs.normalize(U_fs.make_path_absolute(candidate))
  if root == candidate then
    return true
  end
  local prefix = candidate:sub(1, #root)
  if prefix ~= root then
    return false
  end

  local candidate_starts_with_sep = candidate:find("/", #root + 1, true) == #root + 1
  local root_ends_with_sep = root:find("/", #root, true) == #root

  return candidate_starts_with_sep or root_ends_with_sep
end

return U_fs
