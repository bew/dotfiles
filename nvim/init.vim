set nocompatible

" Load options early in case the initialization of some plugin requires them.
" (e.g: for filetype on)
runtime! options.vim

" Specify the python binary to use for the plugins, this is necessary to be
" able to use them while inside a project' venv (which does not have pynvim)
let $NVIM_DATA_HOME = ($XDG_DATA_HOME != '' ? $XDG_DATA_HOME : $HOME . "/.local/share") . "/nvim"
let $NVIM_PY_VENV = $NVIM_DATA_HOME . "/py-venv"
let g:python3_host_prog = $NVIM_PY_VENV . "/bin/python3"
" NOTE: Make sure to install pynvim in this environment! (and jedi for py dev)

" map leader definition - space
let g:mapleader = " "
" IDEA: Change <leader> to <Ctrl-space> | Have <localleader> be <space>
" And the CtrlSpace plugin would be <leader><space> or <leader><leader>
" Also give a new leader possibility with <Alt-space> (:

call plug#begin('~/.nvim/plugged')

" Manage vim-plug itself! (to auto update & handle its doc)
Plug 'junegunn/vim-plug', {
    \ 'do': 'ln -sf ../plugged/vim-plug/plug.vim ~/.nvim/autoload/plug.vim',
    \ }

Plug 'embear/vim-localvimrc'      " Load local .lvimrc files

" -- Vim feature enhancer

Plug 'wellle/targets.vim'        " Moar & improved text objects
Plug 'simnalamburt/vim-mundo'     " undo tree (fork of gundo)
Plug 'szw/vim-ctrlspace'        " Control your space (buffers/tags/workspaces/etc..)
let g:CtrlSpaceUseTabline = 1
let g:CtrlSpaceLoadLastWorkspaceOnStart = 0

" Use ascii for most symbols
" (note: some are still on their plugin' default)
let g:CtrlSpaceSymbols = {}
let g:CtrlSpaceSymbols.CS = "#"
let g:CtrlSpaceSymbols.All = "all"
let g:CtrlSpaceSymbols.Vis = "visible"
let g:CtrlSpaceSymbols.File = "files"
let g:CtrlSpaceSymbols.Zoom = "<Z>"
let g:CtrlSpaceSymbols.WLoad = "|>>"
let g:CtrlSpaceSymbols.WSave = "|<<"
let g:CtrlSpaceSymbols.IV = "(-)"  " Item Visible or Last-active
let g:CtrlSpaceSymbols.IA = "( )"  " Item Active
let g:CtrlSpaceSymbols.IM = "(+)"  " Item Modified

Plug 'tpope/vim-abolish'        " Helpers for abbreviation, cased substitution & coercion
Plug 'thinca/vim-visualstar'      " * for visualy selected text
Plug 'itchyny/lightline.vim'      " statusline builder

Plug 'liuchengxu/vim-which-key'
let g:which_key_use_floating_win = 0
" let g:which_key_timeout = 0  " Does not seem to work, it still takes &timeoutlen to open.
let g:which_key_sep = '->'
autocmd! FileType which_key
autocmd FileType which_key hi WhichKeySeperator ctermbg=none ctermfg=37
let g:which_key_map = {}  " Fill this map for which-key helper!
autocmd User PluginsLoaded call which_key#register("<space>", "g:which_key_map")
" Create a per-buffer map, to avoid crashing WhichKey when the variable
" does not exist, we must create a buffer dict, empty for most files,
" which will be filled for some file types
" FIXME: This does NOT work, because vim-which-key does NOT merge the
"        dicts of multiple register('same-prefix', different-dict).
" autocmd BufRead * let b:which_key_map = {}
" autocmd User PluginsLoaded call which_key#register("<space>", "b:which_key_map")

Plug 'jremmen/vim-ripgrep'
let g:rg_command = 'rg --vimgrep -S' " -S for smartcase

Plug 'machakann/vim-sandwich'   " Advanced operators & textobjects to manipulate surroundings

" Load vim-surround compatible mappings
" Ref: https://github.com/machakann/vim-sandwich/wiki/Introduce-vim-surround-keymappings
source ~/.nvim/plugged/vim-sandwich/macros/sandwich/keymap/surround.vim
" Textobjects to select a text surrounded by bracket or same characters user input
xmap is <Plug>(textobj-sandwich-query-i)
xmap as <Plug>(textobj-sandwich-query-a)
omap is <Plug>(textobj-sandwich-query-i)
omap as <Plug>(textobj-sandwich-query-a)

" Add spaces inside () [] {} when using ( [ or {. (mimicking the original vim-surround)
" Ref: https://github.com/machakann/vim-sandwich/wiki/Bracket-with-spaces
let g:sandwich#recipes += [
    \   {'buns': ['{ ', ' }'], 'nesting': 1, 'match_syntax': 1, 'kind': ['add', 'replace'], 'action': ['add'], 'input': ['{']},
    \   {'buns': ['[ ', ' ]'], 'nesting': 1, 'match_syntax': 1, 'kind': ['add', 'replace'], 'action': ['add'], 'input': ['[']},
    \   {'buns': ['( ', ' )'], 'nesting': 1, 'match_syntax': 1, 'kind': ['add', 'replace'], 'action': ['add'], 'input': ['(']},
    \   {'buns': ['{\s*', '\s*}'],   'nesting': 1, 'regex': 1, 'match_syntax': 1, 'kind': ['delete', 'replace', 'textobj'], 'action': ['delete'], 'input': ['{']},
    \   {'buns': ['\[\s*', '\s*\]'], 'nesting': 1, 'regex': 1, 'match_syntax': 1, 'kind': ['delete', 'replace', 'textobj'], 'action': ['delete'], 'input': ['[']},
    \   {'buns': ['(\s*', '\s*)'],   'nesting': 1, 'regex': 1, 'match_syntax': 1, 'kind': ['delete', 'replace', 'textobj'], 'action': ['delete'], 'input': ['(']},
    \ ]

" Diagnostic provider agnostic signs config
let s:code_diagnostic_cfg = {}
let s:code_diagnostic_cfg.virt_text_prefix = "  <<  "
let s:code_diagnostic_cfg.code_hl = "CodeDiagnosticDefaultCodeHl"
let s:code_diagnostic_cfg.error = {
    \   "sign": "x",
    \   "sign_hl": "CodeDiagnosticSignError",
    \   "virt_text_hl": "CodeDiagnosticVirtTextError",
    \ }
let s:code_diagnostic_cfg.warning = {
    \   "sign": "!",
    \   "sign_hl": "CodeDiagnosticSignWarning",
    \   "virt_text_hl": "CodeDiagnosticVirtTextWarning",
    \ }
let s:code_diagnostic_cfg.info = {
    \   "sign": "i",
    \   "sign_hl": "CodeDiagnosticSignInfo",
    \   "virt_text_hl": "CodeDiagnosticVirtTextInfo",
    \ }
let s:code_diagnostic_cfg.hint = {
    \   "sign": "h",
    \   "sign_hl": "CodeDiagnosticSignHint",
    \   "virt_text_hl": "CodeDiagnosticVirtTextHint",
    \ }
augroup my_code_diagnostic_hi
  au!
  function! s:set_code_diagnostic_highlights()
    hi CodeDiagnosticDefaultCodeHl cterm=underline
    hi CodeDiagnosticSignError   ctermfg=red
    hi CodeDiagnosticSignWarning ctermfg=yellow
    hi CodeDiagnosticSignInfo    ctermfg=cyan
    hi link CodeDiagnosticSignHint CodeDiagnosticSignInfo
    hi CodeDiagnosticVirtTextError   cterm=italic ctermfg=red
    hi CodeDiagnosticVirtTextWarning cterm=italic ctermfg=yellow
    hi CodeDiagnosticVirtTextInfo    cterm=italic ctermfg=cyan
    hi link CodeDiagnosticVirtTextHint CodeDiagnosticVirtTextInfo
  endf
  au ColorScheme * call <sid>set_code_diagnostic_highlights()
augroup END

Plug 'neomake/neomake'          " Asynchronous linting and make framework
let diag = s:code_diagnostic_cfg
let g:neomake_virtualtext_prefix = diag.virt_text_prefix
let s:nm_diag_gen = {cfg -> {"text": cfg.sign, "texthl": cfg.sign_hl}}
let g:neomake_error_sign = s:nm_diag_gen(diag.error)
let g:neomake_warning_sign = s:nm_diag_gen(diag.warning)
let g:neomake_info_sign = s:nm_diag_gen(diag.info)
unlet diag s:nm_diag_gen
augroup my_neomake_hi
  au!
  au ColorScheme * hi link NeomakeSignError   CodeDiagnosticSignError
  au ColorScheme * hi link NeomakeSignWarning CodeDiagnosticSignWarning
  au ColorScheme * hi link NeomakeSignInfo    CodeDiagnosticSignInfo
  au ColorScheme * hi link NeomakeVirtualtextError   CodeDiagnosticVirtTextError
  au ColorScheme * hi link NeomakeVirtualtextWarning CodeDiagnosticVirtTextWarning
  au ColorScheme * hi link NeomakeVirtualtextInfo    CodeDiagnosticVirtTextInfo
augroup END

Plug 'autozimu/LanguageClient-neovim', {'branch': 'next', 'do': 'bash install.sh'}
" note for the line above: single quote are mandatory on the whole line.
let g:LanguageClient_useVirtualText = "Diagnostics"
let g:LanguageClient_virtualTextPrefix = s:code_diagnostic_cfg.virt_text_prefix

let s:lc_diag_gen = {name, cfg -> {
    \   "name": name,
    \   "texthl": s:code_diagnostic_cfg.code_hl,
    \   "signText": cfg.sign,
    \   "signTexthl": cfg.sign_hl,
    \   "virtualTexthl": cfg.virt_text_hl,
    \ }}
let g:LanguageClient_diagnosticsDisplay = {}
let g:LanguageClient_diagnosticsDisplay.1 =
    \ s:lc_diag_gen("Error", s:code_diagnostic_cfg.error)
let g:LanguageClient_diagnosticsDisplay.2 =
    \ s:lc_diag_gen("Warning", s:code_diagnostic_cfg.warning)
let g:LanguageClient_diagnosticsDisplay.3 =
    \ s:lc_diag_gen("Info", s:code_diagnostic_cfg.info)
let g:LanguageClient_diagnosticsDisplay.4 =
    \ s:lc_diag_gen("Hint", s:code_diagnostic_cfg.hint)
unlet s:lc_diag_gen
augroup my_LanguageClient_config
  autocmd!
  autocmd User LanguageClientStarted NeomakeDisableBuffer
  autocmd User LanguageClientStopped NeomakeEnableBuffer
augroup END

let g:LanguageClient_serverCommands = {}
let g:LanguageClient_serverCommands.rust = ["rust-analyzer"]

Plug 'Shougo/echodoc'  " shows (in a smart way) the signature of completed items
let g:echodoc#enable_at_startup = v:true
let g:echodoc#highlight_identifier = "Identifier"
let g:echodoc#highlight_arguments = "Type"
let g:echodoc#highlight_trailing = "Comment"

Plug 'tpope/vim-repeat'         " Repeat for plugins
Plug 'Shougo/deoplete.nvim',      " Dark-powered completion engine
    \ { 'do': ':UpdateRemotePlugin' }
let g:deoplete#enable_at_startup = 1

Plug 'tommcdo/vim-exchange'

" FIXME: I get a vim error message when triggering it with
Plug 'voldikss/vim-floaterm'    " Nice floating terminal with super powers
if $ASCII_ONLY == "1"
  let g:floaterm_borderchars = ['-', '|', '-', '|', '+', '+', '+', '+']
endif
" Command used for opening a file from within :terminal, using the binary `floaterm <some-file>`
let g:floaterm_open_command = 'split'  " So I can move it where I want without overwriting my current window

function! s:InstallFloatermBorderColorChange()
  au TermLeave <buffer> hi FloatermBorder cterm=bold ctermfg=124
  au TermEnter <buffer> hi FloatermBorder cterm=NONE ctermfg=28
endf

augroup my_floaterm
  au!
  au ColorScheme * hi Floaterm ctermbg=235
  au ColorScheme * hi FloatermBorder ctermfg=130

  au FileType floaterm call <SID>InstallFloatermBorderColorChange()
augroup END


Plug 'preservim/nerdcommenter'         " Comment stuff out
let g:NERDCreateDefaultMappings = 0

" Specifies the default alignment to use when inserting comments.
let g:NERDDefaultAlign = 'left'

" Add some spaces between the comment delimiter (e.g: `#`) and the commented text
let g:NERDSpaceDelims = 1

" When uncommenting an empty line some whitespace may be left as a result of
" alignment padding. With this option enabled any trailing whitespace will be
" deleted when uncommenting a line.
let g:NERDTrimTrailingWhitespace = 1

let g:NERDCustomDelimiters = {}
let g:NERDCustomDelimiters.python = {"left": "#"}

" --

Plug 'preservim/nerdtree'    " Tree based file explorer

Plug 'dyng/ctrlsf.vim'            " Project search like Sublime Text
let g:ctrlsf_confirm_save = 1
let g:ctrlsf_auto_focus = {
    \ 'at': 'start',
    \ }
let g:ctrlsf_auto_close = {
    \ "normal" : 0,
    \ "compact": 0
    \ }
" Search interface, wishes:
" - lives in a floating window, can hide but not close (=> easy toggle)
" - search dashboard, with per project recent/frequent searches
" - search results must be closed explicitely (q), will close results, previews &
"   whole search tab
" - new search results open a tab in this floating window
" - duplicate search tab (to save it but continue tinkering around).
" - in the search results:
"   * allow to change search text (and plain/regex mode) & refresh results
"   * view a list of matching files on top, allow to hide the result of
"     some of them
" - unlike ctrlsf, edit mode should be explicitely enabled (with visual feedbacks)

Plug 'airblade/vim-gitgutter'     " Git diff in the gutter
let g:gitgutter_map_keys = v:false
" FIXME: doesn't work well: with no preview visible, esc is still bound to a
" function, and doing 42<esc> (to cancel a started action), the cursor moves
" unexpectedly..
" Tracking issue: https://github.com/airblade/vim-gitgutter/issues/784
let g:gitgutter_close_preview_on_escape = v:false

" Set a high sign priority, to avoid mixing signs based on order of appearance
" (default: 10, lower is higher priority)
let g:gitgutter_sign_priority = 5

if $ASCII_ONLY != ""
  " The default for this is a unicode symbol, which can break the display
  let g:gitgutter_sign_removed_first_line = "-"
else
  let g:gitgutter_sign_added              = "│"
  let g:gitgutter_sign_modified           = "│"
  let g:gitgutter_sign_removed            = "▁"
  let g:gitgutter_sign_modified_removed   = "▁" " NOTE: modified state is visible with sign' color
  let g:gitgutter_sign_removed_first_line = "‾"
endif

" TODO: move these mappings to 'mappings.vim' ?
" Hunk text object
omap ih <Plug>(GitGutterTextObjectInnerPending)
omap ah <Plug>(GitGutterTextObjectOuterPending)
xmap ih <Plug>(GitGutterTextObjectInnerVisual)
xmap ah <Plug>(GitGutterTextObjectOuterVisual)

augroup my_git_signs_hi
  " NOTE: all SignVcs* highlights are defined in my color scheme
  au ColorScheme * hi link GitGutterAdd    SignVcsAdd
  au ColorScheme * hi link GitGutterChange SignVcsChange
  au ColorScheme * hi link GitGutterDelete SignVcsDelete
augroup END

" -- Insert mode helpers

Plug 'Raimondi/delimitMate'      " auto insert of second ()''{}[]\"\" etc...
let delimitMate_expand_space = 1
let delimitMate_expand_cr = 1

Plug 'SirVer/ultisnips'         " Advanced snippets

" -- Text refactor / formater

Plug 'junegunn/vim-easy-align'      " An advanced, easy-to-use Vim alignment plugin.

Plug 'AndrewRadev/splitjoin.vim'    " Switch single-line <=> multiline forms of code
let g:splitjoin_python_brackets_on_separate_lines = 1
let g:splitjoin_trailing_comma = 1

Plug 'tpope/vim-fugitive'       " A Git wrapper so awesome, it should be illegal
Plug 'junegunn/gv.vim'          " Simple (<3) git commit browser, based on vim-fugitive
Plug 'rhysd/git-messenger.vim'  " Popup the commit message of the line under cursor
let g:git_messenger_no_default_mappings = v:true

" -- UI

Plug 'Yggdroot/indentLine'
" Each indent level uses a distinct character (rotating)
let g:indentLine_char_list = ($ASCII_ONLY == "1" ? ["|"] : ["│"])
let g:indentLine_bufTypeExclude = ["help", "terminal"]
let g:indentLine_bufNameExclude = ["_.*", "NERD_tree.*"]
let g:indentLine_fileTypeExclude = [
    \   "codi",
    \   "defx",
    \   "help",
    \   "json",
    \   "man",
    \   "markdown",
    \   "nerdtree",
    \   "startify",
    \ ]
augroup my_indentline_hi_group
  au!
  au ColorScheme * hi IndentLines cterm=none ctermfg=237
augroup END
let g:indentLine_defaultGroup = "IndentLines"

" File opening
Plug '~/.nix-profile/share/vim-plugins/fzf'
let g:fzf_action = {
    \ "alt-t": "tab split",
    \ "alt-s": "split",
    \ "alt-v": "vsplit",
    \ }
let g:fzf_history_dir = "~/.local/share/nvim-fzf-history"
let g:fzf_layout = {"window": {"width": 0.9, "height": 0.6, "border": "sharp"}} " floating window goes brrrr
let $FZF_DEFAULT_OPTS = $FZF_BEW_KEYBINDINGS . " " . $FZF_BEW_LAYOUT
command! FuzzyFilesSmart call fzf#run(fzf#wrap({
    \   "source": "fd --type f --type l --follow",
    \   "options": ["--multi", "--prompt", "FilesSmart-> "]
    \ }))
" Using the default source to find ALL files
command! FuzzyFiles call fzf#run(fzf#wrap({
    \   "options": ["--multi", "--prompt", "Files-> "]
    \ }))
" TODO: in FuzzyOldFiles, remove files that do not exist anymore (or are not
" really files, like `man://foobar`.
command! FuzzyOldFiles call fzf#run(fzf#wrap({
    \   "source": v:oldfiles,
    \   "options": ["--multi", "--prompt", "OldFiles-> "]
    \ }))
" FIXME: oldfiles are NOT recent files (files recently opened in current
" session are not in v:oldfiles. Need a FuzzyRecentFiles !!
" (same dir? or general? or configurable (in fzf?) ?)

Plug 'mhinz/vim-startify'         " add a custom startup screen for vim
augroup my_startify
  au!

  " Makes the Startify buffer listed in the buffer list, this fixes an issue
  " with Floaterm which leaves an empty buffer when opened on a Startify
  " buffer.
  autocmd User Startified setlocal buflisted
augroup END

Plug 'junegunn/vim-peekaboo'    " Show registers on usage
let g:peekaboo_delay = 1000 " in ms (don't show it when I'm fast)
let g:peekaboo_compact = v:false " always show section names

Plug 'owickstrom/vim-colors-paramount' " Very simple colorscheme

Plug 'vim-scripts/xterm-color-table.vim'  " Provide some commands to display all cterm colors

Plug 'chrisbra/Colorizer'  " color hex codes #112233, ANSI sequences, vim's cterm*g
" Or just call :ColorHighlight on any file and enjoy
let g:colorizer_auto_filetype='css,html,vim'
let g:colorizer_colornames_disable = v:true " Don't hl colornames (like red, yellow) because it can be very slow
let g:colorizer_debug = v:false " if needed... to understand why perf is bad
" Disable a bunch of autocmd that triggers a re-coloring AND SLOWS DOWN EVERYTHING!!
" let g:colorizer_insertleave = v:false
let g:colorizer_textchangedi = v:false
let g:colorizer_cursormoved = v:false    " Why would you even have that???
let g:colorizer_cursormovedi = v:false   " Why would you even have that???

Plug 'tweekmonster/nvim-api-viewer'

Plug 'metakirby5/codi.vim'  " Interactive scratchpad (file on the left, interpreter outputs on the right)
let g:codi#width = 50.0  " Split the windows in half
let g:codi#virtual_text_prefix = "  => "

Plug 'junegunn/goyo.vim'

" -- Per Lang / Tech plugins

"# Rust
Plug 'rust-lang/rust.vim'

"# git commit mode
Plug 'rhysd/committia.vim'

"# Nix
Plug 'LnL7/vim-nix'

"# C / CPP
Plug 'octol/vim-cpp-enhanced-highlight' " Better highlight
Plug 'Shougo/deoplete-clangx'     " FINALLY it works properly (C/C++)

" Read why in $VIMRUNTIME/autoload/dist/ft.vim
let g:c_syntax_for_h=1

"# Arduino
"Plug 'jplaut/vim-arduino-ino'      " Arduino project compilation and deploy
"Plug 'sudar/vim-arduino-syntax'      " Arduino syntax
"Plug 'sudar/vim-arduino-snippets'    " Arduino snippets

"# Crystal lang
Plug 'rhysd/vim-crystal'        " Crystal lang integration for vim
let g:crystal_define_mappings = 0

"# LLVM IR
Plug 'EdJoJob/llvmir-vim'       " LLVM IR syntax & other stuff

"# QML
Plug 'peterhoeg/vim-qml'        " QML syntax

"# Markdown
Plug 'plasticboy/vim-markdown'  " Markdown vim mode

let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0
let g:vim_markdown_conceal_code_blocks = 0

" Highlight YAML at start of file, useful to add metadata to a
" markdown file.
let g:vim_markdown_frontmatter = 1

"# Python
" Add colors to 'arg=' in 'func_call(arg=1)'
autocmd FileType python syn match pythonFunctionCallKwargs '\h\w\+='
autocmd FileType python hi pythonFunctionCallKwargs ctermfg=137

" NOTE: specifying `'for': 'python'` for this Plug breaks something when opening
" multiple files from cli, resulting in 'Not an editor command: Semshi enable'
" for each opened files.
Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'} " Semantic highlighting for python
let g:semshi#error_sign = v:false " This is already handled by neomake linters
let g:semshi#mark_selected_nodes = 2 " Also highlight the word under cursor
" Override some highlights
autocmd FileType python hi semshiSelected ctermfg=NONE ctermbg=NONE cterm=underline
autocmd FileType python hi semshiBuiltin ctermfg=131
autocmd FileType python hi semshiParameterUnused ctermfg=240

Plug 'hynek/vim-python-pep8-indent'   " PEP8 indentation
Plug 'zchee/deoplete-jedi'
Plug 'davidhalter/jedi-vim'         " IDE-like tooling
" NOTE: you might need to install 'jedi' in neovim's python virtual env,
" because the default install of the plugin does not always work
" (e.g when inside a project's venv..)

let g:jedi#completions_enabled = 0  " Let my async completion engine do that, using omnifunc
" Do not show call signature by hacking buffer content (breaks some completion)
let g:jedi#show_call_signatures = "0"  " Use echodoc plugin for this

let g:jedi#auto_initialization = 0  " Do not auto-init jedi (mappings, ..)
autocmd FileType python call <SID>setup_python_jedi()
function! s:setup_python_jedi()
  " Inspired from <jedi-vim-plugin-dir>/ftplugin/python/jedi.vim
  nnoremap <buffer>  <leader>cd   <cmd>call jedi#goto()<CR>
  nnoremap <buffer>  <leader>cu   <cmd>call jedi#usages()<CR>
  nnoremap <buffer>  <leader>cr   <cmd>call jedi#rename()<CR>
  vnoremap <buffer>  <leader>cr   <cmd>call jedi#rename_visual()<CR>
  " NOTE: vim-which-key does NOT work with global & local maps,
  "       see the config of vim-which-key for more details.
  " let b:which_key_map.c = {"name": "+code"}
  " let b:which_key_map.c.d = "goto definition"
  " let b:which_key_map.c.u = "goto usages"
  " let b:which_key_map.c.r = "rename"

  nnoremap <silent> <buffer> K   <cmd>call jedi#show_documentation()<CR>

  if g:jedi#show_call_signatures > 0
    call jedi#configure_call_signatures()
  endif
endf

" Jinja templating syntax & indent
Plug 'lepture/vim-jinja'

"# Typescript
Plug 'leafgarland/typescript-vim'

"# ES6 javascript syntax
Plug 'isRuslan/vim-es6'

"# Coffee script
Plug 'kchmck/vim-coffee-script'

"# Slim templating (for HTML)
Plug 'slim-template/vim-slim'

"# nftables
Plug 'nfnty/vim-nftables'

"# Vimscript
Plug 'Shougo/neco-vim'   " deoplete completion source

"# Elixir
Plug 'elixir-editors/vim-elixir'

"# OpenSCAD syntax
Plug 'sirtaj/vim-openscad'

"# Ansible
Plug 'pearofducks/ansible-vim'
" Add special ft for some ansible templates
let g:ansible_template_syntaxes = { '*haproxy*.cfg.j2': 'haproxy' }

"# Just - Support for 'justfile' (https://github.com/casey/just)
Plug 'vmchale/just-vim'

"# Lua
Plug 'tbastos/vim-lua'
" NOTE: setting to 0 for disabling is currently not supported -- just don't set
"       the option at all to keep it disabled.
let g:lua_syntax_nofold = 1  " Disable auto code folding

" tmux panes completion for deoplete <3 <3 <3
" see deoplete config!
Plug 'wellle/tmux-complete.vim'
" Emoji completion (:foobar:)
" It is auto enabled on gitcommit & markdown files
Plug 'fszymanski/deoplete-emoji'

" TODO: Add a configure properly a dictionary completion source for markdown
" https://github.com/deoplete-plugins/deoplete-dictionary
" alternative is https://github.com/deathlyfrantic/deoplete-spell which work if 'set spell'

call plug#end()
doautocmd User PluginsLoaded

"""""""""""""""""""""""""""""""""

runtime! config.rc/plugins/*.rc.vim

" Source some files
runtime! mappings.vim
runtime! autocmd.vim


" --- START of deoplete config
" TODO: move in a function and run on PluginsLoaded autocmd!

call deoplete#custom#option("auto_complete_delay", v:false)
" camel_case: Lowercase letters are also matched with the corresponding uppercase ones.
"   Ex: "foB" is matched with "FooBar" but not with "foobar".
call deoplete#custom#option("camel_case", v:true)

" Allow the use of Ctrl-N for 'complete' based completion
call deoplete#custom#option("on_insert_enter", v:false)

" Ensure file paths are ranked higher than words from around, to be able to write file paths without
" loosing patience because 'around' words are similar and goes before the path completions.
call deoplete#custom#source("file", "rank", 150)
call deoplete#custom#source("member", "rank", 140)
call deoplete#custom#source("around", "rank", 130)
call deoplete#custom#source("buffer", "rank", 120)

" Use fuzzy and more-that-typed-text matchers for 'around'
" matcher_length: It removes candidates shorter than or equal to the user input.
"   FIXME: it is not perfect, because sometime I want to have the same completion if that word
"   appears somewhere else in the file (..for self-validation in some way).
"   I JUST want to remove the current word from entering the candidates pool.
"   TODO: Make a custom matcher that works the same as matcher_length, but
"   only removes those from the current line. Those from other lines are OK
"   because they're not part of the current completion prompt.
call deoplete#custom#source("around", "matchers", ["matcher_fuzzy", "matcher_length"])

" Using custom variables to configure values
" - range_above = Search for words N lines above.
" - range_below = Search for words N lines below.
" - mark_above = Mark shown for words N lines above.
" - mark_below = Mark shown for words N lines below.
" - mark_changes = Mark shown for words in the changelist.
" (Example from the docs)
call deoplete#custom#var("around", {
    \   "range_above": 50,
    \   "range_below": 50,
    \   "mark_above": "[↑]",
    \   "mark_below": "[↓]",
    \   "mark_changes": "[*]",
    \ })

" Non essential completion sources

" rank higher than tmux, because if the emoji source is triggered, we are in a text file and
" there's a leading ':' so emoji is the most likely to be wanted.
call deoplete#custom#source("emoji", "rank", 20)
call deoplete#custom#source("emoji", "min_pattern_length", 4) " NOTE: the leading ':' is counted here
" FIXME: This seems to hide all results UNTIL there are 'max_candidates' results..
"        I just want to display the top 5 or 10. Maybe a bug in deoplete?
" call deoplete#custom#source("emoji", "max_candidates", 10)
call deoplete#custom#source("emoji", "matchers", ["matcher_fuzzy", "matcher_length"]) " the default full fuzzy is too much for me

" rank is lower than emoji, see explanation on emoji' rank
call deoplete#custom#source("tmux-complete", "rank", 10)
" Use this source ONLY for long completions, to avoid having too many suggestion every{time,where}
call deoplete#custom#source("tmux-complete", "min_pattern_length", 5)

" --- END of deoplete config



"""""""""""""""""""""""""""""""""

augroup my_custom_language_hi
  au!

  " Markdown
  au ColorScheme * hi markdownCode ctermfg=29

  " For some reason this group is linked to Visual by default (not in my colorscheme).
  " This group is used for spaces-only lines in markdown files.
  " FIXME: I'm not sure why doing this on ColorScheme autocmd like above doesn't seems to work..
  "        It is overriden by the markdown' syntax file (from the vim-markdown plugin)
  au FileType markdown hi mkdLineBreak cterm=NONE ctermbg=NONE ctermfg=NONE

  " In Markdown doc, make italic & bold standout from normal text, using colors in
  " addition to cterm's italic/bold for terminals without support for bold/italic.
  "
  " In plasticboy/vim-markdown, italic/bold highlights seems to come from HTML
  " syntax groups, which is wrong.  I want to configure highlights for
  " markdown only, not html!
  "
  " Tracking issue: https://github.com/plasticboy/vim-markdown/issues/521
  "
  " In the meantime, we need to set both html & mkd groups, because the mkd
  " groups are used for the delimiters, and html groups are used for the
  " content.
  au ColorScheme * hi mkdItalic cterm=italic ctermfg=253 ctermbg=235
  au ColorScheme * hi mkdBold cterm=bold ctermfg=253 ctermbg=235
  au ColorScheme * hi link htmlItalic mkdItalic
  au ColorScheme * hi link htmlBold mkdBold

  " Ruby Colors
  au ColorScheme * hi clear rubyInstanceVariable
  au ColorScheme * hi rubyInstanceVariable ctermfg=33
  au ColorScheme * hi clear rubySymbol
  au ColorScheme * hi rubySymbol ctermfg=208

  " Lua Colors
  au ColorScheme * hi clear luaTableReference
  au ColorScheme * hi luaTableReference ctermfg=208
  au ColorScheme * hi clear luaFunction
  au ColorScheme * hi link luaFunction luaStatement

  au ColorScheme * hi luaVariableTag cterm=italic ctermfg=30

  " C Colors (can color c++ as well ?)
  au ColorScheme * hi link cStructure cStatement
  au ColorScheme * hi link cStorageClass cStatement
  au ColorScheme * hi clear cStructInstance cOperator cBoolComparator
  au ColorScheme * hi cStructInstance ctermfg=208
  au ColorScheme * hi cArithmOp ctermfg=3
  au ColorScheme * hi cBoolComparator cterm=bold ctermfg=3
  au ColorScheme * hi cVariableTag cterm=italic ctermfg=30

  " Javascript Colors
  au ColorScheme * hi javaScriptDocParam ctermfg=25
  au ColorScheme * hi javaScriptDocTags ctermfg=88
augroup END

" Set a colorScheme based on current 'background'.
" If *force* is v:false, do not change the colorScheme if the current one
" is neither the given dark or given light colorscheme.
function! ApplyColorschemeForBackground(dark_color, light_color, force)
  let cur = get(g:, "colors_name", "default")
  if !a:force && l:cur != a:dark_color && l:cur != a:light_color
    " Another colorscheme than our targets is set, ignore the change.
    echom "Colorscheme kept to " . l:cur . " [background is " . &background . "] - Use :ApplyColorscheme to override"
    return
  endif
  if &background == 'light'
    exe "colorscheme " . a:light_color
  else
    exe "colorscheme " . a:dark_color
  endif
  echom "Colorscheme set to " . g:colors_name . " [background is " . &background . "]"
endf
function! ApplyColorscheme(force)
  call ApplyColorschemeForBackground("bew256-dark", "paramount", a:force)
endf
augroup my_colorscheme_setup
  au!
  au OptionSet background call ApplyColorscheme(v:false)
augroup END
command! ApplyColorscheme call ApplyColorscheme(v:true)

if has("vim_starting")
  " Set the colorscheme on startup
  if $TERM_COLOR_MODE == 'light'
    set background=light
  else
    set background=dark
  endif
  silent call ApplyColorscheme(v:true)
else
  silent call ApplyColorscheme(v:false)
endif

" Fix lightline not refreshing on &background change
" NOTE: must be done after 'my_colorscheme_setup' autocmd group
augroup my_lightline_fix_hightlight
  au!
  au OptionSet background call lightline#highlight()
augroup END

command! HiDumpToSplit so $VIMRUNTIME/syntax/hitest.vim

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
command! DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
    \ | wincmd p | diffthis

function! s:TrimTrailingWS(line1, line2)
  let saved_view = winsaveview()
  " keeppatterns: Don't change search register
  " 'e' option: ignore substitutions errors
  " NOTE: Using SINGLE QUOTES for the substitution part, to avoid having to escape \s or \+.
  execute "keeppatterns " .a:line1.",".a:line2. 's/\s\+$//e'
  call winrestview(saved_view)
endf
command! -range=% TrimTrailingWS call <SID>TrimTrailingWS(<line1>, <line2>)
