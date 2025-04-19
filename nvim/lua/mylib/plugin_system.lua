-- THE IDEA:
-- ```
-- local Plug = ...
-- local NamedPlug = ...
--
-- NamedPlug.foobar {
--   ...
--   config_depends_on = {
--     -- anonymous plugin that depends on foobar
--     Plug { ..., depends_on = {NamedPlug.foobar} }
--   },
-- }
-- ```
-- note: 'NamedPlug' is a automagic proxy / setter for a named plugin spec
-- The tricky part is that the `NamedPlug.foobar` in `config_depends_on` is called _before_ the
-- plugin is defined.
-- So `NamedPlug.foobar` must declare the named plugin on first reference, and always refer to the
-- same object before and after it is defined.

---@class plugin_system.DeclaredPluginSpec
---@field id string The plugin ID
---@field __is_placeholder_plugin_spec boolean?

---@class plugin_system.PluginSpec: plugin_system.DeclaredPluginSpec
---@field enabled boolean Whether the plugin should be loaded by the pkg manager
---@field source PlugSourceBase? Spec about the plugin's source location
---@field INVALID_SOURCE boolean? True if the source is not valid (when it's set to nil)
---@field desc string Rough single-line description
---@field tags string[]
---@field version plugin_system.PluginVersionSpec
---@field depends_on plugin_system.PluginSpec[]
---@field config_depends_on plugin_system.PluginSpec[]
---@field on_pre_load fun() Hook run before plugin is loaded
---@field on_load fun() Hook run just after plugin is loaded
---@field on_colorscheme_change fun() Hook run when colorscheme changes (used to re-define hl groups)

---@class plugin_system.PluginSpecPkgManager: plugin_system.PluginSpec
---@field install_path string Where the pkg manager is installed
---@field bootstrap_itself? fun(self, ctx: plugin_system.BootPlugContext)
---@field on_boot fun(self, ctx: plugin_system.BootPlugContext)

---@class plugin_system.PluginVersionSpec
---@field tag? string
---@field branch? string

local U = require"mylib.utils"
local _f = U.str_space_concat
local _q = U.str_simple_quote_surround
local _s = U.str_surround

local KeyRefMustExist_mt = require"mylib.mt_utils".KeyRefMustExist_mt

local STATE = {
  -- test
  --- Contains anonymous plugin specs
  ---@type plugin_system.PluginSpec[]
  _anon_plugin_specs = {},
  --- Contains named plugin specs
  ---@type {[string]: plugin_system.PluginSpec}
  _named_plugin_specs = {},
}

local M = {}

function M.all_plugin_specs()
  local all_specs = {}
  vim.list_extend(all_specs, STATE._anon_plugin_specs)
  vim.list_extend(all_specs, vim.tbl_values(STATE._named_plugin_specs))
  return all_specs
end

local DeclaratorImpl = {}

---@param spec plugin_system.PluginSpec
function DeclaratorImpl.check_plugin_declaration(spec)
  -- TODO: validate spec is fully respected!
  if not spec.source then
    -- source isn't valid, disable the plugin
    spec.enabled = false
    spec.INVALID_SOURCE = true
  end
end

function DeclaratorImpl.register_anon_plugin(plugin_spec)
  vim.validate{ plugin_spec={plugin_spec, "table"} }
  DeclaratorImpl.check_plugin_declaration(plugin_spec)
  table.insert(STATE._anon_plugin_specs, plugin_spec)
  return plugin_spec
end

---Declares a named plugin
---@param plugin_id string The plugin ID to declare
---@return plugin_system.DeclaredPluginSpec
function DeclaratorImpl.declare_named_plugin(plugin_id)
  if STATE._named_plugin_specs[plugin_id] then
    return STATE._named_plugin_specs[plugin_id]
  end
  local placeholder_plugin_spec = {
    id = plugin_id,
    __is_placeholder_plugin_spec = true, -- will be set to nil when plugin gets defined!
  }
  -- Save named spec, so later references return this spec!
  STATE._named_plugin_specs[plugin_id] = placeholder_plugin_spec
  return placeholder_plugin_spec
end

local CallToRegisterPlugin_mt = {
  ---@param self plugin_system.DeclaredPluginSpec
  ---@param spec_fields plugin_system.PluginSpec
  __call = function(self, spec_fields)
    if not self.__is_placeholder_plugin_spec then
      error(_f("Not a placeholder: Cannot register the named plugin spec", _q(self.id), "twice"))
    end
    self.__is_placeholder_plugin_spec = nil
    -- copy all spec fields to the existing/stored spec
    for k, v in pairs(spec_fields) do self[k] = v end
    ---@diagnostic disable-next-line: param-type-mismatch (self is augmented now)
    DeclaratorImpl.check_plugin_declaration(self)
  end,
}

---@class plugin_system.DeclaratorDefaults
---@field default_tags? (string|plugin_system.PlugTagSpec)[]

-- The magic table metadata that makes the following syntax possible:
-- ```
-- Plug { spec for anonymous plugin }
--
-- -- With forward plugin declaratioin: (Plug.bar isn't defined yet)
-- Plug.foo { depends_on = { Plug.bar }, ... spec for plugin named 'foo' }
--
-- -- Now define Plug.bar, and use on-the-fly plugin spec for a config dependency
-- Plug.bar { config_depends_on = { Plug { on-the-fly spec } }, ... spec for plugin named 'bar' }
-- -- This saves the spec into original table, so earlier/later references can access everything
-- ```
---@param defaults? plugin_system.DeclaratorDefaults
function DeclaratorImpl.get_plugin_declarator(defaults)
  ---@type plugin_system.DeclaratorDefaults
  local plugin_defaults = vim.tbl_extend("keep", defaults or {}, {
    default_tags = {}
  })
  return setmetatable({ _IS_PLUGIN_DECLARATOR = true }, {
    ---@param plugin_spec plugin_system.PluginSpec
    ---@return plugin_system.PluginSpec
    __call = function(_, plugin_spec)
      ---@diagnostic disable-next-line: undefined-field (Want to ensure weird case doesn't happen)
      if plugin_spec._IS_PLUGIN_DECLARATOR then
        error("!! Decl is passed to itself??")
      end
      plugin_spec.tags = vim.list_extend(plugin_spec.tags or {}, plugin_defaults.default_tags)
      return DeclaratorImpl.register_anon_plugin(plugin_spec)
    end,
    ---@return plugin_system.PluginSpec
    __index = function(_, plugin_id)
      local plugin_shim = DeclaratorImpl.declare_named_plugin(plugin_id)
      return setmetatable(plugin_shim, CallToRegisterPlugin_mt)
    end,
    __newindex = function(...)
      error("Assignements are forbidden, use `Plug.foo { ... }` to define a named plugin")
    end,
  })
end

--- The Plugin declarator:
--- * Use `Plug { ... }` to define an anonymous plugin
--- * Use `Plug.foo` to refer to a named plugin (may be undefined at this point)
--- * Use `Plug.foo { ... }` to define a named plugin
M.PlugDeclarator = DeclaratorImpl.get_plugin_declarator()
M.get_plugin_declarator = DeclaratorImpl.get_plugin_declarator

--------------------------------

-- IDEA: attach plugin behavior / load pattern based on tags?

---@class plugin_system.PlugTagSpec
---@field name string
---@field desc string

---@type {[string]: plugin_system.PlugTagSpec}
M.tags = setmetatable({}, {
  __index = KeyRefMustExist_mt.__index,
  ---@param name string
  ---@param spec {name?: string, desc: string}
  __newindex = function(self, name, spec)
    vim.validate{
      name={name, "string"},
      value={spec, "table"},
    }
    spec.name = name -- add name in spec
    rawset(self, name, spec)
  end,
})

--------------------------------

---@class PlugSourceBase
---@field type string
---@field name string

---@class PlugSourceGithub: PlugSourceBase
---@field url string
---@field owner_repo string

---@class PlugSourceLocal: PlugSourceBase
---@field path string

M.sources = {}
--- A Github repo plugin, will be installed, managed & loaded by pkg manager
---@param owner_repo string The Github repo path, like `owner/repo`
---@return PlugSourceGithub
function M.sources.github(owner_repo)
  return setmetatable({
    type = "github",
    owner_repo = owner_repo,
    name = owner_repo:gsub("^.*/", ""), -- remove 'owner/' in 'owner/repo'
    url = "https://github.com/" .. owner_repo .. ".git",
  }, KeyRefMustExist_mt)
end

--- A local path plugin, will not be managed by pkg manager, only loaded
---@param spec {name: string, path: string}
---@return PlugSourceLocal
function M.sources.local_path(spec)
  vim.validate{
    spec={spec, "table"},
    spec_name={spec.name, "string"},
    spec_path={spec.path, "string"},
  }
  return setmetatable({
    type = "local_path",
    name = spec.name,
    path = spec.path,
  }, KeyRefMustExist_mt)
end

--- A dist-managed plugin (e.g. by Nix 😉), will not be managed by pkg manager, only loaded
---@param name string Name of a dist-managed opt plugin (found in packpath)
---@return PlugSourceLocal?
M.sources.dist_managed_opt_plug = function(name)
  ---@type string[]
  local dist_paths = vim.fn.globpath(vim.o.packpath, vim.fs.joinpath("pack", "*", "opt", name), --[[respect-wildstuff]]false, --[[aslist]]true)
  if #dist_paths > 0 then
    return M.sources.local_path {
      name = name,
      path = dist_paths[1],
    }
  else
    vim.notify("Dist-managed opt plugin "..vim.inspect(name).." cannot be found in packpath", vim.log.levels.INFO)
    return nil
  end
end

-----------------------------------------------------------------
-- TODO(?): sort all_plugin_specs to have plugins that don't depend on anything first?
-- TODO: Make a list of plugin spec with only those plugins?

function M.check_missing_plugins()
  for _, plugin_spec in pairs(STATE._named_plugin_specs) do
    if plugin_spec.__is_placeholder_plugin_spec then
      error(_f("Named plugin", _q(plugin_spec.id), "is not defined!!!"))
    end
  end
end

function M.show_plugins_dependencies()
  local plugin_display_name = function(plugin_spec)
    if plugin_spec.id then
      return _f(plugin_spec.source.name, _s("(id: ", plugin_spec.id, ")"))
    else
      return plugin_spec.source.name
    end
  end
  for _, plugin_spec in pairs(M.all_plugin_specs()) do
    print("--- Plugins:", plugin_display_name(plugin_spec))
    if plugin_spec.depends_on then
      print("Depends on:")
      for _, p in ipairs(plugin_spec.depends_on) do
        print(" -", plugin_display_name(p))
      end
      print(" ")
    end
    if plugin_spec.config_depends_on then
      print("Its config depends on:")
      for _, p in ipairs(plugin_spec.config_depends_on) do
        print(" -", plugin_display_name(p))
      end
      print(" ")
    end
  end
end
-- M.show_plugins_dependencies()

--------------------------------

return M
