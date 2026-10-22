local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.ui, t.wm },
}

local A = require"mylib.action_system"
local K = require"mylib.keymap_system"

--------------------------------

Plug {
  source = gh"stevearc/resession.nvim",
  desc = "Session manager (resession-based, project-scoped)",
  tags = { t.wm, "session" },
  on_load = function()
    local resession = require"resession"

    -- --------------------------------------------------------
    -- Lazy resolution of the session directory
    -- --------------------------------------------------------

    -- Cached repo root: nil = not yet resolved, false = not in a repo.
    ---@type string|false|nil
    local _root = nil

    --- Returns the repo root (base repo, not worktree path), or nil.
    ---@return string|nil
    local function get_root()
      if _root == nil then
        local out = vim.trim(vim.fn.system("git rev-parse --show-toplevel"))
        _root = (vim.v.shell_error == 0 and out ~= "") and out or false
      end
      return _root ~= false and _root or nil
    end

    --- Returns the absolute path to the active session directory, or nil.
    ---@return string|nil
    local function active_dir()
      local root = get_root()
      return root and (root .. "/.nvim-sessions") or nil
    end

    --- Returns the absolute path to the archive directory, or nil.
    ---@return string|nil
    local function archive_dir()
      local root = get_root()
      return root and (root .. "/.nvim-sessions/archive") or nil
    end

    --- Write .gitignore into the session dir on first save.
    ---@param dir string
    local function ensure_gitignore(dir)
      local gi = dir .. "/.gitignore"
      if vim.fn.filereadable(gi) == 0 then
        local f = io.open(gi, "w")
        if f then
          f:write("# Session files managed by project-sessions (resession)\n*.json\n")
          f:close()
        end
      end
    end

    -- --------------------------------------------------------
    -- resession setup (minimal; dir is passed per-call)
    -- --------------------------------------------------------

    resession.setup({
      -- Disable default global dir; we always pass dir= per-call.
      -- autosave is intentionally off.
      autosave = { enabled = false },
    })

    -- --------------------------------------------------------
    -- Helpers
    -- --------------------------------------------------------

    --- Format seconds-since-epoch as relative time string.
    ---@param mtime number
    ---@return string
    local function relative_time(mtime)
      local diff = os.time() - mtime
      if diff < 60         then return "just now" end
      if diff < 3600       then return math.floor(diff / 60)          .. " minutes ago" end
      if diff < 86400      then return math.floor(diff / 3600)        .. " hours ago" end
      if diff < 86400 * 7  then return math.floor(diff / 86400)       .. " days ago" end
      if diff < 86400 * 30 then return math.floor(diff / (86400 * 7)) .. " weeks ago" end
      return math.floor(diff / (86400 * 30)) .. " months ago"
    end

    ---@class sess.Entry
    ---@field name string
    ---@field dir string
    ---@field mtime number
    ---@field archived boolean

    --- List resession sessions in a directory, sorted by mtime desc.
    ---@param dir string
    ---@param archived boolean
    ---@return sess.Entry[]
    local function list_in_dir(dir, archived)
      if vim.fn.isdirectory(dir) == 0 then return {} end
      -- resession.list() returns names only; we resolve paths ourselves for mtime.
      local names = resession.list({ dir = dir })
      local entries = {}
      for _, name in ipairs(names) do
        local path = dir .. "/" .. name .. ".json"
        local stat = vim.uv.fs_stat(path)
        table.insert(entries, {
          name     = name,
          dir      = dir,
          mtime    = stat and stat.mtime.sec or 0,
          archived = archived,
        })
      end
      table.sort(entries, function(a, b) return a.mtime > b.mtime end)
      return entries
    end

    -- --------------------------------------------------------
    -- Save
    -- --------------------------------------------------------

    --- Save a session. Prompts for a name if nil.
    ---@param name string|nil
    local function do_save(name)
      local dir = active_dir()
      if not dir then
        vim.notify("project-sessions: not in a git repo", vim.log.levels.WARN)
        return
      end

      local function save_with_name(session_name)
        vim.fn.mkdir(dir, "p")
        ensure_gitignore(dir)
        local ok, err = pcall(resession.save, session_name, { dir = dir, notify = false })
        if not ok then
          vim.notify("project-sessions: save failed\n" .. tostring(err), vim.log.levels.ERROR)
          return
        end
        vim.notify("project-sessions: saved '" .. session_name .. "'", vim.log.levels.INFO)
      end

      if name then
        save_with_name(name)
      else
        vim.ui.input({ prompt = "Session name: ", default = "" }, function(input)
          if not input or input == "" then return end
          save_with_name(input)
        end)
      end
    end

    -- --------------------------------------------------------
    -- Load
    -- --------------------------------------------------------

    --- Load a session by name. Uses pcall for safety.
    ---@param name string
    ---@param dir string
    local function do_load(name, dir)
      local ok, err = pcall(resession.load, name, { dir = dir, silence_errors = false })
      if not ok then
        vim.notify("project-sessions: load failed\n" .. tostring(err), vim.log.levels.ERROR)
      end
      -- resession notifies on success by default
    end

    -- --------------------------------------------------------
    -- Archive / delete
    -- --------------------------------------------------------

    --- Move an active session to the archive.
    ---@param name string
    local function do_archive(name)
      local adir = active_dir()
      local archdir = archive_dir()
      if not adir or not archdir then return end
      local src = adir .. "/" .. name .. ".json"
      if vim.fn.filereadable(src) == 0 then
        vim.notify("project-sessions: session '" .. name .. "' not found", vim.log.levels.ERROR)
        return
      end
      vim.fn.mkdir(archdir, "p")
      vim.fn.rename(src, archdir .. "/" .. name .. ".json")
      vim.notify("project-sessions: archived '" .. name .. "'", vim.log.levels.INFO)
    end

    --- Permanently delete an archived session.
    ---@param name string
    local function do_delete_archived(name)
      local archdir = archive_dir()
      if not archdir then return end
      local path = archdir .. "/" .. name .. ".json"
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
    local function do_rename(name, new_name, dir)
      local src = dir .. "/" .. name .. ".json"
      local dst = dir .. "/" .. new_name .. ".json"
      if vim.fn.filereadable(src) == 0 then
        vim.notify("project-sessions: session '" .. name .. "' not found", vim.log.levels.ERROR)
        return
      end
      if vim.fn.filereadable(dst) == 1 then
        vim.notify("project-sessions: '" .. new_name .. "' already exists", vim.log.levels.ERROR)
        return
      end
      vim.fn.rename(src, dst)
      vim.notify("project-sessions: renamed '" .. name .. "' -> '" .. new_name .. "'", vim.log.levels.INFO)
    end

    -- --------------------------------------------------------
    -- Telescope picker
    -- --------------------------------------------------------

    local function open_picker()
      local adir = active_dir()
      if not adir then
        vim.notify("project-sessions: not in a git repo", vim.log.levels.WARN)
        return
      end

      local pickers      = require"telescope.pickers"
      local finders      = require"telescope.finders"
      local conf         = require("telescope.config").values
      local actions      = require"telescope.actions"
      local action_state = require"telescope.actions.state"

      local function build_entries()
        local entries = {}
        for _, s in ipairs(list_in_dir(adir, false)) do
          table.insert(entries, {
            display  = string.format("%-30s %s", s.name, relative_time(s.mtime)),
            value    = s,
            ordinal  = s.name,
          })
        end
        local archived = list_in_dir(archive_dir() or "", true)
        if #archived > 0 then
          -- Non-selectable separator header
          table.insert(entries, {
            display = "── archived ──────────────────────────────",
            value   = nil,
            ordinal = "\xff",
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

      pickers.new({}, {
        prompt_title = "Sessions",
        finder = finders.new_table {
          results = build_entries(),
          entry_maker = function(e)
            return {
              display = e.display,
              value   = e.value,
              ordinal = e.ordinal,
              valid   = e.value ~= nil,
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
            do_load(sel.value.name, sel.value.dir)
          end)

          -- <C-s>: save/update (active only)
          map({"i","n"}, "<C-s>", function()
            local sel = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if not sel or not sel.value then return end
            if sel.value.archived then
              vim.notify("project-sessions: cannot overwrite archived session", vim.log.levels.WARN)
              return
            end
            do_save(sel.value.name)
          end)

          -- <C-r>: rename
          map({"i","n"}, "<C-r>", function()
            local sel = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if not sel or not sel.value then return end
            local old = sel.value.name
            vim.ui.input({ prompt = "Rename '" .. old .. "' to: ", default = old }, function(new_name)
              if not new_name or new_name == "" or new_name == old then return end
              do_rename(old, new_name, sel.value.dir)
            end)
          end)

          -- <C-x>: archive (active) | permanently delete (archived)
          map({"i","n"}, "<C-x>", function()
            local sel = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if not sel or not sel.value then return end
            if sel.value.archived then
              vim.ui.input(
                { prompt = "Delete '" .. sel.value.name .. "' permanently? [y/N] " },
                function(input)
                  if input and input:lower() == "y" then
                    do_delete_archived(sel.value.name)
                  end
                end
              )
            else
              do_archive(sel.value.name)
            end
          end)

          return true
        end,
      }):find()
    end

    -- --------------------------------------------------------
    -- Commands & keymaps
    -- --------------------------------------------------------

    vim.api.nvim_create_user_command("SessionSave", function()
      do_save(nil)
    end, { desc = "Save project session (prompt for name)" })

    vim.api.nvim_create_user_command("SessionPicker", function()
      open_picker()
    end, { desc = "Open project session picker" })

    vim.keymap.set("n", "<leader>ss", do_save,     { desc = "Session: save" })
    vim.keymap.set("n", "<leader>sp", open_picker, { desc = "Session: picker" })
  end,
}
