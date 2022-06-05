" Force rtp to use the new ~/.dot/nvim-wip dir, not the std ~/.config/nvim one (with my old config)
let &rtp = '/home/lesell_b/.dot/nvim-wip,/etc/xdg/nvim,/home/lesell_b/.local/share/nvim/site,/home/lesell_b/.nix-profile/share/nvim/site,/usr/share/nvim/site,/usr/local/share/nvim/site,/home/lesell_b/.local/share/nvim/site,/nix/store/0vjynr1jdnvqpy9rcc2kh0agsdgdbzn0-neovim-unwrapped-0.7.0/share/nvim/runtime,/nix/store/0vjynr1jdnvqpy9rcc2kh0agsdgdbzn0-neovim-unwrapped-0.7.0/share/nvim/runtime/pack/dist/opt/matchit,/nix/store/0vjynr1jdnvqpy9rcc2kh0agsdgdbzn0-neovim-unwrapped-0.7.0/lib/nvim,/home/lesell_b/.local/share/nvim/site/after,/usr/local/share/nvim/site/after,/usr/share/nvim/site/after,/home/lesell_b/.nix-profile/share/nvim/site/after,/home/lesell_b/.local/share/nvim/site/after,/etc/xdg/nvim/after,/home/lesell_b/.dot/nvim-wip/after'

" Load options early in case the initialization of some plugin requires them.
" (e.g: for filetype on)
runtime! options.vim

" Specify the python binary to use for the plugins, this is necessary to be
" able to use them while inside a project' venv (which does not have pynvim)
let $NVIM_DATA_HOME = ($XDG_DATA_HOME != '' ? $XDG_DATA_HOME : $HOME . "/.local/share") . "/nvim-wip"
" NOTE: ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ use custom dir for nvim-wip !!!!!!!!

" FIXME: python env, still needed?
" let $NVIM_PY_VENV = $NVIM_DATA_HOME . "/py-venv"
" let g:python3_host_prog = $NVIM_PY_VENV . "/bin/python3"
" NOTE: Make sure to install pynvim in this environment! (and jedi for py dev)

" map leader definition - space
let g:mapleader = " "
" IDEA: Change <leader> to <Ctrl-space> | Have <localleader> be <space>
" And the CtrlSpace plugin would be <leader><space> or <leader><leader>
" Also give a new leader possibility with <Alt-space> (:

" ------ PLUGINS

" Mapping helpers, to be moved, probably
lua << LUA
-- Create initial leader maps (to be used in init of some plugins)
wk_leader_n_maps = {}
wk_leader_v_maps = {}

--- Get the which_key's leader map for the given mode
function get_wk_leader_maps_for_mode(mode)
  local wk_leader_maps_for_mode = {
    n = wk_leader_n_maps,
    v = wk_leader_v_maps,
  }
  return wk_leader_maps_for_mode[mode]
end

--- Define leader map group for which_key plugin
function leader_map_define_group(spec)
  assert(spec.mode, "mode is required")
  for _, m in ipairs(spec.mode) do
    wk_leader_maps = get_wk_leader_maps_for_mode(m)
    if wk_leader_maps then
      wk_leader_maps[spec.prefix_key] = { name = spec.name }
    end
  end
end

--- Create top level map
function toplevel_map(spec)
  assert(spec.mode, "mode is required")
  assert(spec.key, "key is required")
  assert(spec.action, "action is required")
  vim.keymap.set(spec.mode, spec.key, spec.action, spec.opts)
end

--- Create leader map & register it on which_key plugin
function leader_map(spec)
  toplevel_map(vim.tbl_extend("force", spec, { key = "<leader>"..spec.key }))
  -- when desc is set, put the key&desc in appropriate whichkey maps
  if spec.desc then
    for _, m in ipairs(spec.mode) do
      wk_leader_maps = get_wk_leader_maps_for_mode(m)
      if wk_leader_maps then
        wk_leader_maps[spec.key] = spec.desc
      end
    end
  end
end
LUA

let $NVIM_MANAGED_PLUGINS_DIR = $NVIM_DATA_HOME . "/managed-plugins"
call plug#begin($NVIM_MANAGED_PLUGINS_DIR)

" Manage vim-plug itself! (to auto update & handle its doc)
Plug 'junegunn/vim-plug', {
    \ 'do': 'ln -sf ' . $NVIM_MANAGED_PLUGINS_DIR . '/vim-plug/plug.vim ~/.nvim/autoload/plug.vim',
    \ }


" ---------- completion
" NOTE: Basic config for now (no lsp, cmdline, custom popup menu stuff)

" The idea with cmp is that various sources register themselves to cmp with a name,
" and then in cmp we mention that name in a list of sources (+ optional configs).
Plug 'hrsh7th/nvim-cmp'    " Next-gen async completion engine (in Lua)
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'andersevenrud/cmp-tmux'
Plug 'hrsh7th/cmp-emoji'

lua << LUA
function my_cmp_setup()
  local cmp = require"cmp"
  -- NOTE: default config is at: https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/default.lua
  cmp.setup.global({
    snippet = {
      expand = function(args)
        -- TODO: enable when luasnip configured!
        -- require'loasnip'.lsp_expand(args.body)
      end
    },
    -- TODO? try the configurable popup menu (value: "custom")
    -- view = {
    --   entries = {name = 'custom', selection_order = 'near_cursor' }
    -- }
    view = { entries = "native" }, -- the builtin completion menu
    confirmation = {
      -- disable auto-confirmations!
      get_commit_characters = function() return {} end,
    },
    -- NOTE: mapping presets are in https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/mapping.lua
    mapping = cmp.mapping.preset.insert({
      ["<C-c>"] = cmp.mapping.abort(), -- in addition to <C-e>
      ["<M-C-n>"] = cmp.mapping.scroll_docs(4),
      ["<M-C-p>"] = cmp.mapping.scroll_docs(-4),
    }),
    -- NOTE: default config has lots of sorting functions (cmp.config.compare.*),
    --       and a locality system, try using that first before trying to override it!
    --sorting = {
    --  comparators = {
    --    require'cmp_buffer'.compare_locality, -- sort words by distance to cursor (for buffer & lsp* sources)
    --  }
    --},
    -- NOTE: 'cmp.config.sources' helper allows to specify multiple source arrays.
    -- (internally it generates a single source list, where each source has 'group_index' field set to make groups)
    -- The sources are grouped in the given order, and the groups are displayed as a fallback,
    -- like chain completion.
    sources = cmp.config.sources({
      -- By default, 'buffer' source searches words in current buffer only
      -- TODO: config to search in all opened (or visible?) buffers
      -- IDEA?: make a separate source to search in buffer of same filetype
      --        (its priority should be higher than the 'buffer' source's priority)
      { name = "buffer" },
      { name = "path" }, -- By default, '.' is relative to the buffer
    }, {
      {
        name = "tmux",
        option = { all_panes = true, trigger_characters = {} --[[ all ]], keyword_length = 5 },
      },
    }),
  })
  cmp.setup.filetype({"markdown", "git", "gitcommit"}, {
    -- FIXME: does it replace the global sources? (I hope not)
    sources = {
      {
        name = "emoji",
        option = { insert = true, keyword_length = 4 },
      },
    }
  })
end
LUA
autocmd User PluginsLoaded lua my_cmp_setup()

" ---------- Code-centric UI

Plug 'lukas-reineke/indent-blankline.nvim'
lua << LUA
function my_indentguides_setup()
  require("indent_blankline").setup {
    char_list = {"¦", "│"},
    show_first_indent_level = false,
    -- show the current indent level on empty lines
    -- (setting it to false would only show the previous indent, not current one)
    show_trailing_blankline_indent = true,
  }
end
LUA
autocmd User PluginsLoaded lua my_indentguides_setup()

Plug 'kyazdani42/nvim-tree.lua'
lua << LUA
function my_tree_setup()
  require"nvim-tree".setup {
    view = {
      signcolumn = "no", -- used to show files diagnostics (FIXME: can these be toggled?)
      preserve_window_proportions = true,
    },
    renderer = {
      add_trailing = true, -- add '/' to folders
      group_empty = true,
      indent_markers = { enable = true },
      icons = {
        symlink_arrow = "->",
        show = {
          -- disable icons
          -- FIXME: icons on symlinks are still there..
          file = false,
          folder = false,
          git = false,
        }
      },
      -- highlight files by their git status (NvimTreeGit* hl groups)
      highlight_git = true,
    },
    actions = {
      open_file = { resize_window = false },
      -- For actions copy_name, copy_path, copy_absolute_path:
      -- don't put copied text in "+ register (let me manage system clip'), put it in "1 & "" regs
      -- FIXME: need an easy way to transfer "" to "+ on demand ?
      use_system_clipboard = false,
    },
    -- TODO(later): rewrite full mappings to be easier more logical (my own) to use / remember.
  }
end
LUA
autocmd User PluginsLoaded lua my_tree_setup()

Plug 'folke/which-key.nvim'
lua << LUA
function my_which_key_setup()
  local wk = require"which-key"
  wk.setup {
    layout = {
      align = "center",
      spacing = 5,
      height = { min = 1 }, -- Ref: https://github.com/folke/which-key.nvim/issues/195
    },
    icons = { separator = "->" },
    key_labels = {
      -- Override the label used to display some keys
      ["<space>"] = "SPC",
      ["<tab>"] = "TAB",
      ["<cr>"] = "Enter",
      ["<NL>"] = "<C-J>",
    },
    plugins = {
      -- Enable spelling popup on 'z='
      spelling = { enabled = true },
      -- Disable most presets (auto-doc for builtin keys) which assume the default keys
      -- are used. It is distractful, and doesn't detect everything right.
      presets = {
        operators = false,
        motions = false,
        text_objects = false,
        windows = false,
        nav = false,
      },
    },
    -- Ensure the which-key popup is auto-triggered ONLY for a very limited set of keys,
    -- because the popup is mostly annoying/distractful for other keys.
    triggers = {
      "<leader>",
      "z", -- (help for 'z' can be useful)
      "<M-f>", -- fuzzy stuff
    },
  }
  -- Register nmap/vmap keys descriptions
  require("which-key").register(wk_leader_n_maps, { mode = "n", prefix = "<leader>" })
  require("which-key").register(wk_leader_v_maps, { mode = "v", prefix = "<leader>" })
end
LUA
autocmd User PluginsLoaded lua my_which_key_setup()
augroup my_hi_which_key
  au!
  au ColorScheme * hi WhichKey      ctermfg=33 cterm=bold
  au ColorScheme * hi WhichKeyDesc  ctermfg=172
  au ColorScheme * hi WhichKeyGroup ctermfg=70
augroup END
" Create a per-buffer map, to avoid crashing WhichKey when the variable
" does not exist, we must create a buffer dict, empty for most files,
" which will be filled for some file types
" FIXME: This does NOT work, because vim-which-key does NOT merge the
"        dicts of multiple register('same-prefix', different-dict).
" autocmd BufRead * let b:which_key_map = {}
" autocmd User PluginsLoaded call which_key#register("<space>", "b:which_key_map")

Plug 'vijaymarupudi/nvim-fzf'   " A powerful Lua API for using fzf in neovim
let $FZF_DEFAULT_OPTS = $FZF_BEW_KEYBINDINGS . " " . $FZF_BEW_LAYOUT
lua << LUA
function my_fzf_setup()
  require"fzf".default_options = {
    relative = "editor", -- open a centered floating win
    width = 90, -- FIXME: not a percentage!!!! Ask to allow function here?
    height = 40, -- FIXME: not a percentage!!!! Ask to allow function here?
    border = "single",
  }
end
LUA
autocmd User PluginsLoaded lua my_fzf_setup()
Plug 'ibhagwan/fzf-lua'         " Few pre-configured thing selectors (buffers, files, ...)
lua << LUA
function my_fuzzy_selectors_setup()
  -- command! FuzzyFilesSmart call fzf#run(fzf#wrap({
  --     \   "source": "fd --type f --type l --follow",
  --     \   "options": ["--multi", "--prompt", "FilesSmart-> "]
  --     \ }))
  -- " Using the default source to find ALL files
  -- command! FuzzyFiles call fzf#run(fzf#wrap({
  --     \   "options": ["--multi", "--prompt", "Files-> "]
  --     \ }))
  -- " TODO: in FuzzyOldFiles, remove files that do not exist anymore (or are not
  -- " really files, like `man://foobar`.
  -- command! FuzzyOldFiles call fzf#run(fzf#wrap({
  --     \   "source": v:oldfiles,
  --     \   "options": ["--multi", "--prompt", "OldFiles-> "]
  --     \ }))
  -- " FIXME: oldfiles are NOT recent files (files recently opened in current
  -- " session are not in v:oldfiles. Need a FuzzyRecentFiles !!
  -- " (same dir? or general? or configurable (in fzf?) ?)
  local act = require"fzf-lua.actions"
  require"fzf-lua".setup{
    winopts = {
      border = "single",
      preview = {
        default = "bat", -- instead of builtin one, using nvim buffers
      },
    },
    fzf_opts = {}, -- don't let them overwrite my own config!
    keymap = {
      -- don't let them overwrite my own config! (e.g: their alt-a means select all :/)
      fzf = {},
    },
    actions = {
      files = {
        -- keys for all providers that act on files
        ["default"] = act.file_edit,
        ["alt-s"]   = act.file_split,
        ["alt-v"]   = act.file_vsplit,
        ["alt-t"]   = act.file_tabedit,
        ["alt-q"]   = act.file_sel_to_qf, -- this is interesting! (TODO: similar to arglist?)
      },
    },
  }
  require"fzf-lua".register_ui_select()
end
LUA
autocmd User PluginsLoaded lua my_fuzzy_selectors_setup()

nnoremap <silent> <M-f><M-f> <cmd>lua require"fzf-lua".files()<cr>
nnoremap <silent> <M-f><M-a> <cmd>lua require"fzf-lua".files()<cr>
nnoremap <silent> <M-f><M-g> <cmd>lua require"fzf-lua".git_files()<cr>

" ---------- utils plugins

Plug 'vim-scripts/xterm-color-table.vim'  " Provide some commands to display all cterm colors

Plug 'nvim-lua/plenary.nvim' " lua contrib stdlib for plugins, used by many plugins

Plug 'kyazdani42/nvim-web-devicons' " corresponding icon for a given filetype (required for alpha-nvim)
Plug 'goolord/alpha-nvim'     " a lua powered greeter like vim-startify / dashboard-nvim
lua << LUA
function my_startupscreen_setup()
  -- the plugin is very versatile! ref: https://github.com/goolord/alpha-nvim/discussions/16
  -- simple theme, until I want to make my own...
  local theme = require"alpha.themes.startify"
  -- FIXME: fortune broken, ref: https://github.com/goolord/alpha-nvim/issues/112
  -- theme.section.footer.val = require"alpha.fortune"()
  -- TODO(later): format with cowsay!
  require"alpha".setup(theme.config)
end
LUA
autocmd User PluginsLoaded lua my_startupscreen_setup()

Plug 'tpope/vim-fugitive'       " A Git wrapper so awesome, it should be illegal
Plug 'junegunn/gv.vim'             " Simple (<3) git commit browser, based on vim-fugitive
Plug 'whiteinge/diffconflicts'     " Helper plugin for git merges
" Use this cmd as mergetool:
"   nvim -c DiffConflictsWithHistory "$MERGED" "$BASE" "$LOCAL" "$REMOTE"

call plug#end()
doautocmd User PluginsLoaded

runtime! mappings.vim
runtime! statusline.vim   " Until it's re-written in Lua :)


colorscheme bew256-dark

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
" Also don't do it when the mark is in the first line, that is the default
" position when opening a file.
" FIXME: still needed with nvim?
autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \ exe "normal! g`\"" |
    \ endif
