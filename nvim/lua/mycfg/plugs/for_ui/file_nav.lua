local PluginSystem = require"mylib.plugin_system"
local t = PluginSystem.tags
local gh = PluginSystem.sources.github
-- local myplug = PluginSystem.sources.myplug
local Plug = PluginSystem.get_plugin_declarator {
  default_tags = { t.ui, "nav" },
}

--------------------------------

Plug {
  -- Use `:Oil <path>`, use `g?` for help
  source = gh"stevearc/oil.nvim",
  desc = "Edit your filesystem like a normal Neovim buffer",
  tags = {"filesystem"},
  -- NOTE: can't use defer_load, or it wouldn't hijack netrw on `nvim <dir>`
  on_load = function()
    -- NOTE: taken from: https://github.com/stevearc/oil.nvim/blob/master/doc/recipes.md
    function _G._oil_get_winbar()
      local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
      local dir = require"oil".get_current_dir(bufnr)
      if dir then
        return vim.fn.fnamemodify(dir, ":~")
      else
        -- If there is no current directory (e.g. over ssh), just show the buffer name
        return vim.api.nvim_buf_get_name(0)
      end
    end
    require"oil".setup {
      default_file_explorer = true,
      win_options = {
        winbar = "%!v:lua._oil_get_winbar()",
      },

      keymaps = {
        -- Disable default split/tab actions that use Ctrl 😬
        ["<C-s>"] = false,
        ["<C-h>"] = false,
        ["<C-t>"] = false,
        -- Disable more defaults that use Ctrl 😬
        ["<C-p>"] = false,
        ["<C-l>"] = false,

        ["<2-LeftMouse>"] = "actions.select",

        -- NOTE: Can't have them without Ctrl without breaking <M-s> to save buffer.. :/
        -- => It's usually easier anyway to split in the direction I want then open wanted file..
        ["<C-M-s>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-M-h>"] = { "actions.select", opts = { vertical = true } },
        ["<C-M-t>"] = { "actions.select", opts = { tab = true } },
        ["<M-p>"] = "actions.preview",
        ["<M-r>"] = "actions.refresh",
        ["<BS>"] = "actions.parent",
      },
    }

    toplevel_map{mode={"n"}, key="-", action=[[<cmd>Oil<cr>]], desc="Oil: Open parent dir"}
  end,
}

Plug.fileexplorer {
  -- extra-keywords: neotree
  source = gh"nvim-neo-tree/neo-tree.nvim",
  desc = "Neovim plugin to manage the file system and other tree like structures",
  tags = {"filesystem"},
  version = { branch = "v3.x" },
  depends_on = {Plug.lib_plenary, Plug.lib_nui, Plug.lib_web_devicons},
  defer_load = { on_cmd = "Neotree" },
  on_load = function()
    require("neo-tree").setup {
      -- Don't hijack nvim's file explorer, Oil is nicer for that!
      hijack_netrw_behavior = "disabled",

      sources = {
        "filesystem", -- builtin
        "buffers", -- builtin
        "git_status", -- builtin
      },
      default_source = "filesystem",
      use_popups_for_input = false, -- force use vim.input
      sort_case_insensitive = true,
      source_selector = {
        winbar = true,
        -- BROKEN: opened issue: https://github.com/nvim-neo-tree/neo-tree.nvim/issues/848
        -- tabs_layout = "start",
        content_layout = "center",
      },
      -- Default window configs (can be specialized per source)
      window = {
        position = "right",
        mappings = {
          -- Action names are found in:
          -- common actions: <plug>/lua/neo-tree/sources/common/commands.lua
          -- per-source actions, e.g: <plug>/lua/neo-tree/sources/filesystem/commands.lua
          -- FIXME: how to define custom ad-hoc actions here in the config?
          -- FIXME: missing tree navigation actions to goto parent node, goto next/prev sibling node
          ["a"] = {"add", config = { show_path = "relative" }},
          ["o"] = "open",
          ["t"] = "noop", ["s"] = "noop", ["S"] = "noop", -- disable default split/tab opening keys
          ["<M-t>"] = "open_tabnew",
          ["<M-s>"] = "open_split",
          ["<M-v>"] = "open_vsplit",

          ["z"] = "noop",
          ["zC"] = "close_all_nodes",
          -- ["zA"] = "expand_all_nodes", -- BROKEN: crashes neovim :eyes:
        },
      },
      -- event_handlers = {},
      default_component_configs = {
        name = {
          trailing_slash = true,
        }
      },

      -- Per source configs
      filesystem = {
        bind_to_cwd = false, -- don't change tab cwd when opening Neotree with a dir
        group_empty_dirs = true,
        use_libuv_file_watcher = true,
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false, -- AFAIU, 'false' -> dirs that were not manually opened will be auto-closed
        },
        window = {
          mappings = {
            -- Disable neotree's fuzzy finder on `/`, it's annoying when I just want to jump to something I see
            ["/"] = "noop",
            ["#"] = "noop",
            -- Re-enable neotree's fuzzy finder using shifted letters so I can spam shift `/` + shift
            -- `f` to activate it, but still do shift `/` + `bla` to search `bla` with vim's search.
            ["/F"] = "fuzzy_finder",
            ["//"] = "fuzzy_finder", -- alt mapping, nicer?
            ["/D"] = "fuzzy_finder_directory", -- only directories
            -- FIXME: how to make the fuzzy_finder NOT auto-open found file?
            --   (when pressing <cr> after searching something to hide)
            --   => Then, how to hide results? Maybe with an empty fuzzy search? (not great..)
            -- NOTE: I'd expect the fuzzy finder thing to not be specific to filesystem view,
            --   and to work over any sets of tree of nodes
            -- FIXME: how to close the fuzzy_finder searchbox while keeping the filtered view of
            --   results??
          },
          fuzzy_finder_mappings = {
            ["<M-j>"] = "move_cursor_down",
            ["<M-k>"] = "move_cursor_up",
          },
        },
      },
      git_status = {
        bind_to_cwd = false, -- don't change tab cwd when opening Neotree with a dir
      },
      buffers = {
        bind_to_cwd = false, -- don't change tab cwd when opening Neotree with a dir
      },
    }
  end,
  on_colorscheme_change = function()
    -- Necessary as I don't have 'termguicolor' => ~all default colors are not available
    vim.cmd[[hi NeoTreeModified cterm=bold]]
    vim.cmd[[hi NeoTreeDimText ctermfg=239]]
    vim.cmd[[hi NeoTreeTabActive cterm=bold]]
    vim.cmd[[hi NeoTreeTabInactive ctermfg=239]]
    vim.cmd[[hi NeoTreeTabSeparatorInactive ctermfg=239]]
  end
}
