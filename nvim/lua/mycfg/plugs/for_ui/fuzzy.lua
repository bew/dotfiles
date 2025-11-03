local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
local fallback = PluginSystem.sources.fallback
local dist_managed_opt_plug = PluginSystem.sources.dist_managed_opt_plug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.ui, "nav" },
}

local K = require"mylib.keymap_system"
local U = require"mylib.utils"

--------------------------------

Plug.telescope {
  source = gh"nvim-telescope/telescope.nvim",
  desc = "Find, Filter, Preview, Pick. All lua, all the time…",
  tags = {},
  depends_on = {Plug.lib_plenary},
  config_depends_on = {
    Plug { source = fallback("telescope-fzf", dist_managed_opt_plug"telescope-fzf-native") },
    Plug { source = gh"nvim-telescope/telescope-ui-select.nvim" },
    Plug { source = gh"nvim-telescope/telescope-frecency.nvim" },
    Plug { source = gh"OliverChao/telescope-picker-list.nvim" },
    Plug { source = gh"piersolenski/telescope-import.nvim" },
  },
  defer_load = { on_event = "VeryLazy" },
  on_load = function()
    local tel_actions = require"telescope.actions"
    local tel_actions_lay = require"telescope.actions.layout"
    local action_state = require"telescope.actions.state"

    --- Wrap function to give it a name so it appears in :map as `telescope|<name>`
    ---@param action_name string
    ---@param fn fun(prompt_bufnr: integer): any
    ---@return unknown Telescope action obj
    local wrap_tel_action_fn = function(action_name, fn)
      return require"telescope.actions.mt".transform_mod({[action_name] = fn})[action_name]
    end

    --- Jump to next/previous selected entry
    ---@param prompt_bufnr integer The prompt buffer id
    ---@param direction "next"|"previous"
    local function jump_to_selected(prompt_bufnr, direction)
      -- /!\ Rows are 0-indexed, and `index` is 1 indexed (table index)
      local picker = action_state.get_current_picker(prompt_bufnr)
      local selected_entries = picker:get_multi_selection()
      -- For some reason the list we get is not in order..
      table.sort(selected_entries, function(e1, e2) return e1.index < e2.index end)

      if #selected_entries > 0 then
        local current_index = picker:get_selection_row() + 1 -- (Row is 0-indexed!)
        local target_entry = nil ---@type table?

        if direction == "next" then
          -- Search entry after current index
          for _, entry in ipairs(selected_entries) do
            if entry.index > current_index then
              target_entry = entry
              break
            end
          end
        elseif direction == "previous" then
          -- Search last entry before current index
          for _, entry in ipairs(selected_entries) do
            if entry.index < current_index then
              target_entry = entry
            else
              break
            end
          end
        end

        if target_entry then
          -- Set selection row
          picker:set_selection(target_entry.index - 1) -- (Row is 0-indexed!)
        end
      end
    end

    local function send_all_or_selected_to_qflist(prompt_bufnr)
      local picker = action_state.get_current_picker(prompt_bufnr)
      local selected_entries = picker:get_multi_selection()
      if #selected_entries == 0 then
        -- send all entries
        tel_actions.send_to_qflist(prompt_bufnr)
      else
        -- send only selected entries
        tel_actions.send_selected_to_qflist(prompt_bufnr)
      end
      tel_actions.open_qflist(prompt_bufnr)
    end

    local default_cfg = {}
    -- DEFAULT (my) MAPPINGS
    default_cfg.default_mappings = {} -- disable all default mappings
    -- Available actions:
    -- - https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac/lua/telescope/actions/init.lua
    -- - https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac/lua/telescope/actions/layout.lua
    -- Default mappings:
    -- - https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac/lua/telescope/mappings.lua#L133
    default_cfg.mappings = {n = {}, i = {}}
    -- Telescope doesn't support adding to both modes at the same time
    -- so we'll add common mappings after all others.
    local both_n_i = {
      -- Close on empty prompt
      ["<C-d>"] = wrap_tel_action_fn("my-close-on-empty-prompt", function(prompt_bufnr)
        local prompt = action_state.get_current_line()
        -- print("DEBUG", "prompt text:", vim.inspect(prompt), "len:", #prompt)
        if #prompt == 0 then
          tel_actions.close(prompt_bufnr)
        else
          vim.notify("Cannot close, prompt is not empty")
        end
      end),

      -- N/I: Select actions
      ["<CR>"] = tel_actions.select_default,
      ["<C-j>"] = tel_actions.select_default,
      -- FIXME: multi-selection not handled properly :/
      --   -> All builtin select_* actions use the selected entry instead of
      --   picker:get_multi_selection() 😖
      ["<M-s>"] = tel_actions.select_horizontal,
      ["<M-v>"] = tel_actions.select_vertical,
      ["<M-t>"] = tel_actions.select_tab,

      -- N/I: Move selection
      ["<Down>"] = tel_actions.move_selection_next,
      ["<Up>"] = tel_actions.move_selection_previous,
      ["<C-M-n>"] = function(prompt_bufnr)
        -- jump to next selected entry (useful if multi-selected entries)
        jump_to_selected(prompt_bufnr, "next")
      end,
      ["<C-M-p>"] = function(prompt_bufnr)
        -- jump to previous selected entry (useful if multi-selected entries)
        jump_to_selected(prompt_bufnr, "previous")
      end,

      -- Move selection
      ["<M-j>"] = tel_actions.move_selection_next,
      ["<M-k>"] = tel_actions.move_selection_previous,
      ["<M-g>"] = tel_actions.move_to_top,
      ["<M-G>"] = tel_actions.move_to_bottom,

      -- N/I: Manage multi-selection
      ["<C-a>"] = tel_actions.select_all,
      ["<C-M-a>"] = tel_actions.toggle_all,
      ["<C-c>"] = tel_actions.drop_all,
      ["<M-a>"] = tel_actions.toggle_selection + tel_actions.move_selection_worse,
      ["<M-Space>"] = tel_actions.toggle_selection,

      -- N/I: Results up/down scrolling
      ["<M-J>"] = tel_actions.results_scrolling_down,
      ["<M-K>"] = tel_actions.results_scrolling_up,

      -- N/I: Preview up/down scrolling
      ["<C-M-j>"] = tel_actions.preview_scrolling_down,
      ["<C-M-k>"] = tel_actions.preview_scrolling_up,

      -- N/I: History nav
      ["<C-n>"] = tel_actions.cycle_history_next,
      ["<C-p>"] = tel_actions.cycle_history_prev,

      -- N/I: Integration with quickfix list (send/add)
      ["<M-q>"] = send_all_or_selected_to_qflist,
      ["<C-q>"] = send_all_or_selected_to_qflist,
      ["<C-M-q>"] = tel_actions.add_selected_to_qflist + tel_actions.open_qflist, -- (?)

      -- N/I: Layout actions
      ["<M-p>"] = tel_actions_lay.toggle_preview,
      ["<C-f>"] = wrap_tel_action_fn("my-toggle-fullscreen", function(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        -- NOTE: don't know how to save state in the picker, so in the meantime we store the layout
        --   in the prompt buffer..
        -- /!\ Downside is that when 'resuming' a picker that was in fullscreen, the prompt buffer
        --   is re-created and we don't have access to the previous layout config anymore..
        if vim.b[prompt_bufnr].telescope_last_layout_config then
          -- Restore layout config, out of fullscreen!
          picker.layout_config = vim.b[prompt_bufnr].telescope_last_layout_config
          -- print("DEBUG", "restoring layout config:", vim.inspect(picker.layout_config))
          vim.b[prompt_bufnr].telescope_last_layout_config = nil
        else
          -- Save layout config, set fullscreen!
          -- print("DEBUG", "saving layout config:", vim.inspect(picker.layout_config))
          vim.b[prompt_bufnr].telescope_last_layout_config = vim.deepcopy(picker.layout_config)
          -- Set current layout strategy size to (almost) 100% (note: 1.0 doesn't work…)
          picker.layout_config[picker.layout_strategy].height = 0.99
          picker.layout_config[picker.layout_strategy].width = 0.99
        end
        picker:full_layout_update()
      end),

      -- N/I: Mouse actions
      ["<LeftMouse>"] = {
        tel_actions.mouse_click,
        type = "action",
        opts = { expr = true },
      },
    }
    default_cfg.mappings.i = {
      ["<Esc>"] = tel_actions.close, -- Quick exit
      ["<M-Esc>"] = { "<Esc>", type = "command" }, -- Insert to Normal mode (used less often)

      -- Delete last word (yes, using <C-S-w> instead of <C-w>)
      -- REF: https://github.com/nvim-telescope/telescope.nvim/issues/1579
      ["<C-w>"] = { "<C-S-w>", type = "command" },
      ["<M-BS>"] = { "<C-S-w>", type = "command" },

      -- Insert file/line/cword
      ["<C-r><C-f>"] = tel_actions.insert_original_cfile,
      ["<C-r><C-l>"] = tel_actions.insert_original_cline,
      ["<C-r><C-w>"] = tel_actions.insert_original_cword,
      ["<C-r><C-a>"] = tel_actions.insert_original_cWORD,
    }
    default_cfg.mappings.n = {
      ["<Esc>"] = tel_actions.close,
      ["?"] = tel_actions.which_key,

      -- Move selection
      ["j"] = tel_actions.move_selection_next,
      ["k"] = tel_actions.move_selection_previous,
      ["g"] = tel_actions.move_to_top,
      -- ["M"] = tel_actions.move_to_middle,
      ["G"] = tel_actions.move_to_bottom,

      -- Results up/down/left/right scrolling
      ["<PageUp>"] = tel_actions.results_scrolling_up,
      ["<PageDown>"] = tel_actions.results_scrolling_down,
      ["<K>"] = tel_actions.results_scrolling_up,
      ["<J>"] = tel_actions.results_scrolling_down,
      ["H"] = tel_actions.results_scrolling_left,
      ["L"] = tel_actions.results_scrolling_right,
    }
    -- Add mappings common for both modes:
    for _, mode in ipairs{"i", "n"} do
      for key, mapping in pairs(both_n_i) do
        default_cfg.mappings[mode][key] = mapping
      end
    end

    -- DEFAULT LAYOUT
    default_cfg.layout_config = {
      prompt_position = "top",
      vertical = {
        mirror = true,
      }
    }
    default_cfg.sorting_strategy = "ascending" -- make sure results are from top-to-bottom
    default_cfg.scroll_strategy = "limit" -- (not cycle!)
    default_cfg.borderchars = { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" } -- heavier borders
    -- // some ideas..
    -- heavy single border: { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" }
    -- half blocks (outer): { "▀", "▐", "▄", "▌", "▛", "▜", "▟", "▙" }
    -- half blocks (inner): { "▄", "▌", "▀", "▐", "▗", "▖", "▘", "▝" }
    -- thin blocks: { "▔", "▕", "▁", "▏", "🭽", "🭾", "🭿", "🭼" }

    local extensions_cfg = {}
    local extensions_to_load = {}

    -- Extension: fzf (fast native sorter implemented in C)
    -- Plugin in named 'telescope-fzf-native'
    extensions_cfg.fzf = {} -- default config
    table.insert(extensions_to_load, "fzf")

    -- Extension: ui-select
    extensions_cfg["ui-select"] = {
      require"telescope.themes".get_dropdown(),
    }
    table.insert(extensions_to_load, "ui-select")

    -- Extension: frecency
    extensions_cfg.frecency = {
      matcher = "fuzzy",
    }
    table.insert(extensions_to_load, "frecency")

    -- Extension: import (find imports in files around)
    extensions_cfg.import = {} -- default config
    table.insert(extensions_to_load, "import")

    -- Extension: picker_list
    -- /!\ must be the last extension
    extensions_cfg.picker_list = {
      -- ignore some pickers I don't need here
      excluded_pickers = {
        "fzf", -- native searcher
        "fd", -- alias for find_files
        "grep_string", -- live_grep is better
        "tags", "current_buffer_tags", -- never use tags now..
        "git_files", -- find_files is basically the same.. (with fd-based finder)
        "symbols", -- useless with telescope-symbols catalog, and not useful for me..
      },
    }
    table.insert(extensions_to_load, "picker_list")

    require"telescope".setup {
      extensions = extensions_cfg,
      defaults = default_cfg,
      pickers = {
        colorscheme = {
          ignore_builtins = true,
          enable_preview = true,
        },
      },
    }
    -- Load extensions
    for _, ext_name in ipairs(extensions_to_load) do
      require"telescope".load_extension(ext_name)
    end

    local tel_builtin = require"telescope.builtin"

    -- Direct key for most used search!
    K.toplevel_map{mode={"n"}, key="<M-f>", desc="Fuzzy search files", action=tel_builtin.find_files}
    K.toplevel_map{mode={"n"}, key="<M-F>", desc="Fuzzy search _all_ files", action=function()
      tel_builtin.find_files { no_ignore = true }
    end}

    K.toplevel_map_define_group{mode={"n"}, prefix_key="<C-f>", name="+Fuzzy search"}
    K.toplevel_map{mode={"n"}, key="<C-f><C-f>", desc="… Resume last", action=tel_builtin.resume} -- ✨
    K.toplevel_map{mode={"n"}, key="<C-f><C-z>", desc="Pick a picker…", action=function() vim.cmd.Telescope("picker_list") end}
    K.toplevel_map{mode={"n"}, key="<C-f><C-g>", desc="Live Grep", action=tel_builtin.live_grep} -- use C-Space to fuzzy refine
    K.toplevel_map{mode={"n"}, key="<C-f><C-r>", desc="Frecency", action=function() vim.cmd.Telescope("frecency") end}
    K.toplevel_map{mode={"n"}, key="<C-f><C-m>", desc="Commands", action=tel_builtin.commands} -- note: <C-f><C-c> broken 🤔
    K.toplevel_map{mode={"n"}, key="<C-f><C-h>", desc="Help Tags", action=tel_builtin.help_tags}
    K.toplevel_map{mode={"n"}, key="<C-f><C-j>", desc="Jumps", action=tel_builtin.jumplist}
    K.toplevel_map{mode={"n"}, key="<C-f><C-l>", desc="Buffer lines", action=tel_builtin.current_buffer_fuzzy_find}
    K.toplevel_map{mode={"n"}, key="<C-f><C-Space>", desc="Buffers", action=tel_builtin.buffers}
  end,
  on_colorscheme_change = function()
    local normal = U.hl.group"Normal"
    ---@type {[string]: mylib.hl.HlGroup}
    local cols = {}
    cols.TelescopeBorder = normal
    cols.TelescopePromptBorder = U.hl.group {
      ctermfg = 202,
      ctermbg = normal.ctermbg,
    }

    -- Titles are the reverse of borders
    cols.TelescopeTitle = cols.TelescopeBorder:with { reverse = true, bold = true }
    cols.TelescopePromptTitle = cols.TelescopePromptBorder:with { reverse = true, bold = true }

    cols.TelescopeMatching = U.hl.group { ctermfg = 202 }
    cols.TelescopeMultiSelection = U.hl.group { ctermbg = 22, bold = true }

    for hlgroup, hlspec in pairs(cols) do
      U.hl.set(hlgroup, hlspec)
    end
  end
}
