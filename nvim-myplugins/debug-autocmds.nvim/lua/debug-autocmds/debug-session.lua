local get_current_time = vim.loop.now

-- FIXME(typing): how to do multiline description / line continuation in @field docs?
-- FIXME(typing): where can I put the EventSpec dataclass declaration, to be used in other Lua files?

---@class DebugSession
---@field active boolean Whether the session is currently active and recording events
---@field name string The name of the session
---@field time_on_start integer? Monotonic time in millisecond from session' first start
---@field event_nr integer The event number of the last recorded event (0 when never started)
---@field augroup integer Vim's augroup for all autocmds (used to clear them all at once by clearing the group)
---@field events_to_watch {[string]: EventSpec} Table of event specs to watch when starting the session
---@field recorded_events EventRecord[] List of recorded events in this session
local DebugSession = {}

---@class EventRecord
---@field name string
---@field event_nr integer The number of the event in the session
---@field time_from_start integer The number of milliseconds from the start of session recording
---@field raw table The raw event data (without 'group')
---@field extra EventRecordExtraContext Additional extra context for each event

---@class EventRecordExtraContext
---@field tabnr integer The tab number
---@field winnr integer The window number (unique in the tab)
---@field winid integer The window ID (unique)

function DebugSession.new(opts)
  local opts = opts or {}
  vim.validate{ name = {opts.name, "string", false} }
  ---@type DebugSession
  local instance = {
    active = false,
    name = opts.name,
    time_on_start = get_current_time(),
    event_nr = 0,
    augroup = vim.api.nvim_create_augroup("debug-autocmds--session-"..opts.name, {clear=true}),
    events_to_watch = {},
    recorded_events = {},
  }
  return setmetatable(instance, {
    __index = DebugSession,
    __gc = DebugSession.stop, -- last resort to clear handlers
  })
end

---@param event_or_events EventSpec[]|EventSpec
function DebugSession:add_events_to_watch(event_or_events)
  local event_specs = event_or_events
  if not vim.tbl_islist(event_or_events) then event_specs = {event_or_events} end
  for _, event_spec in ipairs(event_specs) do
    self.events_to_watch[event_spec.name] = event_spec
  end

  if self.active then
    -- to avoid having to compute delta of events to add/remove,
    -- we simply remove all existing handlers and register all events.
    self:stop()
    self:start()
  end
end

function DebugSession:start()
  self.active = true
  if self.time_on_start == nil then
    -- Time of first start (only)
    self.time_on_start = get_current_time()
  end

  -- Setup all autocmds
  for _, spec in pairs(self.events_to_watch) do
    vim.api.nvim_create_autocmd(spec.name, {
      group = self.augroup,
      callback = function(event_data)
        self:record_event(event_data)
      end,
    })
  end
end

function DebugSession:start_with_events(event_specs)
  self:add_events_to_watch(event_specs)
  self:start()
end

function DebugSession:stop()
  self.active = false
  -- remove all event handlers by clearing the autocmd group
  vim.api.nvim_clear_autocmds({ group = self.augroup })
end

function DebugSession:record_event(event_data)
  if not self.active then return end
  self.event_nr = self.event_nr + 1
  local time_now = get_current_time()

  -- Remove some useless data fields
  event_data.group = nil -- the augroup, specific to session
  -- IDEA: also remove the event name? we already put it in the EventRecord
  -- I'm thinking that actually removing things from event_data is wrong as we store it in the 'raw'
  -- key in the EventRecord.. It's not really 'raw' if we remove things...

  ---@type EventRecord
  local event_record = {
    name = event_data.event --[[@as string]],
    event_nr = self.event_nr,
    time_from_start = time_now - self.time_on_start,
    raw = event_data,
    extra = {
      -- fields here MAY not always be filled with a valid value (FIXME: is this true?)
      tabnr = vim.fn.tabpagenr(),
      winnr = vim.fn.winnr(),
      winid = vim.fn.win_getid(vim.fn.winnr(), vim.fn.tabpagenr())
    },
  }
  table.insert(self.recorded_events, event_record)
end

---@param display_fn fun(record: EventRecord): nil
function DebugSession:dump_with(display_fn)
  for _, event_record in ipairs(self.recorded_events) do
    display_fn(event_record)
  end
end

local function make_record_matcher_fn(matcher_spec)
  local individual_specs = vim.split(matcher_spec, ",")
  return function(event_record)
    local event_name = event_record.name:lower()
    local file_name = event_record.raw.file:lower()
    for _, spec in ipairs(individual_specs) do
      if event_name:match(spec) then
        return true
      end
      if vim.startswith(spec, "file:") and file_name:match(spec) then
        return true
      end
    end
    return false
  end
end

---@param matcher_spec string A string representing what event records to match and pass to `display_fn`.
---    Note that the event name or file name are lowercased before matching
---
---    Syntax: comma-separated list of either:
---    `foo` to match any part of an event name
---    `file:foo` to match any part of the file name of an event
---
---    Example: buf,winenter,file:foo
---    This will match the events including 'buf', the events WinEnter, and the events with
---    file name including 'foo'
---@param display_fn fun(record: EventRecord): nil
function DebugSession:dump_matching_with(matcher_spec, display_fn)
  local matcher_fn = make_record_matcher_fn(matcher_spec)
  for _, event_record in ipairs(self.recorded_events) do
    if matcher_fn(event_record) then
      display_fn(event_record)
    end
  end
end

return setmetatable(DebugSession, {
  __call = function(_, ...)
    return DebugSession.new(...)
  end,
})
