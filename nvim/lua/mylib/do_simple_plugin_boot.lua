local U = require"mylib.utils"
local _f = U.fmt.str_space_concat
local _q = U.fmt.str_simple_quote_surround

local print_err = vim.api.nvim_err_writeln

-- Return a filter function that checks the given field is present
local function need_field(field_name)
  return function(p)
    return rawget(p, field_name) ~= nil
  end
end

--- Returns the first plugin spec with id `pkg_manager` or errors if there is none.
---@param plugin_specs plugsys.PluginSpec[]
---@return plugsys.PluginSpecPkgManager
local function find_pkg_manager(plugin_specs)
  for _, p in ipairs(plugin_specs) do
    if p.id == "pkg_manager" then
      return p --[[@as plugsys.PluginSpecPkgManager]]
    end
  end
  error("No package loader/installer/manager found!")
end

---@class plugsys.BootPlugContext
---@field plugin_specs plugsys.PluginSpec[] All plugin specs
---@field manager_install_path string Install path for the pkg manager

---@class plugsys.BootPlugOpts
---@field install_dir string Where plugins should be installed if they aren't

---@param plugin_specs plugsys.PluginSpec[] All plugin specs
---@param opts plugsys.BootPlugOpts
local function boot_plugins(plugin_specs, opts)
  if #plugin_specs == 0 then
    return -- nothing to do!
  end

  local pkg_manager = find_pkg_manager(plugin_specs)

  local pkg_manager_install_path ---@type string
  ---@diagnostic disable-next-line: undefined-field (We're only testing for a local_path source)
  if pkg_manager.source.type == "local_path" and U.fs.path_exists(pkg_manager.source.path) then
    ---@diagnostic disable-next-line: undefined-field
    pkg_manager_install_path = pkg_manager.source.path
  elseif type(pkg_manager.install_path) == "function" then
    pkg_manager_install_path = pkg_manager:install_path()
  elseif type(pkg_manager.install_path) == "string" then
    pkg_manager_install_path = pkg_manager.install_path --[[@as string]]
  else
    vim.notify("Package manager is missing its 'install_path'", vim.log.levels.ERROR)
  end

  ---@type plugsys.BootPlugContext
  local ctx = U.mt.checked_table_index {
    plugin_specs = plugin_specs,
    install_dir = opts.install_dir,
    manager_install_path = pkg_manager_install_path,
  }

  if not U.fs.path_exists(pkg_manager_install_path) then
    vim.notify("Pkg manager not installed at " .. _q(pkg_manager_install_path) .. ", attempting bootstrap…")
    pkg_manager:bootstrap_itself(ctx)
    if not U.fs.path_exists(pkg_manager_install_path) then
      vim.notify("Pkg manager still not installed, cannot boot plugins", vim.log.levels.ERROR)
      -- (maybe a msg was printed to ask user to install it 🤷)
      return
    end
  end
  vim.opt.rtp:prepend(pkg_manager_install_path)

  local pkg_manager_name = pkg_manager.source.name
  assert(
    type(pkg_manager.on_boot) == "function",
    _f("Field on_boot of pkg_manager plug spec", _q(pkg_manager_name), "is not a function")
  )
  local success, error_msg = pcall(pkg_manager.on_boot, pkg_manager, ctx)
  if not success or error_msg then
    print_err(_f("Package manager", _q(pkg_manager_name), "failed to boot, expect errors / lack of plugins / .."))
    print_err(_f("Reason:", error_msg))
    return
  end

  -- Setup custom highlight autocommands
  local function apply_custom_highlights()
    local plugins_with_hl_updates = vim.iter(ctx.plugin_specs):filter(need_field"on_colorscheme_change")
    for _, plug in plugins_with_hl_updates:enumerate() do
      plug.on_colorscheme_change()
    end
  end
  -- NOTE: this group should probably by global, usable by plugin's 'on_load'&co as well?
  -- NOTE: this group can be problematic if this function to boot plugins is called multiple times
  --   with different specs of plugins: the augroup used in previous call will be cleared..
  local augroup_id = vim.api.nvim_create_augroup("custom_highlights_augroup", { clear = true })
  vim.api.nvim_create_autocmd({"ColorScheme"}, {
    group = augroup_id,
    callback = apply_custom_highlights,
  })
  -- call once on boot (as new colorsheme might already be applied!)
  apply_custom_highlights()
end

return boot_plugins
