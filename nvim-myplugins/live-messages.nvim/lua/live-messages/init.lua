-- live-messages: an append-only buffer mirroring `:messages`, with a trailing
-- sentinel line, timestamped markers, and a window-local statusline.

local M = {}

---User-facing actions (see the Actions section).
M.actions = {}

---@alias LiveMessages.Split "vertical"|"horizontal"

---Window options applied to the live window when it opens.
---@alias LiveMessages.WindowOptions table<string, any>
-- (NOTE: @2026-09 no vim type for an arbitrary set of `:h option-list` window options)

---@class LiveMessages.OnAttachCtx
---@field bufnr integer Live-messages buffer the hook is called for.

---@class LiveMessages.Opts.UserConfig
---@field default_split? LiveMessages.Split Split direction when the command passes no modifier.
---@field window_options? LiveMessages.WindowOptions Window options applied on open.
---@field on_attach? fun(ctx: LiveMessages.OnAttachCtx): nil Called once, with the live buffer current.

---@class LiveMessages.Config
---@field default_split LiveMessages.Split
---@field window_options LiveMessages.WindowOptions
---@field on_attach fun(ctx: LiveMessages.OnAttachCtx): nil

---@class LiveMessages.State
---@field bufnr integer
---@field winid integer|nil
---@field timer uv.uv_timer_t|nil
---@field prev string[]         -- last :messages snapshot, used to diff new lines
---@field msg_count integer      -- message lines mirrored into the buffer
---@field has_marker boolean     -- whether at least one marker was inserted
---@field new_since_marker integer  -- messages appended since the last marker
---@field pending_count integer  -- new lines seen but not yet scrolled to
---@field attached boolean       -- whether config.on_attach already ran for the buffer
---@field ns_pending integer     -- namespace for the pending "+N new" virt-text
---@field ns_mark integer        -- namespace for marker line highlights

---@type LiveMessages.Config
M.default_config = {
  default_split = "vertical",
  window_options = {
    wrap = false,
    number = false,
    relativenumber = false,
  },
  on_attach = function(_ctx) end,
}

local config = M.default_config

---Polling interval for the `:messages` diff.
local POLL_INTERVAL_MS = 500

---Prefix opening and closing a marker line; also the marker-navigation search pattern.
local MARKER_PREFIX = "----"

---Highlight group for the "+N new" pending virt-text.
local PENDING_HL = "DiagnosticVirtualTextHint"

---Highlight group for marker lines.
local MARKER_HL = "DiagnosticVirtualTextInfo"

---Statusline expression target; 'statusline' can only reach Lua through `v:lua`.
---@return string
function _G.__live_messages_statusline()
  return require"live-messages".get_statusline()
end

---@type LiveMessages.State
local state = {
  bufnr = -1,
  winid = nil,
  timer = nil,
  prev = {},
  msg_count = 0,
  has_marker = false,
  new_since_marker = 0,
  pending_count = 0,
  attached = false,
  ns_pending = vim.api.nvim_create_namespace("live-messages.pending"),
  ns_mark = vim.api.nvim_create_namespace("live-messages.mark"),
}

local augroup = vim.api.nvim_create_augroup("LiveMessages", { clear = true })

-- -------------------------------------------------------
-- Message snapshot & diffing

---Return all current `:messages` lines as a list, or an empty list on error.
---Empty history yields `{}`, not `{ "" }` (vim.split on "") -- avoids a blank first line.
---@return string[]
local function get_messages()
  local ok, out = pcall(vim.api.nvim_exec2, "messages", { output = true })
  if not ok or not out.output or out.output == "" then return {} end
  return vim.split(out.output, "\n", { plain = true })
end

---Count how many trailing lines of `prev` also lead `curr`.
---Resyncs the diff after the `:messages` history rolls over (it is a 500-line ring)
---or is cleared, where a plain line-count delta would stop detecting new entries.
---@param prev string[]
---@param curr string[]
---@return integer
local function tail_overlap(prev, curr)
  local max_k = math.min(#prev, #curr)
  for k = max_k, 1, -1 do
    local matches = true
    for i = 1, k do
      if prev[#prev - k + i] ~= curr[i] then
        matches = false
        break
      end
    end
    if matches then return k end
  end
  return 0
end

-- -------------------------------------------------------
-- Buffer / window view helpers

---Return true when the window cursor rests on the trailing sentinel line.
---The sentinel is the buffer's last line; resting on it means the user is caught up.
---@param winid integer
---@return boolean
local function at_bottom(winid)
  local cursor_row = vim.api.nvim_win_get_cursor(winid)[1] -- 1-indexed
  return cursor_row >= vim.api.nvim_buf_line_count(state.bufnr)
end

---Schedule a statusline redraw when the live window is visible.
local function redraw_statusline()
  if state.winid and vim.api.nvim_win_is_valid(state.winid) then
    vim.cmd.redrawstatus()
  end
end

---Clear the pending virt-text.
local function clear_pending_virt()
  if not vim.api.nvim_buf_is_valid(state.bufnr) then return end
  vim.api.nvim_buf_clear_namespace(state.bufnr, state.ns_pending, 0, -1)
end

---Move the window cursor onto the sentinel line and drop the pending notice.
---@param winid integer
local function follow_bottom(winid)
  local line_count = vim.api.nvim_buf_line_count(state.bufnr)
  vim.api.nvim_win_set_cursor(winid, { line_count, 0 })
  state.pending_count = 0
  clear_pending_virt()
  redraw_statusline()
end

---Show a "+N new" virt-text at EOL of the cursor line in the live-messages win.
---@param n integer
local function show_pending_virt(n)
  if not (state.winid and vim.api.nvim_win_is_valid(state.winid)) then return end
  local cursor_row = vim.api.nvim_win_get_cursor(state.winid)[1] - 1 -- 0-indexed
  vim.api.nvim_buf_clear_namespace(state.bufnr, state.ns_pending, 0, -1)
  vim.api.nvim_buf_set_extmark(state.bufnr, state.ns_pending, cursor_row, 0, {
    virt_text = { { string.format("  +%d new", n), PENDING_HL } },
    virt_text_pos = "eol",
    invalidate = true,
  })
end

---Build the window statusline: total messages, pending, and since-last-marker count.
---@return string
function M.get_statusline()
  local parts = { string.format("live-messages  %d msgs", state.msg_count) }
  if state.pending_count > 0 then
    parts[#parts + 1] = string.format("+%d new", state.pending_count)
  end
  if state.has_marker then
    parts[#parts + 1] = string.format("%d since marker", state.new_since_marker)
  end
  return " " .. table.concat(parts, " · ") .. " "
end

-- -------------------------------------------------------
-- Timer lifecycle

-- Forward declarations: stop_timer and poll are defined in different sections but
-- reference each other (start_timer wraps poll; poll stops the timer on a dead buffer).
local stop_timer
local poll

---Stop and release the diff/poll timer.
function stop_timer()
  if not state.timer then return end
  state.timer:stop()
  state.timer:close()
  state.timer = nil
end

---Start the diff/poll timer if it is not already running.
local function start_timer()
  if state.timer then return end
  state.timer = vim.uv.new_timer()
  state.timer:start(0, POLL_INTERVAL_MS, vim.schedule_wrap(poll))
end

-- -------------------------------------------------------
-- Buffer & polling

---Create the scratch buffer, its sentinel line, and its buffer-local autocmds.
---The buffer is reused across window openings; `on_attach` runs once from `actions.open`.
local function ensure_buffer()
  if vim.api.nvim_buf_is_valid(state.bufnr) then return end
  state.bufnr = vim.api.nvim_create_buf(false, true)
  -- A fresh buffer restarts tracking from the current history snapshot.
  state.prev = {}
  state.msg_count = 0
  state.has_marker = false
  state.new_since_marker = 0
  state.pending_count = 0
  state.attached = false
  -- The trailing sentinel line: new messages are inserted before it, and the cursor
  -- resting on it means the user is caught up.
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, { "" })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = state.bufnr })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = state.bufnr })
  -- Set filetype last so user FileType autocmds can still override buffer settings.
  vim.api.nvim_set_option_value("filetype", "livemessages", { buf = state.bufnr })

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = augroup,
    buffer = state.bufnr,
    callback = function()
      if state.pending_count == 0 then return end
      local winid = vim.api.nvim_get_current_win()
      if winid ~= state.winid or not at_bottom(winid) then return end
      state.pending_count = 0
      clear_pending_virt()
      redraw_statusline()
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = augroup,
    buffer = state.bufnr,
    callback = function()
      stop_timer()
      state.bufnr = -1
      state.winid = nil
      state.prev = {}
      state.msg_count = 0
      state.has_marker = false
      state.new_since_marker = 0
      state.pending_count = 0
      state.attached = false
    end,
  })
end

---Append any new `:messages` lines before the sentinel; follow or show a pending notice.
function poll()
  if not vim.api.nvim_buf_is_valid(state.bufnr) then
    stop_timer()
    return
  end
  local msgs = get_messages()
  local overlap = tail_overlap(state.prev, msgs)
  local new_lines = vim.list_slice(msgs, overlap + 1, #msgs)
  -- Snapshot before the early return so view state stays current while idle.
  state.prev = msgs
  if #new_lines == 0 then return end

  state.msg_count = state.msg_count + #new_lines
  if state.has_marker then
    state.new_since_marker = state.new_since_marker + #new_lines
  end

  local sentinel_row = vim.api.nvim_buf_line_count(state.bufnr) - 1 -- 0-indexed
  vim.api.nvim_buf_set_lines(state.bufnr, sentinel_row, sentinel_row, false, new_lines)

  -- The window may have been closed or repurposed for another buffer since last poll.
  if state.winid and not vim.api.nvim_win_is_valid(state.winid) then
    state.winid = nil
  end
  local winid = state.winid
  if winid and vim.api.nvim_win_get_buf(winid) ~= state.bufnr then
    state.winid = nil
    winid = nil
  end

  if winid then
    if at_bottom(winid) then
      -- Already on the sentinel: follow new output, drop any pending notice.
      follow_bottom(winid)
    else
      -- Reading history: accumulate and show the pending notice instead.
      state.pending_count = state.pending_count + #new_lines
      show_pending_virt(state.pending_count)
      redraw_statusline()
    end
  else
    -- Window closed or repurposed without a WinClosed event: stop mirroring.
    stop_timer()
  end
end

---Apply the configured window options to the live window.
---@param winid integer
local function apply_window_options(winid)
  for option_name, value in pairs(config.window_options) do
    vim.api.nvim_set_option_value(option_name, value, { win = winid })
  end
end

---Set the live window's local 'statusline' unless config.window_options overrides it.
---@param winid integer
local function set_window_statusline(winid)
  if config.window_options.statusline ~= nil then return end
  vim.api.nvim_set_option_value("statusline", "%{v:lua.__live_messages_statusline()}", { win = winid })
end

-- -------------------------------------------------------
-- Actions

---Insert a timestamped, highlighted marker line above the cursor in the live buffer.
---No-op unless the current buffer is the live-messages buffer.
---@param label string|nil Marker text; empty/nil falls back to "note".
function M.actions.mark(label)
  if not vim.api.nvim_buf_is_valid(state.bufnr) then return end
  if vim.api.nvim_get_current_buf() ~= state.bufnr then return end
  label = (label and label ~= "") and label or "note"
  local marker = string.format("%s [%s] %s %s", MARKER_PREFIX, os.date("%H:%M:%S"), label, MARKER_PREFIX)
  -- Insert before the cursor line so the marker sits above it.
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
  vim.api.nvim_buf_set_lines(state.bufnr, row, row, false, { marker })
  state.has_marker = true
  state.new_since_marker = 0
  -- Dedicated namespace: ns_pending is cleared wholesale as the notice moves.
  vim.api.nvim_buf_set_extmark(state.bufnr, state.ns_mark, row, 0, {
    line_hl_group = MARKER_HL,
  })
  redraw_statusline()
end

---Move the cursor to the next marker line in the live buffer.
function M.actions.goto_next_marker()
  vim.fn.search("^" .. MARKER_PREFIX, "W")
end

---Move the cursor to the previous marker line in the live buffer.
function M.actions.goto_prev_marker()
  vim.fn.search("^" .. MARKER_PREFIX, "bW")
end

---Open (or focus) the live-messages split and start polling.
---@param opts? vim.api.keyset.create_user_command.command_args  Command opts (uses `smods`).
function M.actions.open(opts)
  opts = opts or {}
  ensure_buffer()

  local winid = state.winid
  if winid and vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == state.bufnr then
    -- Reuse an already-open live-messages window instead of stacking splits.
    vim.api.nvim_set_current_win(winid)
  else
    -- Default to the configured split; honour user-supplied modifiers (:horiz, :vert, ...).
    local smods = vim.deepcopy(opts.smods or {})
    if not smods.vertical and not smods.horizontal then
      smods.vertical = config.default_split == "vertical"
      smods.horizontal = config.default_split == "horizontal"
    end
    vim.api.nvim_cmd({ cmd = "split", mods = smods }, {})

    winid = vim.api.nvim_get_current_win()
    state.winid = winid
    vim.api.nvim_win_set_buf(winid, state.bufnr)

    vim.api.nvim_create_autocmd("WinClosed", {
      group = augroup,
      pattern = tostring(winid),
      once = true,
      callback = function()
        stop_timer()
        state.winid = nil
      end,
    })
  end

  apply_window_options(winid)
  set_window_statusline(winid)

  -- Run once, with the live buffer current, so buffer-local maps target it.
  if not state.attached then
    state.attached = true
    config.on_attach { bufnr = state.bufnr }
  end

  follow_bottom(winid)
  start_timer()
end

-- -------------------------------------------------------
-- Config

---Merge user options over the defaults.
---@param given_config? LiveMessages.Opts.UserConfig
function M.setup(given_config)
  config = vim.tbl_deep_extend("force", M.default_config, given_config or {})
end

---Return a copy of the resolved config.
---@return LiveMessages.Config
function M.get_config()
  return vim.deepcopy(config)
end

return M
