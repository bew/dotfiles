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

---@alias act.ModeRawActionInput string|(fun(): any)

---@class act.ModeActionSpecInput
---@field raw_action? act.ModeRawActionInput The raw action to execute
---@field default_desc? string The default description for the keymap when this action is used
---@field map_opts? {string: any} The keymap options for that action
---@field debug? boolean Wheather to debug the effective keymap args on use

---@class act.ActionSpecInput: act.ModeActionSpecInput (used as defaults for each mode)
---@field n? act.ModeRawActionInput|act.ModeActionSpecInput Action spec for normal mode
---@field i? act.ModeRawActionInput|act.ModeActionSpecInput Action spec for insert mode
---@field v? act.ModeRawActionInput|act.ModeActionSpecInput Action spec for visual mode
---@field o? act.ModeRawActionInput|act.ModeActionSpecInput Action spec for operator mode
---@field c? act.ModeRawActionInput|act.ModeActionSpecInput Action spec for command mode
--- + key like `{"n", "i"}` to set both `n` & `i` action spec.

---@class act.ModeAction: act.ModeActionSpecInput

---@class act.Action
---@field meta table Metadata about this action
---@field mode_actions {string: act.ModeAction} Action for each mode
---@field supports_mode fun(any, string):boolean Whether the action supports the given modes

local ActionSpec_mt = {
  __index = setmetatable(
    {
      supports_mode = function(self, given_modes)
        vim.validate { mode={given_modes, {"string", "table"}} }
        local supported_modes = vim.tbl_keys(self.mode_actions)
        for _, mode in ipairs(U.args.normalize_arg_one_or_more(given_modes)) do
          if not vim.tbl_contains(supported_modes, mode) then
            return false
          end
        end
        return true
      end,

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
    },
    -- FIXME: is there a better/simpler way to chain __index metamethods?
    U.mt.KeyRefMustExist_mt
  ),
  __call = function(self, ...)
    local nb_mode_actions = #vim.tbl_keys(self.mode_actions)
    if nb_mode_actions ~= 1 then
      error(_f(
        "Ad-hoc action call ONLY supports single mode action, got", nb_mode_actions,
        "(mode(s)", vim.inspect(vim.tbl_keys(self.mode_actions)), ")"
      ))
    end
    local adhoc_action = vim.tbl_values(self.mode_actions)[1]
    adhoc_action(...)
  end
}
local SingleModeActionSpec_mt = {
  __call = function(self, ...)
    if (self.map_opts or {}).expr then
      error("Ad-hoc action call of expr-based action is NOT tested/supported")
    end

    local raw_action_type = type(self.raw_action)
    if raw_action_type == "function" then
      self.raw_action(...)
    elseif raw_action_type == "string" then
      error("Ad-hoc action call of a string raw action is not implemented (failed..)")
      -- FIXME: I can't get it to work properly,
      --   e.g with cmd mode or surround actions..
      ----------------------------------------------------
      -- local feed_keys_opts = {
      --   remap = self.keymap_opts.remap,
      --   replace_keycodes = self.keymap_opts.expr or false,
      -- }
      -- -- if self.debug then
      --   print("Debugging ad-hoc feedkeys:",
      --     "raw_action:", vim.inspect(self.raw_action),
      --     "feed_keys_opts:", vim.inspect(feed_keys_opts),
      --   )
      -- -- end
      -- -- NOTE: assumes termcodes haven't been replaced yet (<C-x>, <Plug>, etc..)
      -- U.feed_keys_sync(self.raw_action, feed_keys_opts)
      -- vim.api.nvim_feedkeys(self.raw_action, feedkeys_mode, replace_keycodes)
    else
      error(_f("Ad-hoc action call with raw action of type", _q(raw_action_type), "is not supported"))
    end
  end,
}

---@alias ActionList {[string]: act.Action|ActionList}

---@type ActionList
---@diagnostic disable-next-line: lowercase-global
my_actions = {}

-- Usage:
-- A.mk_action {
--   default_desc = "Description for n/i (normal/insert mode) actions"
--
--   n = "zz",
--   -- same as
--   n = {
--     "zz",
--     -- other options for action for normal mode
--   }
--   -- same as
--   n = {
--     raw_action = "zz"
--   }
--   -- technically same as
--   n = {
--     map_opts = { expr = true },
--     raw_action = function() return "zz" end
--   }
--
--   i = {
--     function() return "<Left>" end,
--     map_opts = { expr = true },
--   }
--
--   v = {
--     default_desc = "Description for visual mode action"
--     "zf"
--     map_opts = { silent = true },
--   }
-- }
---@param global_spec act.ActionSpecInput
function A.mk_action(global_spec)
  -- For a given mode, I want these fields:
  -- - default_desc
  -- - raw_action

  -- - map_opts
  -- - debug
  -- If field not given (except for `raw_action`), use the field at parent level (for all modes) if any

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
    local mode_action = {
      raw_action = mode_spec.raw_action,
      default_desc = mode_spec.default_desc or global_spec.default_desc,
      map_opts = mode_spec.map_opts or global_spec.map_opts,
      debug = mode_spec.debug or global_spec.debug,
    }
    return setmetatable(mode_action, SingleModeActionSpec_mt)
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

  local action_obj = {
    meta = { action_version = "v2" },
    mode_actions = vim.tbl_map(mk_action_single_mode, spec_for_mode),
  }
  if global_spec.debug then
    print("Debugging action:", vim.inspect(action_obj))
  end
  return setmetatable(action_obj, ActionSpec_mt)
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
