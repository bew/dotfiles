local real_stdpath_fn = vim.fn.stdpath

-- TODO: Add little doc and type annotations when I have something that can check them!

local M = {}

local function get_override_from_env(what)
  local env_var = "NVIM_STDPATH_" .. what:upper()
  return vim.env[env_var]
end
M.NVIM_STDPATH_env_overrides = {
  cache = get_override_from_env,
  config = get_override_from_env,
  data = get_override_from_env,
  log = get_override_from_env,
  run = get_override_from_env,
  state = get_override_from_env,
}

local function resolve_override_value(what, maybe_override)
  if not maybe_override then return nil end
  if type(maybe_override) == "string" then
    return maybe_override
  elseif type(maybe_override) == "function" then
    return resolve_override_value(what, maybe_override(what))
  end
end

local function resolve_overrides(what, overrides)
  for _, override_table in ipairs(overrides) do
    local maybe_override = resolve_override_value(what, override_table[what])
    if maybe_override then
      return maybe_override
    end
  end
end

function make_custom_stdpath_fn(opts)
  local cache = {}
  return function(what)
    if cache[what] then
      return cache[what]
    end
    local path = resolve_overrides(what, opts.overrides)
    if not path then
      -- Last resort fallback to the real stdpath
      path = real_stdpath_fn(what)
    end
    if opts.cache_on_first_resolve then
      cache[what] = path
    end
    return path
  end
end

local DEFAULT_OPTS = {
  overrides = { M.NVIM_STDPATH_env_overrides },
  cache_on_first_resolve = true,
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, opts or {})
  vim.fn.stdpath = make_custom_stdpath_fn(opts)
end

function TEST()
  -- Call nvim like so:
  --   NVIM_STDPATH_DATA=foodata NVIM_STDPATH_CONFIG=foocfg nvim -u path/to/this/file.lua
  --
  -- We should get the following prints
  --   !!! Called for config !!!
  --   Current config path is: config from fn!
  --   Current config path is: config from fn! (should be cached)
  --   Current data path is: foodata
  --   Current state path is: /home/bew/.local/state/nvim
  M.setup {
    overrides = {
      {
        config = function()
          print("!!! Called for config !!!")
          return "config from fn!"
        end,
      },
      M.NVIM_STDPATH_env_overrides,
    },
    cache_on_first_resolve = true,
  }

  print("Current config path is:", vim.fn.stdpath("config"))
  print("Current config path is:", vim.fn.stdpath("config"), "(should be cached)")
  print("Current data path is:", vim.fn.stdpath("data"))
  print("Current state path is:", vim.fn.stdpath("state"))
end
--TEST()

return M
