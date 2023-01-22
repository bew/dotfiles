local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround

local function boot_plugins(given_plugin_specs)
  -- TODO(?): would be nice to find the named plugin 'pkg_manager' and boot it first?
  -- and fallback to a manual boot if no pkg manage found.

  local boot_plugins = U.filter_list(given_plugin_specs, function(p) return p.on_boot end)
  for _, plug in pairs(boot_plugins) do
    local name = plug.source.resolved_name
    assert(type(plug.on_boot) == "function", _f("Field on_boot of plug spec", _q(name), "is not a function"))
    if plug.on_boot() == false then
      print("Plug", _q(name), "failed to boot, expect errors / lack of plugins / ..")
    end
  end
end

return boot_plugins
