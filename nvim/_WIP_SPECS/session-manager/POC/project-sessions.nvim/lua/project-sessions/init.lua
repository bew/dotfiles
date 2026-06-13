--- project-sessions.nvim
--- Session manager scoped to a git repo root.
--- Sessions live in <repo-root>/.nvim-sessions/
--- Archived sessions live in <repo-root>/.nvim-sessions/archive/

local M = {}

-- ============================================================
-- State
-- ============================================================

---@class projsess.Config
---@field session_dir fun(): string|nil
---@field keys { save: string|false, picker: string|false }
---@field hooks { before_save?: fun(name:string):boolean|nil, after_save?: fun(name:string), before_load?: fun(name:string):boolean|nil, after_load?: fun(name:string) }

---@type projsess.Config
local cfg = {
  session_dir = function()
    local root = vim.trim(vim.fn.system("git rev-parse --show-toplevel"))
    if vim.v.shell_error ~= 0 then return nil end
    return root
  end,
  keys = {
    save   = "<leader>ss",
    picker = "<leader>sp",
  },
  hooks = {},
}

-- Cached result of cfg.session_dir(); false = resolved but nil (not in a repo)
---@type string|false|nil
local _resolved_root = nil

-- ============================================================
-- Internal helpers
-- ============================================================

--- Resolve and cache the repo root. Returns nil if not in a repo.
---@return string|nil
local function get_root()
  if _resolved_root == nil then
    _resolved_root = cfg.session_dir() or false
  end
  if _resolved_root == false then return nil end
  return _resolved_root
end

---@return string|nil
local function active_dir_path()
  local root = get_root()
  if not root then return nil end
  return root .. "/.nvim-sessions"
end

---@return string|nil
local function archive_dir_path()
  local root = get_root()
  if not root then return nil end
  return root .. "/.nvim-sessions/archive"
end

--- Ensure a directory exists; create it (and parents) if not.
---@param dir string
local function ensure_dir(dir)
  vim.fn.mkdir(dir, "p")
end

--- Write a .gitignore into the session dir on first save.
---@param dir string
local function ensure_gitignore(dir)
  local gi = dir .. "/.gitignore"
  if vim.fn.filereadable(gi) == 0 then
    local f = io.open(gi, "w")
    if f then
      f:write("# Session files managed by project-sessions.nvim\n*.vim\n")
      f:close()
    end
  end
end

--- Return mtime of a file (0 if not readable).
---@param path string
---@return number
local function file_mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and stat.mtime.sec or 0
end

---@class projsess.Session
---@field name string
---@field path string
---@field mtime number
---@field archived boolean

--- List session files in a directory, sorted by mtime descending.
---@param dir string
---@param archived boolean
---@return projsess.Session[]
local function list_in_dir(dir, archived)
  local results = {}
  if vim.fn.isdirectory(dir) == 0 then return results end
  local files = vim.fn.glob(dir .. "/*.vim", false, true)
  for _, path in ipairs(files) do
    local name = vim.fn.fnamemodify(path, ":t:r") -- basename without .vim
    table.insert(results, {
      name     = name,
      path     = path,
      mtime    = file_mtime(path),
      archived = archived,
    })
  end
  table.sort(results, function(a, b) return a.mtime > b.mtime end)
  return results
end

--- Format seconds-ago as a human relative string.
---@param mtime number
---@return string
local function relative_time(mtime)
  local diff = os.time() - mtime
  if diff < 60 then return "just now" end
  if diff < 3600 then return math.floor(diff / 60) .. " minutes ago" end
  if diff < 86400 then return math.floor(diff / 3600) .. " hours ago" end
  if diff < 86400 * 7 then return math.floor(diff / 86400) .. " days ago" end
  if diff < 86400 * 30 then return math.floor(diff / (86400 * 7)) .. " weeks ago" end
  return math.floor(diff / (86400 * 30)) .. " months ago"
end

--- Run a hook. Returns false if the hook explicitly returns false (abort).
---@param name string
---@param session_name string
---@return boolean ok
local function run_hook(name, session_name)
  local fn = cfg.hooks[name]
  if fn then
    local result = fn(session_name)
    if result == false then return false end
  end
  return true
end

-- ============================================================
-- Public API
-- ============================================================

--- Save the current session.
--- If name is nil, prompts the user (interactive use).
---@param name string|nil
---@param opts? { force?: boolean }
function M.save(name, opts)
  opts = opts or {}
  local adir = active_dir_path()
  if not adir then
    vim.notify("project-sessions: not in a supported project", vim.log.levels.WARN)
    return
  end

  local function do_save(session_name)
    if not opts.force then
      if not run_hook("before_save", session_name) then return end
    end
    ensure_dir(adir)
    ensure_gitignore(adir)
    local path = adir .. "/" .. session_name .. ".vim"
    vim.cmd("mksession! " .. vim.fn.fnameescape(path))
    run_hook("after_save", session_name)
    vim.notify("project-sessions: saved '" .. session_name .. "'", vim.log.levels.INFO)
  end

  if name then
    do_save(name)
  else
    vim.ui.input({ prompt = "Session name: ", default = "" }, function(input)
      if not input or input == "" then return end
      do_save(input)
    end)
  end
end

--- Load a session by name. Wrapped in pcall.
---@param name string
---@param opts? { archived?: boolean }
function M.load(name, opts)
  opts = opts or {}
  local dir = opts.archived and archive_dir_path() or active_dir_path()
  if not dir then
    vim.notify("project-sessions: not in a supported project", vim.log.levels.WARN)
    return
  end

  if not run_hook("before_load", name) then return end

  local path = dir .. "/" .. name .. ".vim"
  if vim.fn.filereadable(path) == 0 then
    vim.notify("project-sessions: session '" .. name .. "' not found", vim.log.levels.ERROR)
    return
  end

  local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(path))
  if not ok then
    vim.notify("project-sessions: load failed\n" .. tostring(err), vim.log.levels.ERROR)
    return
  end

  run_hook("after_load", name)
  vim.notify("project-sessions: loaded '" .. name .. "'", vim.log.levels.INFO)
end

--- Move an active session to the archive.
---@param name string
function M.archive(name)
  local adir = active_dir_path()
  local archdir = archive_dir_path()
  if not adir or not archdir then return end

  local src = adir .. "/" .. name .. ".vim"
  local dst = archdir .. "/" .. name .. ".vim"
  if vim.fn.filereadable(src) == 0 then
    vim.notify("project-sessions: session '" .. name .. "' not found", vim.log.levels.ERROR)
    return
  end
  ensure_dir(archdir)
  vim.fn.rename(src, dst)
  vim.notify("project-sessions: archived '" .. name .. "'", vim.log.levels.INFO)
end

--- Permanently delete a session from the archive.
---@param name string
function M.delete_archived(name)
  local archdir = archive_dir_path()
  if not archdir then return end

  local path = archdir .. "/" .. name .. ".vim"
  if vim.fn.filereadable(path) == 0 then
    vim.notify("project-sessions: archived session '" .. name .. "' not found", vim.log.levels.ERROR)
    return
  end
  vim.fn.delete(path)
  vim.notify("project-sessions: deleted '" .. name .. "'", vim.log.levels.INFO)
end

--- Rename an active session.
---@param name string
---@param new_name string
function M.rename(name, new_name)
  local adir = active_dir_path()
  if not adir then return end

  local src = adir .. "/" .. name .. ".vim"
  local dst = adir .. "/" .. new_name .. ".vim"
  if vim.fn.filereadable(src) == 0 then
    vim.notify("project-sessions: session '" .. name .. "' not found", vim.log.levels.ERROR)
    return
  end
  if vim.fn.filereadable(dst) == 1 then
    vim.notify("project-sessions: session '" .. new_name .. "' already exists", vim.log.levels.ERROR)
    return
  end
  vim.fn.rename(src, dst)
  vim.notify("project-sessions: renamed '" .. name .. "' -> '" .. new_name .. "'", vim.log.levels.INFO)
end

--- List active sessions sorted by mtime desc.
---@return projsess.Session[]
function M.list()
  local adir = active_dir_path()
  if not adir then return {} end
  return list_in_dir(adir, false)
end

--- List archived sessions sorted by mtime desc.
---@return projsess.Session[]
function M.list_archived()
  local archdir = archive_dir_path()
  if not archdir then return {} end
  return list_in_dir(archdir, true)
end

--- Return the Active Session Directory path (nil if not in a repo).
---@return string|nil
function M.active_dir()
  return active_dir_path()
end

-- ============================================================
-- Telescope picker
-- ============================================================

function M.picker()
  local adir = active_dir_path()
  if not adir then
    vim.notify("project-sessions: not in a supported project", vim.log.levels.WARN)
    return
  end

  local ok_tele, telescope = pcall(require, "telescope")
  if not ok_tele then
    vim.notify("project-sessions: telescope.nvim is required for the picker", vim.log.levels.ERROR)
    return
  end

  local pickers    = require("telescope.pickers")
  local finders    = require("telescope.finders")
  local conf       = require("telescope.config").values
  local actions    = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local function build_entries()
    local entries = {}
    for _, s in ipairs(M.list()) do
      table.insert(entries, {
        display  = string.format("%-30s %s", s.name, relative_time(s.mtime)),
        value    = s,
        ordinal  = s.name,
      })
    end
    -- Section separator
    local archived = M.list_archived()
    if #archived > 0 then
      table.insert(entries, {
        display  = "── archived ──────────────────────────────",
        value    = nil, -- not selectable as a real session
        ordinal  = "\xff", -- sorts after all real names
      })
      for _, s in ipairs(archived) do
        table.insert(entries, {
          display  = string.format("  %-28s %s", s.name, relative_time(s.mtime)),
          value    = s,
          ordinal  = "\xff" .. s.name,
        })
      end
    end
    return entries
  end

  local picker_keys = cfg.keys or {}

  pickers.new({}, {
    prompt_title = "Sessions",
    finder = finders.new_table {
      results = build_entries(),
      entry_maker = function(e)
        return {
          display  = e.display,
          value    = e.value,
          ordinal  = e.ordinal,
          valid    = e.value ~= nil, -- separator line is not selectable
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- <CR>: load
      actions.select_default:replace(function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not sel or not sel.value then return end
        M.load(sel.value.name, { archived = sel.value.archived })
      end)

      -- <C-s>: save & update (active only)
      map({"i","n"}, "<C-s>", function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not sel or not sel.value then return end
        if sel.value.archived then
          vim.notify("project-sessions: cannot overwrite archived session", vim.log.levels.WARN)
          return
        end
        M.save(sel.value.name, { force = false })
      end)

      -- <C-r>: rename
      map({"i","n"}, "<C-r>", function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not sel or not sel.value then return end
        local old = sel.value.name
        vim.ui.input({ prompt = "Rename '" .. old .. "' to: ", default = old }, function(new_name)
          if not new_name or new_name == "" or new_name == old then return end
          if sel.value.archived then
            -- rename inside archive
            local archdir = archive_dir_path()
            if not archdir then return end
            vim.fn.rename(archdir .. "/" .. old .. ".vim", archdir .. "/" .. new_name .. ".vim")
            vim.notify("project-sessions: renamed '" .. old .. "' -> '" .. new_name .. "'", vim.log.levels.INFO)
          else
            M.rename(old, new_name)
          end
        end)
      end)

      -- <C-x>: archive (active) or permanently delete (archived)
      map({"i","n"}, "<C-x>", function()
        local sel = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not sel or not sel.value then return end
        if sel.value.archived then
          vim.ui.input(
            { prompt = "Delete '" .. sel.value.name .. "' permanently? [y/N] " },
            function(input)
              if input and input:lower() == "y" then
                M.delete_archived(sel.value.name)
              end
            end
          )
        else
          M.archive(sel.value.name)
        end
      end)

      return true
    end,
  }):find()
end

-- ============================================================
-- Setup
-- ============================================================

---@param opts? projsess.Config
function M.setup(opts)
  cfg = vim.tbl_deep_extend("force", cfg, opts or {})

  -- Register user commands
  vim.api.nvim_create_user_command("SessionSave", function()
    M.save(nil)
  end, { desc = "Save project session (prompt for name)" })

  vim.api.nvim_create_user_command("SessionPicker", function()
    M.picker()
  end, { desc = "Open project session picker" })

  -- Keymaps
  local k = cfg.keys
  if k.save then
    vim.keymap.set("n", k.save, M.save, { desc = "Session: save" })
  end
  if k.picker then
    vim.keymap.set("n", k.picker, M.picker, { desc = "Session: picker" })
  end
end

return M
