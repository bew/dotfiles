local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.editing },
}

local K = require"mylib.keymap_system"
local A = require"mylib.action_system"

--------------------------------

Plug {
  source = gh"jake-stewart/multicursor.nvim",
  desc = "Multiple cursors in Neovim which work how you expect",
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    local mc = require"multicursor-nvim"
    mc.setup {
      -- Don't disable hlsearch on cursor actions 🙏
      -- ref: https://github.com/jake-stewart/multicursor.nvim/issues/118
      hlsearch = true,
    }

    K.toplevel_map_define_group{mode={"n", "v"}, prefix_key="<M-Space>", name="+multicursor"}

    -- Add or skip cursor above/below the main cursor.
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-j>", desc="Add cursor, jump down",  action=function() mc.lineAddCursor(1) end}
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-k>", desc="Add cursor, jump up",    action=function() mc.lineAddCursor(-1) end}
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-J>", desc="Skip cursor, jump down", action=function() mc.lineSkipCursor(1) end}
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-K>", desc="Skip cursor, jump up",   action=function() mc.lineSkipCursor(-1) end}

    --- Search/Match action around main cursor
    ---@param opts {dir?: "prev"|"next", match_fn: fun(dir?: integer), search_fn: fun(dir?: integer)}
    local function search_or_match_cursor_action(opts)
      ---@type integer?
      local dir = ({next = 1, prev = -1})[opts.dir]
      local has_selection = vim.tbl_contains({"v", "V", ""}, vim.fn.mode())
      local has_active_search = vim.v.hlsearch == 1 and vim.fn.searchcount().total > 0
      -- FIXME: how to handle when there are non-visible matches?
      --   (e.g. after switching to a different file and wishing to use current word matching..)

      if has_selection then
        -- We have active visual selection, use it to find matches
        opts.match_fn(dir)
      elseif has_active_search then
        -- We have an active search, use search results
        opts.search_fn(dir)
      else
        -- Otherwise use current word to find matches
        opts.match_fn(dir)
      end
    end

    -- Add or skip adding a new cursor by matching word/selection or search results
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-n>", desc="Add cursor, jump next match", action=function()
      search_or_match_cursor_action {
        dir = "next",
        match_fn = mc.matchAddCursor,
        search_fn = mc.searchAddCursor,
      }
    end}
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-p>", desc="Add cursor, jump prev match", action=function()
      search_or_match_cursor_action {
        dir = "prev",
        match_fn = mc.matchAddCursor,
        search_fn = mc.searchAddCursor,
      }
    end}
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-N>", desc="Skip cursor, jump next match", action=function()
      search_or_match_cursor_action {
        dir = "next",
        match_fn = mc.matchSkipCursor,
        search_fn = mc.searchSkipCursor,
      }
    end}
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-P>", desc="Skip cursor, jump prev match", action=function()
      search_or_match_cursor_action {
        dir = "prev",
        match_fn = mc.matchSkipCursor,
        search_fn = mc.searchSkipCursor,
      }
    end}

    -- Add a cursor for all matches of cursor word/selection in the document.
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><C-a>", desc="Add cursors for all matches/search-results", action=function()
      search_or_match_cursor_action {
        match_fn = mc.matchAllAddCursors,
        search_fn = mc.searchAllAddCursors,
      }
    end}
    -- (easy to spam!)
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-*>", desc="Add cursors for all matches", action=mc.matchAllAddCursors}

    -- Add cursors for all regex results within visual selection(s)
    K.toplevel_map{mode="v", key="<M-Space><M-/>", desc="Add cursors by regex in selection(s)", action=mc.matchCursors}
    K.toplevel_map{mode="v", key="<M-Space>/",     desc="Add cursors by regex in selection(s)", action=mc.matchCursors}
    K.toplevel_map{mode="v", key="<M-Space><M-m>", desc="Add cursors by regex in selection(s)", action=mc.matchCursors}

    -- Add and remove cursors with Alt + left click (note: drag seems to only work vertically)
    K.toplevel_map{mode="n", key="<M-LeftMouse>",   action=mc.handleMouse}
    K.toplevel_map{mode="n", key="<M-LeftDrag>",    action=mc.handleMouseDrag}
    K.toplevel_map{mode="n", key="<M-LeftRelease>", action=mc.handleMouseRelease}

    -- Toggle actions
    my_actions.mc_toggle_enable_cursors = A.mk_action {
      default_desc = "Enable/Disable cursors",
      [{"n", "v"}] = function()
        if mc.cursorsEnabled() then
          mc.disableCursors()
        else
          mc.enableCursors()
        end
      end,
    }
    -- When cursors are disabled, toggle cursor under the main cursor.
    -- Otherwise, disables all cursors (only the main cursor moves).
    -- They'll need to be re-enabled before doing any multi-cursors edits.
    K.toplevel_map{mode="n", key="<M-Space><M-Space>", desc="Toggle cursor here", action=mc.toggleCursor}
    -- Disable / Re-enable cursors
    -- (note: setting up few mappings, not sure which one I'll prefer in practice 🤔)
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-t>",     action=my_actions.mc_toggle_enable_cursors}
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><Space>",   action=my_actions.mc_toggle_enable_cursors}
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><C-Space>", action=my_actions.mc_toggle_enable_cursors}

    my_actions.mc_clear_all_cursors = A.mk_action {
      default_desc = "Clear all cursors",
      [{"n", "v"}] = function()
        mc.clearCursors()
      end,
    }

    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-q>",   action=my_actions.mc_clear_all_cursors}
    K.toplevel_map{mode={"n", "v"}, key="<M-Space><M-Esc>", action=my_actions.mc_clear_all_cursors}

    -- Same as visual block's I/A, but also works in visual line mode
    K.toplevel_map{mode="v", key="<M-Space>I", desc="Insert for all lines of selection", action=mc.insertVisual}
    K.toplevel_map{mode="v", key="<M-Space>A", desc="Append for all lines of selection", action=mc.appendVisual}

    -- Mappings defined in a keymap layer only apply when there are
    -- multiple cursors. This lets you have overlapping mappings.
    mc.addKeymapLayer(function(layer_map)
      -- Select a different cursor as the main one
      layer_map({"n", "x"}, "<left>",  mc.prevCursor, { desc = "Select prev cursor" })
      layer_map({"n", "x"}, "<right>", mc.nextCursor, { desc = "Select next cursor" })
      layer_map({"n", "x"}, "<M-c>",   mc.nextCursor, { desc = "Cycle cursors" })

      layer_map({"n", "x"}, "<M-Space><M-g>", mc.firstCursor, { desc = "Select first(top) cursor" })
      layer_map({"n", "x"}, "<M-Space><M-G>", mc.lastCursor,  { desc = "Select last(bottom) cursor" })

      -- Delete the main cursor
      layer_map({"n", "x"}, "<M-Space><M-x>", mc.deleteCursor, { desc = "Delete main cursor, jump to last" })

      -- Increment/decrement sequences, treating all cursors as one sequence
      layer_map({"n", "x"}, "g<C-a>", mc.sequenceIncrement)
      layer_map({"n", "x"}, "g<C-x>", mc.sequenceDecrement)
    end)

    K.toplevel_map{mode={"n", "v"}, key="<M-Space><C-d>", desc="Clone cursors, disable originals", action=mc.duplicateCursors}
    K.toplevel_map{mode="n", key="<M-Space><M-u>", desc="Restore cursors (after clear)", action=mc.restoreCursors}
    K.toplevel_map{mode="n", key="<M-Space><M-=>", desc="Align cursor columns", action=mc.alignCursors}

    K.toplevel_map_define_group{mode={"n", "v"}, prefix_key="<M-Space><M-s>", name="+split"}
    K.toplevel_map{mode="v", key="<M-Space><M-s><M-s>", desc="Split by lines", action=mc.visualToCursors}
    K.toplevel_map{mode="v", key="<M-Space><M-s><M-x>", desc="Split by regex", action=mc.splitCursors}

    -- -- Pressing `<leader>miwap` will create a cursor in every match of the
    -- -- string captured by `iw` inside range `ap`.
    -- -- This action is highly customizable, see `:h multicursor-operator`.
    -- toplevel_map{mode={"n", "v"}, key="<leader>m", desc="WHAT", action=mc.operator}

  end,
  on_colorscheme_change = function()
    -- NOTE: Colors are _reversed_ to ensure the extmarks stay visible over search result highlights
    -- ISSUE: https://github.com/neovim/neovim/issues/18756#issuecomment-2833479559
    vim.api.nvim_set_hl(0, "MultiCursorCursor", {
      bold = true,
      reverse = true,
      ctermfg = 88,
      ctermbg = 248,
    })
    vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", {
      bold = true,
      reverse = true,
      ctermfg = 238,
      ctermbg = 248,
    })
    vim.api.nvim_set_hl(0, "MultiCursorVisual", { ctermbg = 52 })
    vim.api.nvim_set_hl(0, "MultiCursorDisabledVisual", { ctermbg = 236 })
  end,
}
