-- Define mods helper, to have a short way to create mods values
-- (e.g: mods._ for NONE, mods.CA for CTRL|ALT)
local mods = setmetatable({
  _SHORT_MOD_MAP = {
    _ = "NONE",
    C = "CTRL",
    S = "SHIFT",
    A = "ALT",
    D = "SUPER", -- D for Desktop (Win/Cmd/Super)
  }
}, {
  -- Dynamically transform key access of 'CSA' to 'CTRL|SHIFT|ALT'
  ---@param key string
  ---@return string
  __index = function(self, key)
    local resolved_mods = self._SHORT_MOD_MAP[key:sub(1, 1)]
    for i = 2, #key do
      local char = key:sub(i, i)
      resolved_mods = resolved_mods .. "|" .. self._SHORT_MOD_MAP[char]
    end
    return resolved_mods
  end,
})

-- Magic table to check support of actions/configs in current Wezterm
-- This allows conditional configs based on whether we're on a stable/nightly.
-- e.g.: `if supports_action.CopyMode { OptionNotStableYet = 42 } then ... end`
-- e.g.: `if supports_config.not_stable_yet(42) then ... end`
-- made as a Lua POC for: https://github.com/wezterm/wezterm/issues/7450
local wezterm = require"wezterm"
local supports_action = setmetatable({}, {
  __index = function (_self, key)
    return setmetatable({ support_checker_for_action = key }, {
      __call = function(_self, arg)
        -- note: output not used, only success
        local supported = pcall(function()
          local maybe_action = wezterm.action[key]
          -- print("theaction:", maybe_action, "type:", type(maybe_action))
          if type(maybe_action) == "string" then
            -- no arg supported, so none should have been passed
            return arg == nil
          end
          maybe_action(arg)
          -- if we're here, action with this arg is supported
        end)
        return supported
      end,
    })
  end,
})
local supports_config = setmetatable({}, {
  __index = function (_self, key)
    return setmetatable({ support_checker_for_config = key }, {
      __call = function(_self, value)
        -- note: output not used, only success
        if value == nil then
          error("Checking for config without value is not supported (yet)")
        end
        local supported = pcall(function()
          local config_builder = wezterm.config_builder()
          config_builder[key] = value
          -- if we're here, config with this value is supported
        end)
        return supported
      end,
    })
  end,
})

return {
  mods = mods,
  supports_action = supports_action,
  supports_config = supports_config,
}
