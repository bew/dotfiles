local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround

local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.get_plugin_declarator()
local gh = PluginSystem.sources.github
local dist_managed_opt_plug = PluginSystem.sources.dist_managed_opt_plug
local fallback = PluginSystem.sources.fallback

--------------------------------

-- NOTE: I don't want all the lazyness and perf stuff of 'lazy'
-- I want a simple plugin loader (using neovim packages), with nice recap UI,
-- interactive update system, with a lockfile (usable from Nix).
--
-- I want a way to ask what plugins has updates, see git log, and update plugins individually on
-- demand (or by tags inclusion/exclusion).
-- => It's actually already possible (except filtering on tags) with `Lazy check` then `Lazy logs`
--
-- TODO: Ask a way to disable the 'update' tab, which is potentially too dangerous,
-- I want to review plugins updates before I actually update them!
--
-- TODO: Make a dedicated way to register a package manager,
--   so we can enforce a set of fields / structure
Plug.pkg_manager {
  -- Default to Github source if local one cannot be found.
  source = fallback("lazy", dist_managed_opt_plug"lazy-nvim", gh"folke/lazy.nvim"),
  desc = "A modern plugin manager for Neovim",
  tags = {"boot"},
  install_path = function()
    -- note: called if pkg source has no (specified/existing) path
    return vim.fn.stdpath("state") .. "/pkg-manager--lazy"
  end,
  bootstrap_itself = function(self, ctx)
    local clone_cmd_parts = {
      "git",
      "clone",
      "--filter=blob:none", -- don't fetch blobs until git needs them
      self.source.url,
      ctx.manager_install_path,
    }
    local clone_cmd = table.concat(clone_cmd_parts, " ")
    print("Package manager not found! Install with:")
    print("  ", clone_cmd) -- note: on separate line for easy copy/paste
  end,
  on_boot = function(_self, ctx)
    if not U.is_module_available("lazy") then return false end
    local function enabled_plugins_filter(plug)
      if plug.on_boot then return false end -- not a regular plugin
      return plug.enabled ~= false
    end

    local lazy_plugin_specs = {}
    for _, plug in vim.iter(ctx.plugin_specs):filter(enabled_plugins_filter):enumerate() do
      local lazy_single_spec = {
        -- Set the plugin name, so we can easily reference other plugins by name
        -- (e.g. for plugin dependencies)
        name = plug.source.name,
      }
      if plug.source.type == "github" then
        lazy_single_spec[1] = plug.source.owner_repo
      elseif plug.source.type == "local_path" then
        lazy_single_spec.dir = plug.source.path
      else
        error(_f("Unknown declared plugin type", _q(plug.source.type)))
      end
      lazy_single_spec.init = plug.on_pre_load
      lazy_single_spec.config = plug.on_load
      if plug.version then
        if plug.version.branch then
          lazy_single_spec.branch = plug.version.branch
        end
        if plug.version.tag then
          lazy_single_spec.tag = plug.version.tag
        end
        if plug.version.rev then
          lazy_single_spec.rev = plug.version.rev
        end
      end
      if plug.depends_on then
        local direct_deps = {}
        for _, dep_plug in ipairs(plug.depends_on) do
          table.insert(direct_deps, dep_plug.source.name)
        end
        -- Important to ensure that deps are put in rtp before the plugin requiring them,
        -- can be necessary for vimscript plugins calling autoload functions from immediately
        -- executed plugin-script.
        lazy_single_spec.dependencies = direct_deps
        -- print("Plugin", _q(plug.source.name), "depends on:", vim.inspect(direct_deps)) -- DEBUG
      end
      if plug.defer_load then
        lazy_single_spec.lazy = plug.defer_load.autodetect -- bool
        lazy_single_spec.event = plug.defer_load.on_event
        lazy_single_spec.cmd = plug.defer_load.on_cmd
        lazy_single_spec.ft = plug.defer_load.on_ft
      end
      table.insert(lazy_plugin_specs, lazy_single_spec)
    end
    local plug_names = {}
    for _, plug in pairs(lazy_plugin_specs) do
      table.insert(plug_names, plug[1])
    end
    local xdg_config_dirs = vim.env.XDG_CONFIG_DIRS ~= nil and vim.split(vim.env.XDG_CONFIG_DIRS, ":") or {}
    local function try_find_lazy_lockfile()
      local candidates = U.concat_lists { {vim.fn.stdpath"config"}, xdg_config_dirs }
      for _, cfg_dir in ipairs(candidates) do
        local maybe_path = vim.fs.joinpath(cfg_dir, vim.env.NVIM_APPNAME or "nvim", "lazy-lock.json")
        if vim.fn.filereadable(maybe_path) == 1 then
          return maybe_path
        end
      end
      return nil
    end
    -- print("Loading lazy plugins:", vim.inspect(plug_names)) -- DEBUG
    ---@diagnostic disable-next-line: missing-fields (lazy config has all options as 'required'..)
    require("lazy").setup(lazy_plugin_specs, {
      root = ctx.install_dir,
      git = {
        -- In the Logs UI, show commits that are 'pending'
        -- (for plugins not yet updated to their latest fetched commit)
        -- => Will show nothing for plugins that are up-to-date, but I can always go
        --    where the plugin is (can copy path from plugin details) and `git log`!
        log = {"..origin/HEAD"}
      },
      -- open a pseudo terminal with git diff (for nice diffs with delta!)
      diff = { cmd = "terminal_git" },
      lockfile = try_find_lazy_lockfile(),
      -- Disable most automations
      install = { missing = false }, -- do not auto-install plugins
      custom_keys = false,
      change_detection = { enabled = false }, -- MAYBE: try it?
      performance = {
        cache = { enabled = true },
        reset_packpath = false,
        rtp = {
          reset = true, -- (this is the default, but it removes all $XDG_CONFIG_DIRS..)
          -- => We need to ADD `$XDG_CONFIG_DIRS[*]/$NVIM_APPNAME` paths that exists to ensure
          -- standalone Nix-managed config dir (passed in $XDG_CONFIG_DIRS) is available.
          -- => We also need to ADD `$XDG_CONFIG_DIRS[*]/$NVIM_APPNAME/after` paths (reverse order)
          -- to ensure 'after' scripts like ft-related configs are loaded.
          paths = U.concat_lists {
            U.filter_map_list(xdg_config_dirs, function(path)
              local cfg_path = vim.fs.joinpath(path, vim.env.NVIM_APPNAME or "nvim")
              if vim.fn.isdirectory(cfg_path) == 1 then
                -- print("config dir", vim.inspect(cfg_path))
                return cfg_path
              end
              return nil -- skip
            end),
            U.filter_map_list(vim.iter(xdg_config_dirs):rev():totable(), function(path)
              local cfg_after_path = vim.fs.joinpath(path, vim.env.NVIM_APPNAME or "nvim", "after")
              if vim.fn.isdirectory(cfg_after_path) == 1 then
                -- print("config dir (after)", vim.inspect(cfg_after_path))
                return cfg_after_path
              end
              return nil -- skip
            end),
          }
        },
      },
    })
  end,
}
