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

local KeyRefMustExist_mt = require"mylib.mt_utils".KeyRefMustExist_mt

-- FIXME: avoid global state!
-- FIXME: find a better name!
local MasterDeclarator = {
  -- Contains anonymous plugin specs
  _anon_plugin_specs = {},
  -- Contains named plugin specs
  _named_plugin_specs = {},
}
local named_plugin_specs = {}

---@class DeclaredPluginSpec
---@field plugin_id string The plugin ID
---@field __is_placeholder_plugin_spec ...

---@class PluginSpec: DeclaredPluginSpec
---@field source
---@field desc
---@field tags
---@field enable
---@field version
---@field depends_on
---@field config_depends_on
---@field on_load
---@field on_pre_load
---@field on_colorscheme_change
---...

function MasterDeclarator:all_specs()
  local all_specs = {}
  vim.list_extend(all_specs, self._anon_plugin_specs)
  vim.list_extend(all_specs, vim.tbl_values(self._named_plugin_specs))
  return all_specs
end

function MasterDeclarator:named_specs()
  return vim.tbl_extend("force", {}, self._named_plugin_specs)
end

-- Allows the following syntax:
--   Plug { spec for anonymous plugin }
function MasterDeclarator:register_anon_plugin(plugin_spec)
  vim.validate{ plugin_spec={plugin_spec, "table"} }
  -- TODO: validate spec is fully respected!
  table.insert(self._anon_plugin_specs, plugin_spec)
  return plugin_spec
end
function MasterDeclarator:get_anonymous_plugin_declarator()
  return function(...)
    self:register_anon_plugin(...)
  end
end

local CallToRegisterPlugin_mt = {
  ---@param self DeclaredPluginSpec
  ---@param spec_fields PluginSpec
  __call = function(self, spec_fields)
    if not self.__is_placeholder_plugin_spec then
      error(_f("Cannot register the named plugin spec", _q(self.id), "twice"))
    end
    self.__is_placeholder_plugin_spec = nil
    -- copy all spec fields to the existing/stored spec
    for k, v in pairs(spec_fields) do self[k] = v end
    -- TODO: validate spec is fully respected!
  end,
}

---Declares a named plugin
---@param plugin_id string The plugin ID to declare
---@return DeclaredPluginSpec
function MasterDeclarator:declare_named_plugin(plugin_id)
  if self._named_plugin_specs[plugin_id] then
    return self._named_plugin_specs[plugin_id]
  end
  local initial_plugin_spec = setmetatable({
    id = plugin_id,
    __is_placeholder_plugin_spec = true, -- will be set to nil when plugin gets defined!
  }, CallToRegisterPlugin_mt)
  -- Save named spec, so later references return this spec!
  self._named_plugin_specs[plugin_id] = initial_plugin_spec
  return initial_plugin_spec
end

-- Allows the following syntax:
--   local NamedPlug = MasterDeclarator:get_named_plugin_declarator()
--   NamedPlug.foo { spec for plugin named foo }
-- And save to initial spec, so later references find it.
function MasterDeclarator:get_named_plugin_declarator()
  return setmetatable({}, {
    __index = function(_, plugin_id)
      return self:declare_named_plugin(plugin_id)
    end,
    __newindex = function(...)
      error("Assignements are forbidden, use `NamedPlug.foo { ... }` to declare/define named plugin")
    end,
  })
end

--------------------------------

-- IDEA: attach plugin behavior / load pattern based on tags?
local predefined_tags = setmetatable({}, {
  __index = KeyRefMustExist_mt.__index,
  __newindex = function(self, tag_name, tag_spec)
    if type(tag_name) ~= "string" or type(tag_spec) ~= "table" then
      error("Tag name must be string, value must be table")
    end
    tag_spec.name = tag_name -- add name in spec
    rawset(self, tag_name, tag_spec)
  end,
})

--------------------------------

local PlugSource = {}
function PlugSource.github(owner_repo)
  return setmetatable({
    type = "github",
    owner_repo = owner_repo,
    name = owner_repo:gsub("^.*/", ""), -- remove 'owner/' in 'owner/repo'
    url = "https://github.com/" .. owner_repo .. ".git",
  }, KeyRefMustExist_mt)
end
function PlugSource.local_path(spec)
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

-----------------------------------------------------------------
-- TODO(?): sort all_plugin_specs to have plugins that don't depend on anything first?
-- TODO: Make a list of plugin spec with only those plugins?

function MasterDeclarator:check_missing_plugins()
  for _, plugin_spec in pairs(self._named_plugin_specs) do
    if plugin_spec.__is_placeholder_plugin_spec then
      error(_f("Named plugin", _q(plugin_spec.id), "is not defined!!!"))
    end
  end
end

function MasterDeclarator:show_plugins_dependencies()
  local plugin_display_name = function(plugin_spec)
    if plugin_spec.id then
      return _f(plugin_spec.source.name, _s("(id: ", plugin_spec.id, ")"))
    else
      return plugin_spec.source.name
    end
  end
  for _, plugin_spec in pairs(self:all_specs()) do
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
--MasterDeclarator:show_plugins_dependencies()

--------------------------------

return {
  MasterDeclarator = MasterDeclarator,
  predefined_tags = predefined_tags,
  sources = PlugSource,
}
