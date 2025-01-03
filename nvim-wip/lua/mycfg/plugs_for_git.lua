local PluginSystem = require"mylib.plugin_system"
local Plug = PluginSystem.MasterDeclarator:get_anonymous_plugin_declarator()
local NamedPlug = PluginSystem.MasterDeclarator:get_named_plugin_declarator()

-- Shorter vars for easy/non-bloat use in pkg specs!
local t = PluginSystem.predefined_tags
local gh = PluginSystem.sources.github


NamedPlug.fugitive {
  source = gh"tpope/vim-fugitive",
  desc = "A Git wrapper so awesome, it should be illegal",
  tags = {t.vimscript, t.git},
  defer_load = { on_event = "VeryLazy" },
}
Plug {
  -- TODO: switch to https://github.com/rbong/vim-flog
  source = gh"junegunn/gv.vim",
  depends_on = { NamedPlug.fugitive },
  desc = "Simple (<3) git commit browser, based on vim-fugitive",
  tags = {t.vimscript, t.git},
  defer_load = { on_event = "VeryLazy" },
}
Plug {
  source = gh"whiteinge/diffconflicts",
  -- Use this cmd as mergetool:
  --   nvim -c DiffConflictsWithHistory "$MERGED" "$BASE" "$LOCAL" "$REMOTE"
  desc = "Helper plugin for git merges",
  tags = {t.vimscript, t.git, t.ui},
  defer_load = {
    on_event = "VeryLazy",
    on_cmd = "DiffConflictsWithHistory",
  },
}

Plug {
  source = gh"rhysd/git-messenger.vim",
  desc = "Popup the commit message of the line under cursor",
  tags = {t.vimscript, t.git, t.ui},
  on_pre_load = function()
    vim.g.git_messenger_no_default_mappings = true
  end,
  defer_load = { on_event = "VeryLazy" },
}

Plug {
  source = gh"lewis6991/gitsigns.nvim",
  desc = "Git integration for buffers",
  tags = {t.content_ui, t.git},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    require"gitsigns".setup{
      signs = {
        add          = { text = "┃" },
        change       = { text = "┃" },
        delete       = { text = "▁" },
        changedelete = { text = "▁" }, -- like delete, but with different highlight
        topdelete    = { text = "▔" },
        untracked    = { text = '┆' },
      },
      attach_to_untracked = true,
      preview_config = { border = "none" },
    }
    vim.api.nvim_set_hl(0, "GitSignsAdd",          { link = "SignVcsAdd" })
    vim.api.nvim_set_hl(0, "GitSignsChange",       { link = "SignVcsChange" })
    vim.api.nvim_set_hl(0, "GitSignsDelete",       { link = "SignVcsDelete" })
    vim.api.nvim_set_hl(0, "GitSignsChangedelete", { link = "SignVcsChange" })
    vim.api.nvim_set_hl(0, "GitSignsTopdelete",    { link = "SignVcsDelete" })
    vim.api.nvim_set_hl(0, "GitSignsUntracked",    { link = "SignVcsUntracked" })

    -- FIXME: use 'on_attach' to config keybinds?

    -- define these globally for now.. (until good solution for per-buffer which_key helper)
    local_leader_map_define_group{mode={"n"}, prefix_key="h", name="+hunks"}
    local_leader_map_define_group{mode={"n"}, prefix_key="H", name="__hide__"}
    -- NOTE: 'H' group exists to make 'HN' spam-able by holding shift

    local gs = require"gitsigns"
    local_leader_map{mode={"n"}, key="hp", action=gs.preview_hunk, desc="preview hunk"}
    local_leader_map{mode={"n"}, key="hu", action=gs.reset_hunk,   desc="undo (reset) hunk"}
    local_leader_map{mode={"n"}, key="hD", action=gs.diffthis,     desc="diff file"}
    -- FIXME: there is no action to toggle fold of everything that didn't change
    -- local_leader_map{mode={"n"}, key="hf", action=gs.fold_unchanged, desc="fold unchanged lines"}

    -- next/prev hunk that also work in vim's diff mode
    my_actions.go_next_changed_hunk = mk_action_v2 {
      default_desc = "Goto next changed hunk",
      n = function()
        if vim.wo.diff then
          vim.cmd.normal({']c', bang = true})
        else
          gs.nav_hunk('next')
        end
      end,
    }
    my_actions.go_prev_changed_hunk = mk_action_v2 {
      default_desc = "Goto prev changed hunk",
      n = function()
        if vim.wo.diff then
          vim.cmd.normal({'[c', bang = true})
        else
          gs.nav_hunk('prev')
        end
      end,
    }
    local_leader_map{mode={"n"}, key="hn", action=my_actions.go_next_changed_hunk}
    local_leader_map{mode={"n"}, key="hN", action=my_actions.go_prev_changed_hunk}
    -- also map HN so I can 'spam' the letters easily :)
    local_leader_map{mode={"n"}, key="HN", action=my_actions.go_prev_changed_hunk}

    -- TODO: move closer to git-messenger plugin? Should simply add to a 'git' keymap.
    local_leader_map{mode={"n"}, key="hb", action="<Plug>(git-messenger)", desc="blame someone"}

    -- toggles
    local_leader_map_define_group{mode={"n"}, prefix_key="ht", name="+toggle"}
    local_leader_map{mode={"n"}, key="htw", action=gs.toggle_word_diff,          desc="toggle word diff"}
    local_leader_map{mode={"n"}, key="htd", action=gs.toggle_deleted,            desc="toggle deleted lines"}
    local_leader_map{mode={"n"}, key="htb", action=gs.toggle_current_line_blame, desc="toggle blame lens"}

    -- define hunk text object & visual selector
    toplevel_map{mode={"o", "v"}, key="ih", action=gs.select_hunk, desc="select hunk"}
    toplevel_map{mode={"o", "v"}, key="ah", action=gs.select_hunk, desc="select hunk"}
  end,
}

Plug {
  source = gh"sindrets/diffview.nvim",
  desc = "Single tabpage interface for easily cycling through diffs for all modified files for any git revs",
  tags = {t.ui, t.git},
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    -- FIXME: anything to do here?
    require"diffview".setup {
      default_args = {    -- Default args prepended to the arg-list for the listed commands
        DiffviewOpen = {"--untracked-files=false", "--imply-local"},
      },
      view = {
        default = { winbar_info = true },
        file_history = { winbar_info = true },
      },
      keymaps = {
        -- NOTE: use `g?` in any view to get help panel
        -- disable_defaults = true, -- (?) (there are a lot...)
      }
    }
  end
}
