local Utils = require"debug-autocmds.utils"

---@type debug_aucmd.EventSpec[]
local builtin_events = Utils.normalize_event_specs({
  "BufAdd",
  "BufDelete",
  "BufEnter",
  "BufFilePost",
  "BufFilePre",
  "BufHidden",
  "BufLeave",
  "BufModifiedSet",
  "BufNew",
  "BufNewFile",
  "BufRead",
  "BufReadPost",
  -- "BufReadCmd", -- don't want to re-impl the action!
  "BufReadPre",
  "BufUnload",
  "BufWinEnter",
  "BufWinLeave",
  "BufWipeout",
  "BufWrite",
  "BufWritePre",
  -- "BufWriteCmd", -- don't want to re-impl the action!
  "BufWritePost",

  { "ChanInfo", tags = {"channel"} },
  { "ChanOpen", tags = {"channel"} },

  "CmdUndefined",
  "CmdlineChanged",
  "CmdlineEnter",
  "CmdlineLeave",
  "CmdwinEnter",
  "CmdwinLeave",

  { "ColorScheme", tags = {"ui"} },
  { "ColorSchemePre", tags = {"ui"} },

  { "CompleteChanged", tags = {"edit"} },
  { "CompleteDonePre", tags = {"edit"} },
  { "CompleteDone", tags = {"edit"} },

  "CursorHold",
  { "CursorHoldI", tags = {"edit", "insert"} },
  "CursorMoved",
  { "CursorMovedI", tags = {"edit", "insert"} },

  { "DiffUpdated", tags = {"edit"} },

  { "DirChanged", tags = {"fs"} },
  { "DirChangedPre", tags = {"fs"} },

  { "ExitPre", tags = {"vim"} },

  -- "FileAppendCmd", -- don't want to re-impl the action!
  "FileAppendPost",
  "FileAppendPre",
  "FileChangedRO",
  "FileChangedShell",
  "FileChangedShellPost",
  "FileReadCmd", -- don't want to re-impl the action!
  "FileReadPost",
  "FileReadPre",
  "FileType",
  -- "FileWriteCmd", -- don't want to re-impl the action!
  "FileWritePost",
  "FileWritePre",

  "FilterReadPost",
  "FilterReadPre",
  "FilterWritePost",
  "FilterWritePre",

  { "FocusGained", tags = {"vim"} },
  { "FocusLost", tags = {"vim"} },

  "FuncUndefined",

  "UIEnter",
  "UILeave",

  "InsertChange",
  "InsertCharPre",
  "InsertEnter",
  "InsertLeavePre",
  "InsertLeave",

  { "MenuPopup", tags = {"ui"} },

  "ModeChanged",

  "OptionSet",

  "QuickFixCmdPre",
  "QuickFixCmdPost",

  { "QuitPre", tags = {"vim"} },

  "RemoteReply",

  "SearchWrapped",

  "RecordingEnter",
  "RecordingLeave",

  "SessionLoadPost",

  "ShellCmdPost",

  "Signal",

  "ShellFilterPost",

  "SourcePre",
  "SourcePost",
  -- "SourceCmd", -- don't want to re-impl the action!

  "SpellFileMissing",

  "StdinReadPost",
  "StdinReadPre",

  { "SwapExists", tags = {"fs", "edit"} },

  "Syntax",

  "TabEnter",
  "TabLeave",
  "TabNew",
  "TabNewEntered",
  "TabClosed",

  "TermOpen",
  "TermEnter",
  "TermLeave",
  "TermClose",
  "TermResponse",

  { "TextChanged", tags = {"edit"} },
  { "TextChangedI", tags = {"edit"} },
  { "TextChangedP", tags = {"edit"} },
  "TextYankPost",

  "User",

  "VimEnter",
  "VimLeave",
  "VimLeavePre",
  "VimResized",
  "VimResume",
  "VimSuspend",

  "WinClosed",
  "WinEnter",
  "WinLeave",
  "WinNew",
  "WinScrolled",
})

-- Remove events that end with 'Cmd', when they are defined, the handler must
-- implement the action.
-- For example, the handler of 'BufReadCmd' would need to actually read the file
-- in some way and fill the buffer with lines. See `:h Cmd-event` for more info.
--
-- Since we don't want to re-implement all actions, we remove them from the list
-- to ensure we never register a handle for them.
builtin_events = vim.tbl_filter(
  -- keep events that do NOT end with 'Cmd'
  function(event_spec) return not vim.endswith(event_spec.name, "Cmd") end,
  builtin_events
)

return builtin_events
