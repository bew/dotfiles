local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.editing },
}

--------------------------------

Plug {
  source = gh"jake-stewart/multicursor.nvim",
  desc = "Multiple cursors in Neovim which work how you expect",
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    local mc = require"multicursor-nvim"
    mc.setup()

    toplevel_map_define_group{mode={"n", "v"}, prefix_key="<M-Space>", name="+multicursor"}

    -- Add or skip cursor above/below the main cursor.
    toplevel_map{mode={"n", "v"}, key="<M-Space><M-j>", desc="Add cursor, jump down", action=function() mc.lineAddCursor(1) end}
    toplevel_map{mode={"n", "v"}, key="<M-Space><M-k>", desc="Add cursor, jump up", action=function() mc.lineAddCursor(-1) end}
    toplevel_map{mode={"n", "v"}, key="<M-Space><M-J>", desc="Skip cursor, jump down", action=function() mc.lineSkipCursor(1) end}
    toplevel_map{mode={"n", "v"}, key="<M-Space><M-K>", desc="Skip cursor, jump up", action=function() mc.lineSkipCursor(-1) end}

    --- Search/Match action around main cursor
    ---@param opts {dir?: "prev"|"next", match_fn: fun(dir?: integer), search_fn: fun(dir?: integer)}
    local function search_or_match_cursor_action(opts)
      ---@type integer?
      local dir = ({next = 1, prev = -1})[opts.dir]
      if vim.v.hlsearch == 1 then
        -- We have an active search, use search results
        opts.search_fn(dir)
      else
        -- Otherwise use current selection or current word to find matches
        opts.match_fn(dir)
      end
    end

    -- Add or skip adding a new cursor by matching word/selection or search results
    toplevel_map{mode={"n", "v"}, key="<M-Space><M-n>", desc="Add cursor, jump next match", action=function()
      search_or_match_cursor_action {
        dir = "next",
        match_fn = mc.matchAddCursor,
        search_fn = mc.searchAddCursor,
      }
    end}
    toplevel_map{mode={"n", "v"}, key="<M-Space><M-p>", desc="Add cursor, jump prev match", action=function()
      search_or_match_cursor_action {
        dir = "prev",
        match_fn = mc.matchAddCursor,
        search_fn = mc.searchAddCursor,
      }
    end}
    toplevel_map{mode={"n", "v"}, key="<M-Space><M-N>", desc="Skip cursor, jump next match", action=function()
      search_or_match_cursor_action {
        dir = "next",
        match_fn = mc.matchSkipCursor,
        search_fn = mc.searchSkipCursor,
      }
    end}
    toplevel_map{mode={"n", "v"}, key="<M-Space><M-P>", desc="Skip cursor, jump prev match", action=function()
      search_or_match_cursor_action {
        dir = "prev",
        match_fn = mc.matchSkipCursor,
        search_fn = mc.searchSkipCursor,
      }
    end}

    -- Add a cursor for all matches of cursor word/selection in the document.
    toplevel_map{mode={"n", "v"}, key="<M-Space><C-a>", desc="Add cursors for all matches/search-results", action=function()
      search_or_match_cursor_action {
        match_fn = mc.matchAllAddCursors,
        search_fn = mc.searchAllAddCursors,
      }
    end}

    -- Add cursors for all regex results within visual selection(s)
    toplevel_map{mode="v", key="<M-Space><M-/>", desc="Add cursors by regex in selection(s)", action=mc.matchCursors}
    toplevel_map{mode="v", key="<M-Space>/",     desc="Add cursors by regex in selection(s)", action=mc.matchCursors}

    -- Add and remove cursors with Alt + left click.
    toplevel_map{mode="n", key="<M-LeftMouse>",   action=mc.handleMouse}
    toplevel_map{mode="n", key="<M-LeftDrag>",    action=mc.handleMouseDrag}
    toplevel_map{mode="n", key="<M-LeftRelease>", action=mc.handleMouseRelease}

    -- Disable cursors -> only the main cursor moves.
    -- When cursors are disabled, press again to add a cursor under the main cursor.
    toplevel_map{mode="n", key="<M-Space><M-Space>", desc="Toggle cursor here", action=mc.toggleCursor}

    toplevel_map{mode={"n", "v"}, key="<M-Space><M-q>", desc="Enable/Disable cursors", action=function()
      if mc.cursorsEnabled() then
        mc.disableCursors()
      else
        mc.enableCursors()
      end
    end}

    -- Same as visual block's I/A, but also works in visual line mode
    toplevel_map{mode="v", key="<M-Space>I", desc="Insert for all lines of selection", action=mc.insertVisual}
    toplevel_map{mode="v", key="<M-Space>A", desc="Append for all lines of selection", action=mc.appendVisual}

    -- Mappings defined in a keymap layer only apply when there are
    -- multiple cursors. This lets you have overlapping mappings.
    mc.addKeymapLayer(function(mc_map)
      -- Select a different cursor as the main one.
      mc_map({"n", "v"}, "<left>", mc.prevCursor, { desc = "Select prev cursor" })
      mc_map({"n", "v"}, "<right>", mc.nextCursor, { desc = "Select next cursor" })
      mc_map({"n", "v"}, "<M-Space><M-c>", mc.nextCursor, { desc = "Select next cursor" })

      -- Delete the main cursor.
      mc_map({"n", "v"}, "<M-Space><M-x>", mc.deleteCursor, { desc = "Delete main cursor, jump to last" })

      mc_map("n", "<M-Space><M-Esc>", function()
        if mc.hasCursors() then
          mc.clearCursors()
        end
      end, { desc = "Clear cursors" })

      -- Increment/decrement sequences, treating all cursors as one sequence.
      mc_map({"n", "v"}, "g<C-a>", mc.sequenceIncrement)
      mc_map({"n", "v"}, "g<C-x>", mc.sequenceDecrement)
    end)

    toplevel_map{mode={"n", "v"}, key="<M-Space><C-d>", desc="Clone cursors, disable originals", action=mc.duplicateCursors}
    toplevel_map{mode="n", key="<M-Space><M-u>", desc="Restore cursors (after clear)", action=mc.restoreCursors}
    toplevel_map{mode="n", key="<M-Space><M-=>", desc="Align cursor columns", action=mc.alignCursors}

    toplevel_map_define_group{mode={"n", "v"}, prefix_key="<M-Space><M-s>", name="+split"}
    toplevel_map{mode="v", key="<M-Space><M-s><M-s>", desc="Split by lines", action=mc.visualToCursors}
    toplevel_map{mode="v", key="<M-Space><M-s><M-x>", desc="Split by regex", action=mc.splitCursors}

    -- -- Pressing `<leader>miwap` will create a cursor in every match of the
    -- -- string captured by `iw` inside range `ap`.
    -- -- This action is highly customizable, see `:h multicursor-operator`.
    -- toplevel_map{mode={"n", "v"}, key="<leader>m", desc="WHAT", action=mc.operator}

  end,
  on_colorscheme_change = function()
    vim.api.nvim_set_hl(0, "MultiCursorCursor", {
      bold = true,
      ctermbg = 88,
    })
    vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", {
      bold = true,
      ctermbg = 238,
    })
  end,
}
