local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround
local KeyRefMustExist_mt = require"mylib.mt_utils".KeyRefMustExist_mt

-- Return a filter function that checks the given field is present
local function need_field(field_name)
  return function(p)
    return rawget(p, field_name) ~= nil
  end
end

local function boot_plugins(plugin_specs)
  -- TODO(?): would be nice to find the named plugin 'pkg_manager' and boot it first?
  -- and fallback to a manual boot if no pkg manager found.
  local can_boot_plugins = U.filter_list(plugin_specs, need_field"on_boot")
  local ctx = setmetatable({ all_plugin_specs = plugin_specs }, KeyRefMustExist_mt)
  for _, plug in pairs(can_boot_plugins) do
    local name = plug.source.name
    assert(type(plug.on_boot) == "function", _f("Field on_boot of plug spec", _q(name), "is not a function"))
    if plug.on_boot(ctx) == false then
      print("Plug", _q(name), "failed to boot, expect errors / lack of plugins / ..")
    end
  end

  -- Setup custom highlight autocommands
  local function apply_custom_highlights()
    local plugins_with_hl_updates = U.filter_list(plugin_specs, need_field"on_colorscheme_change")
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
