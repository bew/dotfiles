local DebugSession = require"debug-autocmds.debug-session"
local Utils = require"debug-autocmds.utils"

local M = {}
local STATE = {
  sessions = {},
}
M._state = STATE

local function setup_watchers_on(sess, event_specs)
  STATE.sessions[sess.name] = sess
  for _, spec in ipairs(event_specs) do
    vim.api.nvim_create_autocmd(spec.name, {
      group = sess.augroup,
      callback = function(event_data)
        sess:record_event(event_data)
      end,
    })
  end
end

M.default_config = {
  global_tracking_on_start = false,
}

function M.setup(given_cfg)
  local cfg = vim.tbl_extend("force", M.default_config, given_cfg or {})
  if cfg.global_tracking_on_start then
    local global_session = M.create_session{ name = "global" }
    global_session:start_with_events(require"debug-autocmds.builtin_events")
  end
end

function M.create_session(opts)
  local session = DebugSession(opts)
  STATE.sessions[session.name] = session
  return session
end

function M.get_session(name)
  return STATE.sessions[name]
end
M.get = M.get_session

-- Nice 'oneliner' to get some info about buffer/window/tab events
-- require"debug-autocmds".get"global":dump_matching_with("buf,win,tab", function(ev) print(("%-15s"):format(ev.name), vim.fs.basename(ev.raw.file), "   tab:", ev.extra.tabnr, "   win:", ev.extra.winid) end)

return M
