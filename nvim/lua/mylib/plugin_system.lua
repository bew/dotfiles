-- THE IDEA:
-- ```
-- local Plug = ...
-- local Plug = ...
--
-- Plug.foobar {
--   ...
--   config_depends_on = {
--     -- anonymous plugin that depends on foobar
--     Plug { ..., depends_on = {Plug.foobar} }
--   },
-- }
-- ```
-- note: 'Plug' is a automagic proxy / setter for a named plugin spec
-- The tricky part is that the `Plug.foobar` in `config_depends_on` is called _before_ the
-- plugin is defined.
-- So `Plug.foobar` must declare the named plugin on first reference, and always refer to the
-- same object before and after it is defined.

--- The Plugin declarator:
--- * Use `Plug { ... }` to define an anonymous plugin
--- * Use `Plug.foo` to refer to a named plugin (may be undefined at this point)
--- * Use `Plug.foo { ... }` to define a named plugin
---@class plugsys.PlugDeclarator
---@overload fun(spec: plugsys.PluginSpec): plugsys.PluginSpecDeclared
---@field [string] plugsys.PluginSpecDeclared

---@class plugsys.PluginSpecDeclared
---@overload fun(spec: plugsys.PluginSpec): plugsys.PluginSpecDeclared
---@field id string The plugin ID
---@field __is_placeholder_plugin_spec boolean?

-- note: avoid inherit from PluginSpecDeclared to avoid inheritting the callable overload
---@class plugsys.PluginSpec
---@field source plugsys.PlugSourceBase Spec about the plugin's source location
---@field id? string The plugin ID
---@field desc? string Rough single-line description
---@field enabled? boolean Whether the plugin should be loaded by the pkg manager
---@field tags? (string|plugsys.TagSpec)[]
---@field version? plugsys.PluginVersionSpec
---@field depends_on? plugsys.PluginSpecDeclared[]
---@field config_depends_on? plugsys.PluginSpecDeclared[]
---@field defer_load? plugsys.PluginDeferredLoadSpec
---@field on_pre_load? fun() Hook run before plugin is loaded
---@field on_load? fun() Hook run just after plugin is loaded
---@field on_colorscheme_change? fun() Hook run when colorscheme changes
---@field _INVALID? string Message explaining what is invalid about this spec

---@alias plugsys.PluginInstallPath string|(fun(): string)

---@class plugsys.PluginSpecPkgManager: plugsys.PluginSpec
---@field install_path plugsys.PluginInstallPath Where the pkg is/should-be installed
---    (as function, called if pkg source has no (specified/existing) path)
---@field bootstrap_itself? fun(self, ctx: plugsys.BootPlugContext)
---@field on_boot fun(self, ctx: plugsys.BootPlugContext)

---@class plugsys.PluginDeferredLoadSpec
---@field autodetect? boolean When true, the plugin will only be loaded when needed
---@field on_event? string|string[] Defer load on (builtin/user) event(s)
---@field on_ft? string|string[] Defer load on filetype(s)
---@field on_cmd? string|string[] Defer load on command(s)

---@class plugsys.PluginVersionSpec
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
  ---@type plugsys.PluginSpec[]
  _anon_plugin_specs = {},
  --- Contains named plugin specs
  ---@type {[string]: plugsys.PluginSpec|plugsys.PluginSpecDeclared}
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

--- Checks if the given source is a valid plugin source
---@param src any
---@return boolean
local function is_plugin_source_valid(src)
  if type(src) ~= "table" then
    return false
  end
  if not src.type or src.type == "BAD_SOURCE" then
    return false
  end
  return type(src.type) == "string" and type(src.name) == "string"
end

---@param spec plugsys.PluginSpec
local function check_plugin_source(spec)
  if type(spec.source) == "function" then
    spec.source = spec.source()
  end
  if not is_plugin_source_valid(spec.source) then
    local plugin_info ---@type string
    if spec.id then
      plugin_info = "(id: "..spec.id..")"
    elseif type(spec.source) == "table" and type(spec.source.name) == "string" then
      plugin_info = "(name: "..spec.source.name..")"
    else
      plugin_info = "(unamed)"
    end
    vim.notify(_f("Source for plugin", plugin_info, "is invalid"), vim.log.levels.ERROR)
    -- source isn't valid, disable the plugin
    spec.enabled = false
    spec._INVALID = "Invalid source"
  end
end

---@param spec plugsys.PluginSpec
function DeclaratorImpl.check_plugin_declaration(spec)
  -- TODO: validate spec is fully respected!
  check_plugin_source(spec)
end

---@param spec plugsys.PluginSpec
---@return plugsys.PluginSpec
function DeclaratorImpl.register_anon_plugin(spec)
  vim.validate{ spec={spec, "table"} }
  DeclaratorImpl.check_plugin_declaration(spec)
  table.insert(STATE._anon_plugin_specs, spec)
  return spec
end

--- Declares a named plugin
---@param plugin_id string The plugin ID to declare
---@return plugsys.PluginSpecDeclared|plugsys.PluginSpec
function DeclaratorImpl.declare_named_plugin(plugin_id)
  if STATE._named_plugin_specs[plugin_id] then
    return STATE._named_plugin_specs[plugin_id]
  end
  ---@type plugsys.PluginSpecDeclared
  local placeholder_plugin_spec = {
    id = plugin_id,
    __is_placeholder_plugin_spec = true, -- will be set to nil when plugin gets defined!
  }
  -- Save named spec, so later references return this spec!
  STATE._named_plugin_specs[plugin_id] = placeholder_plugin_spec
  return placeholder_plugin_spec
end

---@class plugsys.DeclaratorDefaults
---@field default_tags? (string|plugsys.TagSpec)[]

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
---@param defaults? plugsys.DeclaratorDefaults
---@return plugsys.PlugDeclarator
function M.get_plugin_declarator(defaults)
  ---@type plugsys.DeclaratorDefaults
  local plugin_defaults = vim.tbl_extend("keep", defaults or {}, {
    default_tags = {}
  })
  return setmetatable({}, {
    ---@param plugin_spec plugsys.PluginSpec
    ---@return plugsys.PluginSpec
    __call = function(_, plugin_spec)
      ---@diagnostic disable-next-line: undefined-field (Want to ensure weird case doesn't happen)
      if plugin_spec._IS_PLUGIN_DECLARATOR then
        error("!! Decl is passed to itself??")
      end
      plugin_spec.tags = vim.list_extend(plugin_spec.tags or {}, plugin_defaults.default_tags)
      return DeclaratorImpl.register_anon_plugin(plugin_spec)
    end,
    ---@return plugsys.PluginSpec
    __index = function(_, plugin_id)
      if plugin_id == "_IS_PLUGIN_DECLARATOR" then
        -- Magic value, only for the declarator
        return true
      end
      local plugin_shim = DeclaratorImpl.declare_named_plugin(plugin_id)
      return setmetatable(plugin_shim, {
        ---@param self plugsys.PluginSpecDeclared
        ---@param spec_fields plugsys.PluginSpec
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
      })
    end,
    __newindex = function(...)
      error("Assignements are forbidden, use `Plug.foo { ... }` to define a named plugin")
    end,
  })
end

--------------------------------

-- IDEA: attach plugin behavior / load pattern based on tags?

---@class plugsys.TagSpec
---@field name string
---@field desc string

---@type {[string]: plugsys.TagSpec}
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

---@class plugsys.PlugSourceBase
---@field type string Source type
---@field name string Name of the plugin

---@alias plugsys.PlugSourceDefered (fun(): plugsys.PlugSourceBase)

---@class plugsys.PlugSourceGithub: plugsys.PlugSourceBase
---@field owner_repo string Repo address in format `owner/repo`
---@field url string Full URL of the repo

---@class plugsys.PlugSourceLocal: plugsys.PlugSourceBase
---@field path string Static path of the plugin, if it's a function, it will be
---    called when needed and the result will be saved to `self.resolved_local_path`.

M.sources = {}

--- Returns a BAD source for a plugin, used as a marker when the real source cannot be found.
---@param name string Arbitrary name for the plugin
---@return plugsys.PlugSourceBase
function M.sources.BAD_SOURCE(name)
  return {
    type = "BAD_SOURCE",
    name = name,
  }
end

--- A Github repo plugin, will be installed, managed & loaded by pkg manager
---@param owner_repo string The Github repo path, like `owner/repo`
---@return plugsys.PlugSourceGithub
function M.sources.github(owner_repo)
  ---@type plugsys.PlugSourceGithub
  return setmetatable({
    type = "github",
    owner_repo = owner_repo,
    name = owner_repo:gsub("^.*/", ""), -- remove 'owner/' in 'owner/repo'
    url = "https://github.com/" .. owner_repo .. ".git",
  }, KeyRefMustExist_mt)
end

--- A local path plugin, will not be managed by pkg manager, only loaded
---@param spec plugsys.PlugSourceLocal
---@return plugsys.PlugSourceLocal
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
---@return plugsys.PlugSourceDefered
M.sources.dist_managed_opt_plug = function(name)
  return function()
    local glob_expr = vim.fs.joinpath("pack", "*", "opt", name)
    local dist_paths = vim.fn.globpath(vim.o.packpath, glob_expr, --[[respect-wildstuff]]false, --[[aslist]]true)
    if #dist_paths == 0 then
      return M.sources.BAD_SOURCE(name)
    end

    return M.sources.local_path {
      name = name,
      path = dist_paths[1],
    }
  end
end

--- Returns the first valid plugin source
---@param name string Arbitrary name for the plugin, used if fallback can't find any viable source.
---@param ... plugsys.PlugSourceBase|plugsys.PlugSourceDefered Sources to try
---@return plugsys.PlugSourceBase
M.sources.fallback = function(name, ...)
  -- (note: `ipairs{...}` stops at first nil param)
  for _, src in pairs({...}) do
    if type(src) == "function" then
      local resolved_src = src()
      if is_plugin_source_valid(resolved_src) then
        return resolved_src
      end
    end
    if is_plugin_source_valid(src) then
      return src --[[@as plugsys.PlugSourceBase]]
    end
  end
  vim.notify("Unable to find a valid source for '"..name.."' plugin", vim.log.levels.ERROR)
  return M.sources.BAD_SOURCE(name)
end

-----------------------------------------------------------------
-- MAYBE: sort all_plugin_specs to have plugins that don't depend on anything first?
-- MAYBE: Make a list of plugin spec with only those plugins?

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

return M
