local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround

local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.PlugDeclarator

-- Define custom plugin source for my local plugins
---@param name string Name of my local plugin (found in $NVIM_BEW_MYPLUGINS_PATH)
---@return PlugSourceLocal
PluginSystem.sources.myplug = function(name)
  local myplugins_path = vim.env.NVIM_BEW_MYPLUGINS_PATH
  assert((
    myplugins_path or vim.fn.filereadable(myplugins_path) == 1
  ), "$NVIM_BEW_MYPLUGINS_PATH is not set or doesn't exist!!")
  return PluginSystem.sources.local_path {
    name = name,
    path = vim.fs.normalize(myplugins_path .. "/" .. name)
  }
end

---@diagnostic disable: missing-fields
-- Having different type for table & `__newindex` isn't supported nor easy to.. skip diags for this..
--   REF: https://github.com/LuaLS/lua-language-server/issues/3020
PluginSystem.tags.careful_update = { desc = "Plugins I want to update carefully" }
PluginSystem.tags.vimscript = { desc = "Plugins in vimscript" }
PluginSystem.tags.ui = { desc = "Plugins for the global UI" }
PluginSystem.tags.content_ui = { desc = "Plugins for content UI" }
PluginSystem.tags.editing = { desc = "Plugins about code/content editing" }
PluginSystem.tags.insert = { desc = "Plugins adding stuff in insert mode" }
PluginSystem.tags.ts = { desc = "Plugins made to use Treesitter information" }
PluginSystem.tags.git = { desc = "Plugins around git VCS" }
PluginSystem.tags.textobj = { desc = "Plugins to add textobjects" }
PluginSystem.tags.ft_support = { desc = "Plugins to support specific filetype(s)" }
PluginSystem.tags.lib_only = { desc = "Plugins that are only useful to other plugins" }
PluginSystem.tags.need_better_plugin = { desc = "Plugins that are 'meh', need to find a better one" }
---@diagnostic enable: missing-fields

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local myplug = PluginSystem.sources.myplug

-- --------------------------------

Plug {
  enabled = false, -- NOTE(DEBUG): Enable when exploring/debugging stuff
  source = myplug"debug-autocmds.nvim",
  desc = "Tool to debug/understand autocmd flow while using neovim",
  tags = {"utils", "debug"},
  on_load = function()
    require("debug-autocmds").setup{
      global_tracking_on_start = true, -- switch to `true` to debug builtin events from start :)
    }
    -- NOTE: Nice 'oneliner' to get some info about buffer/window/tab events
    -- require"debug-autocmds".get"global":dump_matching_with("buf,win,tab", function(ev) print(("%-15s"):format(ev.name), vim.fs.basename(ev.raw.file), "   tab:", ev.extra.tabnr, "   win:", ev.extra.winid) end)
    -- require"debug-autocmds".get"global":dump_matching_with("user", function(ev) print(("%-8s"):format(ev.name), ("%-15s"):format(ev.raw.file), "   data:", vim.inspect(ev.raw.data, { newline = "" })) end)
  end,
}

Plug {
  source = myplug"smart-bol.nvim",
  desc = "Provide action to cycle movements ^ and 0 with a single key",
  tags = {"movement", t.insert},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    -- I: Move cursor to begin/end of line
    -- NOTE: BREAKS UNDO
    --   I couldn't make the smart-bol plugin work in insert mode in a 'repeat'-able way nor without
    --   breaking undo...
    --   (moving to end could, but having begin/end have different behavior is a no-no)
    --
    -- NOTE: Direct mapping of <M-^> might need special terminal config to work instantly...
    -- otherwise dead key might be triggered (like `^e` to make `ê`).
    -- (wezterm implemented this after my issue: https://github.com/wez/wezterm/issues/877)
    -- vim.cmd[[inoremap <M-^> <C-g>U<Home>]] -- BUT: <Home> moves like 0 not like ^
    local smart_bol_act = require"smart-bol.actions"
    toplevel_map{mode={"n", "i"}, key=[[<M-^>]],  desc="smart bol", action=smart_bol_act.do_smart_bol}
    toplevel_map{mode={"n", "i"}, key=[[<Home>]], desc="smart bol", action=smart_bol_act.do_smart_bol}
    toplevel_map{mode={"n", "i"}, key=[[<M-$>]],  desc="eol", action=[[<End>]]}
  end,
}

Plug {
  source = myplug"tab-zoom-win.nvim",
  desc = "Toggle zoom in tab page",
  tags = {"wm"},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    my_actions.tab_toggle_win_zoom = mk_action_v2 {
      default_desc = "Tab: Toggle window zoom",
      n = require"tab-zoom-win".toggle_zoom
    }

    toplevel_map{mode="n", key="+", action=my_actions.tab_toggle_win_zoom}

    -- Default <C-w>o is dangerous for the layout, make it zoom instead
    toplevel_map{mode="n", key=[[<C-w>o]], action=my_actions.tab_toggle_win_zoom}
    -- Still allow the 'dangerous' operation with `<C-w>O` (maj o)
    toplevel_map{mode="n", key=[[<C-w>O]], action=[[<C-w>o]]}
  end,
}

Plug {
  source = gh"ii14/neorepl.nvim",
  desc = "Neovim REPL for lua and vim script",
  tags = {"config"},
  defer_load = { on_event = "VeryLazy" },
  -- NOTE: use `/h` to get help inside the repl buffer
  on_load = function()
    -- NOTE: need my PR (#21) to merge config with plugin's default config
    require"neorepl".config {
      startinsert = false, -- Don't start REPL in insert mode
      indent = 4, -- Indent outputs
      on_init = function(_bufnr)
        -- Plugin comes with its own completion, so other auto-completion plugins must be disabled
        require"cmp".setup.buffer({ enabled = false })

        -- Map plugin's completion to usual completion key (Which is <Tab> here by default :/)
        toplevel_buf_map{mode="i", key="<C-n>", opts={expr=true}, action=function()
          return vim.fn.pumvisible() == 1 and "<C-n>" or "<Plug>(neorepl-complete)"
        end}

        -- navigate in history
        toplevel_buf_map{mode="i", key="<M-j>", action="<Plug>(neorepl-hist-next)"}
        toplevel_buf_map{mode="i", key="<M-k>", action="<Plug>(neorepl-hist-prev)"}
        toplevel_buf_map{mode="i", key="<Down>", action="<Plug>(neorepl-hist-next)"}
        toplevel_buf_map{mode="i", key="<Up>", action="<Plug>(neorepl-hist-prev)"}
        -- toplevel_buf_map{mode="i", key="<M-k>", opts={expr=true}, action=function()
        --   -- FIXME: if cursor is at top line of editable region
        --   return "<Plug>(neorepl-hist-prev)"
        --   -- FIXME: else
        --   return "<Up>"
        -- end}
        -- toplevel_buf_map{mode="i", key="<M-j>", opts={expr=true}, action=function()
        --   -- FIXME: if cursor is at bottom line of editable region
        --   return "<Plug>(neorepl-hist-next)"
        --   -- FIXME: else
        --   return "<Down>"
        -- end}

        -- N: navigate from section to sections
        toplevel_buf_map{mode="n", key="<M-j>", action="<Plug>(neorepl-]])"}
        toplevel_buf_map{mode="n", key="<M-k>", action="<Plug>(neorepl-[[)"}

        -- N,I: Eval line(s)
        toplevel_buf_map{mode={"n", "i"}, key="<CR>", action="<Plug>(neorepl-eval-line)"}
        toplevel_buf_map{mode="i", key="<C-j>", action="<Plug>(neorepl-eval-line)"}

        -- N,I: multiline editing
        toplevel_buf_map{mode="i", key="<M-CR>", action="<Plug>(neorepl-break-line)"}
        toplevel_buf_map{mode="i", key="<M-o>", action="<End><Plug>(neorepl-break-line)"}
        toplevel_buf_map{mode="n", key="o", action="A<Plug>(neorepl-break-line)"}
        -- FIXME: Fix detection of start of line, going to BOL of non-first line of editable area should put cursor after initial `\`
        -- toplevel_buf_map{mode="i", key="<M-O>", action="<Home><Plug>(neorepl-break-line)<Up>"}
        -- toplevel_buf_map{mode="n", key="O", action="I<Plug>(neorepl-break-line)<Up>"}

        -- I: Ctrl-d exits
        toplevel_buf_map{mode="i", key="<C-d>", action=function()
          if vim.api.nvim_get_current_line() == "" then
            vim.cmd.quit()
          else
            vim.notify("Cannot quit repl, line is not empty!", vim.log.levels.ERROR)
          end
        end}
      end,
    }

    my_actions.neovim_lua_repl = mk_action_v2 {
      default_desc = "Neovim Lua Repl buffer",
      n = "<cmd>Repl lua<cr>",
    }
    my_actions.neovim_vim_repl = mk_action_v2 {
      default_desc = "Neovim VimScript Repl buffer",
      n = "<cmd>Repl vim<cr>",
    }
  end,
}

Plug.lib_plenary {
  source = gh"nvim-lua/plenary.nvim",
  desc = "Lua contrib stdlib for plugins, used by many plugins",
  tags = {t.lib_only},
  defer_load = { autodetect = true },
}

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
  source = gh"folke/lazy.nvim",
  desc = "A modern plugin manager for Neovim",
  tags = {"boot"},
  install_path = vim.fn.stdpath("data") .. "/pkg-manager--lazy",
  bootstrap_itself = function(self, _ctx)
    local clone_cmd_parts = {
      "git",
      "clone",
      "--filter=blob:none", -- don't fetch blobs until git needs them
      self.source.url,
      self.install_path,
    }
    local clone_cmd = table.concat(clone_cmd_parts, " ")
    print("Package manager not found! Install with:")
    print(clone_cmd) -- note: on separate line for easy copy/paste
  end,
  on_boot = function(_self, ctx)
    if not U.is_module_available("lazy") then return false end
    local function enabled_plugins_filter(plug)
      if plug.on_boot then return false end -- not a regular plugin
      return plug.enabled ~= false
    end

    local lazy_plugin_specs = {}
    for _, plug in pairs(U.filter_list(ctx.all_plugin_specs, enabled_plugins_filter)) do
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

--------------------------------

require"mycfg.plugs_for_ui"
require"mycfg.plugs_for_ft"
require"mycfg.plugs_for_git"
require"mycfg.plugs_for_file_editing"
require"mycfg.plugs_for_treesitter"
require"mycfg.plugs_for_ai_llm"

PluginSystem.check_missing_plugins()
return PluginSystem.all_plugin_specs()
