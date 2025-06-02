local U = require"mylib.utils"
local _f = U.fmt.str_space_concat
local _q = U.fmt.str_simple_quote_surround

local A = {}



-- Minimal action system
--
-- IDEA of a plugin name:
-- - `factions` [short: `fact`]: Framework for Actions
--   BAD: plugin short name `fact` doesn't make me think about actions, but facts which an entirely
--     different thing..
-- - `nactions` [short: `nact`]: Neovim Actions
-- - `spectacle` [short: `acts`]: Like at a spectacle we present only nice interface (nice show),
--   through acts (meaning actions for us, but parts of a play for a spectacle).
-- - Words related to 'somebody/something who does actions':
--   * "performer" (❤ ?)
--   * "actor"
--   * "operator"
--   * "executor"
--   Nice ones!

---@alias act.ModeActionSpecRawInput string|(fun(...): string?)

---@class act.ModeActionSpecObjInput
---@field raw_action? act.ModeActionSpecRawInput The raw action to execute
---@field default_desc? string The default description for the keymap when this action is used
---@field map_opts? {[string]: any} The keymap options for that action
---@field debug? boolean Wheather to debug the effective keymap args on use

---@alias act.ModeActionSpecInput act.ModeActionSpecRawInput|act.ModeActionSpecObjInput

---@class act.ActionSpecInput: act.ModeActionSpecObjInput (used as defaults for each mode)
---@field n? act.ModeActionSpecInput Action spec for normal mode
---@field i? act.ModeActionSpecInput Action spec for insert mode
---@field v? act.ModeActionSpecInput Action spec for visual mode (not select)
---@field o? act.ModeActionSpecInput Action spec for operator mode
---@field c? act.ModeActionSpecInput Action spec for command mode
--- + key like `{"n", "i"}` to set both `n` & `i` action spec.

---@class act.ModeAction
---@overload fun(): string? (maybe expr fn)
---@field raw_action act.ModeActionSpecRawInput The raw action to execute
---@field default_desc string The default description for the keymap when this action is used
---@field map_opts {[string]: any} The keymap options for that action
---@field debug boolean Wheather to debug the effective keymap args on use
local ModeAction = U.mt.checked_table_index{}
ModeAction.mt = {}
ModeAction.mt.__index = ModeAction

--- Do the action via a function call
--- This is useful to run an action from another action / function..
---@param self act.ModeAction
---@param ... any
---@return string?
function ModeAction.mt:__call(...)
  local raw_action = self.raw_action
  if type(raw_action) == "function" then
    return raw_action(...)
  elseif type(raw_action) == "string" then
    ---@type mylib.FeedKeysOpts
    local feed_keys_opts = {
      remap = self.map_opts.remap ~= false, -- remap by default
      replace_termcodes = true,
    }
    if self.debug then
      print(_f{
        "Debugging ad-hoc feedkeys:",
        "raw_action:", vim.inspect(self.raw_action),
        "feed_keys_opts:", vim.inspect(feed_keys_opts),
      })
    end
    U.feed_keys_sync(raw_action, feed_keys_opts)
  else
    error(_f("Ad-hoc action call with raw action of type", _q(type(raw_action)), "is not supported"))
  end
end

---@class act.MultiModeAction
---@field meta table Metadata about this action
---@field mode_actions {[string]: act.ModeAction} Action for each mode
local MultiModeAction = U.mt.checked_table_index{}
MultiModeAction.mt = {}
MultiModeAction.mt.__index = MultiModeAction

--- Try get the action for the given mode, returns nil if the mode is not supported by the action
---@param mode string
---@return act.ModeAction?
function MultiModeAction:try_get_mode_action(mode)
  return rawget(self.mode_actions, mode)
end

--- Get the action for the given mode, error if the mode is not supported by the action
---@param mode string
---@return act.ModeAction
function MultiModeAction:get_mode_action(mode)
  local mode_action = self:try_get_mode_action(mode)
  if not mode_action then
    error(_f("Mode", _q(mode), "is not supported by this action"))
  end
  return mode_action
end

--- Whether the action supports the given modes
---@param given_modes string|string[]
---@return boolean
function MultiModeAction:supports_modes(given_modes)
  vim.validate { mode={given_modes, {"string", "table"}} }
  for _, mode in ipairs(U.args.normalize_arg_one_or_more(given_modes)) do
    if self:try_get_mode_action(mode) then
      return true
    end
  end
  return false
end

--- Returns a function to pass to `vim.keymap.set`, and that will select the correct action mode
--- based on the current mode (or error if the current mode is not supported by the action)
---@return (fun(): any)
function MultiModeAction:get_multimode_proxy_fn()
  return function()
    local current_mode = vim.fn.mode()
    local mode_action = self:get_mode_action(current_mode)
    return mode_action()
  end
end

-- WIP WIP WIP (and untested) functions to enable configurable actions
--
-- --- Returns true if the action has configuration options, false otherwise.
-- is_configurable = function(self)
--   return type(self.options_def) == "table" and not vim.tbl_isempty(self.options_def)
-- end,
--
-- --- Set given options as the default options for this action from now on.
-- set_default_opts = function(self, given_opts)
--   self:_ensure_is_configurable()
--   self:_validate_given_opts(given_opts)
--   self.opts = vim.tbl_extend("force", self.opts, given_opts)
-- end,
--
-- --- Duplicate this action with the given options replacing default ones
-- with_opts = function(self_parent, given_opts)
--   self:_ensure_is_configurable()
--   self:_validate_given_opts(given_opts)
--   local new_action_opts = vim.tbl_extend("keep", given_opts, self_parent.opts)
--   -- FIXME: make a cheap proxy action with new opts (and good mt) & return that
--   local proxy_action = {opts = new_action_opts}
--   -- FIXME: copy self_parent's metatable, and add original action as `__index` metamethod
--   local self_mt = getmetatable(self_parent)
--   local proxy_mt = vim.tbl_extend("force", {}, self_mt) -- copy metatable
--   proxy_mt.__index = self_parent -- if not found in parent, its mt should be triggered
--   return setmetatable(proxy_action, proxy_mt)
-- end,
--
-- -- Ensure the action is configurable before trying to access/use options
-- _ensure_is_configurable = function(self)
--   if not self:is_configurable() then
--     error("This action is NOT configurable!")
--   end
-- end,
-- -- Validate given_opts has only declared options & values are of valid types.
-- _validate_given_opts = function(self, given_opts)
--   for opt_name, new_value in pairs(given_opts) do
--     if not self.options_def[opt_name] then
--       error("This action doesn't have option '" .. opt_name .. "'")
--     end
--     local opt_spec = self.options_def[opt_name]
--     if type(new_value) ~= opt_spec.type then
--       error(_f("Given value for option", _q(opt_name), "has invalid type", _q(type(new_value))))
--     end
--   end
-- end,

--- A set of actions
---@class act.ActionsSet: {[string]: act.MultiModeAction}

--- The main set of actions
---@class act.Actions: act.ActionsSet
---@diagnostic disable-next-line: lowercase-global
my_actions = {}
-- NOTE: using a @class here makes LuaLS register all new fields as class fields
--   👉 Gives _GREAT_ completion for all actions ✨

--- Usage:
--- ```lua
--- A.mk_action {
---   default_desc = "Description for n/i (normal/insert mode) actions"
---
---   n = "zz",
---   -- same as
---   n = {
---     "zz",
---     -- other options for action for normal mode
---   }
---   -- same as
---   n = {
---     raw_action = "zz"
---   }
---   -- technically same as
---   n = {
---     map_opts = { expr = true },
---     raw_action = function() return "zz" end
---   }
---
---   i = {
---     function() return "<Left>" end,
---     map_opts = { expr = true },
---   }
---
---   v = {
---     default_desc = "Description for visual mode action"
---     "zf"
---     map_opts = { silent = true },
---   }
--- }
--- ```
---@param global_spec act.ActionSpecInput
---@return act.MultiModeAction
function A.mk_action(global_spec)
  -- For a given mode, I want these fields:
  -- - default_desc
  -- - raw_action
  -- - map_opts
  -- - debug
  -- If field not given (except for `raw_action`), use the field at parent level (for all modes) if any

  ---@param mode_spec act.ModeActionSpecInput
  ---@return act.ModeAction
  local function mk_action_single_mode(mode_spec)
    -- (note: uses upvalue 'global_spec')
    if type(mode_spec) == "function" or type(mode_spec) == "string" then
      mode_spec = { raw_action = mode_spec }
    end
    if type(mode_spec) ~= "table" then
      error(_f("spec for mode must be a function, a string or a mode spec, got", _q(type(mode_spec))))
    end
    -- Allow raw_action to be given without the key, as first item of a table list
    -- => `n = { "foo" }` is same as `n = { raw_action = "foo" }`
    if mode_spec.raw_action == nil then
      if mode_spec[1] ~= nil then
        mode_spec.raw_action = mode_spec[1]
      else
        error("Missing action!")
      end
    end
    local default_desc = mode_spec.default_desc or global_spec.default_desc
    if not default_desc then
      error("Missing default_desc!")
    end
    ---@type act.ModeAction
    local mode_action = {
      raw_action = mode_spec.raw_action,
      default_desc = default_desc,
      map_opts = mode_spec.map_opts or global_spec.map_opts or {},
      debug = mode_spec.debug or global_spec.debug or false,
    }
    return setmetatable(mode_action, ModeAction.mt)
  end

  local VALID_MODES_FOR_ACTIONS = {"n", "i", "v", "x", "o", "c", "s"}

  -- Find all action specs for each valid mode
  local spec_for_mode = {}
  for maybe_mode, value in pairs(global_spec) do
    if type(maybe_mode) == "string" then
      if vim.tbl_contains(VALID_MODES_FOR_ACTIONS, maybe_mode) then
        spec_for_mode[maybe_mode] = value
      end
    end
    if type(maybe_mode) == "table" then
      for _, mode in ipairs(maybe_mode) do
        if vim.tbl_contains(VALID_MODES_FOR_ACTIONS, mode) then
          spec_for_mode[mode] = value
        end
      end
    end
  end
  if vim.tbl_isempty(spec_for_mode) then
    error("Action has no mode available")
  end

  local mode_actions = vim.tbl_map(mk_action_single_mode, spec_for_mode)

  ---@type act.MultiModeAction
  local action_obj = {
    meta = { action_version = "v2" },
    mode_actions = U.mt.checked_table_index(mode_actions)
  }
  if global_spec.debug then
    print("Debugging action:", vim.inspect(action_obj))
  end
  return setmetatable(action_obj, MultiModeAction.mt)
end

function A.mk_action_opt(_spec)
  -- NOT IMPLEMENTED YET
  return false
end

-- function A.mk_configurable_action(spec)
--   -- NOTE: A configurable action has options (inspired from NixOS options, at a single level),
--   -- and can be configured where it's going to be used.
--
--   -- TODO: validate `spec` inputs!
--   assert(spec.options, "a configurable action must actually expose options to be configurable..")
-- end

return A
