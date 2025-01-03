local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround
local KeyRefMustExist_mt = require"mylib.mt_utils".KeyRefMustExist_mt

local print_err = vim.api.nvim_err_writeln

-- Return a filter function that checks the given field is present
local function need_field(field_name)
  return function(p)
    return rawget(p, field_name) ~= nil
  end
end

--- Returns the first plugin spec with id `pkg_manager` or errors if there is none.
---@param plugin_specs plugin_system.PluginSpec[]
---@return plugin_system.PluginSpecPkgManager
local function find_pkg_manager(plugin_specs)
  for _, p in ipairs(plugin_specs) do
    if p.id == "pkg_manager" then
      ---@cast p plugin_system.PluginSpecPkgManager
      return p
    end
  end
  error("No package loader/installer/manager found!")
end

---@class plugin_system.BootPlugContext
---@field all_plugin_specs plugin_system.PluginSpec[]

---@param ctx plugin_system.BootPlugContext
local function boot_plugins(ctx)
  ctx = setmetatable(ctx, KeyRefMustExist_mt)

  if #ctx.all_plugin_specs == 0 then
    return -- nothing to do!
  end

  local pkg_manager = find_pkg_manager(ctx.all_plugin_specs)

  local check_path_exists = vim.uv.fs_stat
  if check_path_exists(pkg_manager.install_path) then
    vim.opt.rtp:prepend(pkg_manager.install_path)
  else
    pkg_manager:bootstrap_itself(ctx)
    if not check_path_exists(pkg_manager.install_path) then
      -- pkg manager still not bootstrapped, can't load plugins, bye
      -- (maybe a msg was printed to ask user to install it !shrug)
      return
    end
  end

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
    local plugins_with_hl_updates = U.filter_list(ctx.all_plugin_specs, need_field"on_colorscheme_change")
    for _, plug in pairs(plugins_with_hl_updates) do
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
  -- FIXME: is there a way if colorscheme was already set?
  apply_custom_highlights()
end

return boot_plugins
