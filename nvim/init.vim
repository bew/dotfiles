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
let mapleader = " "

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
Plug 'tpope/vim-abolish'        " Helpers for abbreviation, cased substitution & coercion
Plug 'thinca/vim-visualstar'      " * for visualy selected text
Plug 'itchyny/lightline.vim'      " statusline builder

Plug 'jremmen/vim-ripgrep'
let g:rg_command = 'rg --vimgrep -S' " -S for smartcase

Plug 'stefandtw/quickfix-reflector.vim' " Editable quickfix buffer, for bulk changes
" Sets quickfix buffers as modifiable
let g:qf_modifiable = 1   " FIXME: Do I hide this behind a command?
" Changes within a single buffer will be undo-able as a single change
let g:qf_join_changes = 1
" TODO: change the status line / display a warning that there is a change / ..


Plug 'machakann/vim-sandwich'   " Advanced operators & textobjects to manipulate surroundings

" Load vim-surround compatible mappings
" Ref: https://github.com/machakann/vim-sandwich/wiki/Introduce-vim-surround-keymappings
source ~/.nvim/plugged/vim-sandwich/macros/sandwich/keymap/surround.vim
" Textobjects to select a text surrounded by bracket or same characters user input
xmap is <Plug>(textobj-sandwich-query-i)
xmap as <Plug>(textobj-sandwich-query-a)
omap is <Plug>(textobj-sandwich-query-i)
omap as <Plug>(textobj-sandwich-query-a)
" Textobjects to select the nearest surrounded text automatically
xmap iss <Plug>(textobj-sandwich-auto-i)
xmap ass <Plug>(textobj-sandwich-auto-a)
omap iss <Plug>(textobj-sandwich-auto-i)
omap ass <Plug>(textobj-sandwich-auto-a)
" Textobjects to select a text surrounded by same characters user input
xmap im <Plug>(textobj-sandwich-literal-query-i)
xmap am <Plug>(textobj-sandwich-literal-query-a)
omap im <Plug>(textobj-sandwich-literal-query-i)
omap am <Plug>(textobj-sandwich-literal-query-a)

" Add spaces inside () [] {} when using ( [ or {. (mimicking vim-surround)
" Ref: https://github.com/machakann/vim-sandwich/wiki/Bracket-with-spaces
let g:sandwich#recipes += [
    \   {'buns': ['{ ', ' }'], 'nesting': 1, 'match_syntax': 1, 'kind': ['add', 'replace'], 'action': ['add'], 'input': ['{']},
    \   {'buns': ['[ ', ' ]'], 'nesting': 1, 'match_syntax': 1, 'kind': ['add', 'replace'], 'action': ['add'], 'input': ['[']},
    \   {'buns': ['( ', ' )'], 'nesting': 1, 'match_syntax': 1, 'kind': ['add', 'replace'], 'action': ['add'], 'input': ['(']},
    \   {'buns': ['{\s*', '\s*}'],   'nesting': 1, 'regex': 1, 'match_syntax': 1, 'kind': ['delete', 'replace', 'textobj'], 'action': ['delete'], 'input': ['{']},
    \   {'buns': ['\[\s*', '\s*\]'], 'nesting': 1, 'regex': 1, 'match_syntax': 1, 'kind': ['delete', 'replace', 'textobj'], 'action': ['delete'], 'input': ['[']},
    \   {'buns': ['(\s*', '\s*)'],   'nesting': 1, 'regex': 1, 'match_syntax': 1, 'kind': ['delete', 'replace', 'textobj'], 'action': ['delete'], 'input': ['(']},
    \ ]

Plug 'neomake/neomake'          " Asynchronous linting and make framework
let g:neomake_virtualtext_prefix = "  <<  "
let g:neomake_error_sign = { 'text': 'x', 'texthl': 'NeomakeSignError', }
let g:neomake_warning_sign = { 'text': '!', 'texthl': 'NeomakeSignWarning', }
augroup my_neomake_hi
  au!

  " Signs
  au ColorScheme * hi NeomakeSignError   cterm=none ctermfg=red
  au ColorScheme * hi NeomakeSignWarning cterm=none ctermfg=yellow

  " Virtual text
  au ColorScheme * hi NeomakeVirtualtextError   cterm=italic ctermbg=none ctermfg=red
  au ColorScheme * hi NeomakeVirtualtextWarning cterm=italic ctermbg=none ctermfg=yellow
  au ColorScheme * hi NeomakeVirtualtextInfo    cterm=italic ctermbg=none ctermfg=cyan
augroup END


Plug 'tpope/vim-repeat'         " Repeat for plugins
Plug 'Shougo/deoplete.nvim',      " Dark-powered completion engine
    \ { 'do': ':UpdateRemotePlugin' }
let g:deoplete#enable_at_startup = 1

Plug 'tommcdo/vim-exchange'

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


Plug 'scrooloose/nerdcommenter'     " Comment stuff out
Plug 'scrooloose/nerdtree'        " Tree based file explorer

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
let g:gitgutter_map_keys = 0
nmap <leader>hp <Plug>(GitGutterPreviewHunk)
nmap <leader>hu <Plug>(GitGutterUndoHunk)
nnoremap <leader>hf :GitGutterFold<cr>

nnoremap ]h :GitGutterNextHunk<cr>
nnoremap [h :GitGutterPrevHunk<cr>

" Hunk text object
omap ih <Plug>(GitGutterTextObjectInnerPending)
omap ah <Plug>(GitGutterTextObjectOuterPending)
xmap ih <Plug>(GitGutterTextObjectInnerVisual)
xmap ah <Plug>(GitGutterTextObjectOuterVisual)

if $ASCII_ONLY != "1"
  let g:gitgutter_sign_added              = "┃"
  let g:gitgutter_sign_modified           = "┃"
  let g:gitgutter_sign_removed            = "▁"
  let g:gitgutter_sign_removed_first_line = "▔"
  let g:gitgutter_sign_modified_removed   = "~▁"
endif

augroup my_git_signs_hi
  " NOTE: all SignVcs* highlights are defined in my color scheme
  au ColorScheme * hi link GitGutterAdd    SignVcsAdd
  au ColorScheme * hi link GitGutterChange SignVcsChange
  au ColorScheme * hi link GitGutterDelete SignVcsDelete
augroup END

Plug 'easymotion/vim-easymotion' " Motions on speed!

Plug 'liuchengxu/vim-which-key'
" My floating win highlightings aren't ready for this...
let g:which_key_use_floating_win = 0
let g:which_key_sep = '--'
autocmd! FileType which_key
autocmd FileType which_key hi WhichKeySeperator ctermbg=none ctermfg=37

" -- Insert mode helpers

Plug 'Raimondi/delimitMate'      " auto insert of second ()''{}[]\"\" etc...
let delimitMate_expand_space = 1
let delimitMate_expand_cr = 1

Plug 'SirVer/ultisnips'         " Advanced snippets

" -- Text refactor / formater

Plug 'autozimu/LanguageClient-neovim',
    \ {
    \   'branch': 'next',
    \   'do': 'bash install.sh',
    \ }
let g:LanguageClient_serverCommands = {
    \ 'crystal': [$HOME . '/Projects/opensource/scry/bin/scry'],
    \ }
" let g:LanguageClient_loggingFile = '/tmp/lsp.log'
" let g:LanguageClient_loggingLevel = 'DEBUG'

Plug 'junegunn/vim-easy-align'      " An advanced, easy-to-use Vim alignment plugin.

Plug 'tpope/vim-fugitive'       " A Git wrapper so awesome, it should be illegal
Plug 'junegunn/gv.vim'          " Simple (<3) git commit browser, based on vim-fugitive
Plug 'rhysd/git-messenger.vim'  " Popup the commit message of the line under cursor
let g:git_messenger_no_default_mappings = v:true
nmap gc  <Plug>(git-messenger)

" -- UI

Plug 'Yggdroot/indentLine'
" Each indent level uses a distinct character (rotating)
let g:indentLine_char_list = ($ASCII_ONLY == "1" ? ["|"] : ["┆", "┊", "┆", "¦"])
let g:indentLine_fileTypeExclude = ['help', 'startify', 'man', 'defx', 'markdown', 'codi']

" File opening
Plug '~/.nix-profile/share/vim-plugins/fzf'
let g:fzf_action = {
    \ "alt-t": "tab split",
    \ "alt-s": "split",
    \ "alt-v": "vsplit",
    \ }
let g:fzf_history_dir = "~/.local/share/nvim-fzf-history"
let g:fzf_layout = {"window": "bot 20new"}
let $FZF_DEFAULT_OPTS = $FZF_BEW_KEYBINDINGS . " " . $FZF_BEW_LAYOUT
command! FilesSmart call fzf#run(fzf#wrap({
    \   "source": "fd --type f --type l --follow",
    \   "options": ["--multi"]
    \ }))
command! Files      FZF

Plug 'mhinz/vim-startify'         " add a custom startup screen for vim
augroup my_startify
  au!

  " Makes the Startify buffer listed in the buffer list, this fixes an issue
  " with Floaterm which leaves an empty buffer when opened on a Startify
  " buffer.
  autocmd User Startified setlocal buflisted
augroup END

Plug 'owickstrom/vim-colors-paramount' " Very simple colorscheme

Plug 'vim-scripts/xterm-color-table.vim'  " Provide some commands to display all cterm colors

Plug 'chrisbra/Colorizer'  " color hex codes #112233, ANSI sequences, vim's cterm*g
" Or just call :ColorHighlight on any file and enjoy
let g:colorizer_auto_filetype='css,html,vim'
let g:colorizer_colornames = 0 " Don't hl colornames (like red, yellow)

Plug 'tweekmonster/nvim-api-viewer'

Plug 'metakirby5/codi.vim'  " Interactive scratchpad (file on the left, interpreter outputs on the right)
let g:codi#width = 50.0  " Split the windows in half

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
let g:jedi#show_call_signatures = "2"

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

call plug#end()

"""""""""""""""""""""""""""""""""

runtime! config.rc/plugins/*.rc.vim

" Source some files
runtime! mappings.vim
runtime! autocmd.vim


"""""""""""""""""""""""""""""""""

augroup my_custom_language_hi
  au!

  " Markdown
  au ColorScheme * hi markdownCode ctermfg=29


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
" is not one of the given target colorschemes.
function! SetColorschemeForBackground(dark_color, light_color, force)
  let cur = get(g:, "colors_name", "default")
  if !a:force && l:cur != a:dark_color && l:cur != a:light_color
    " Another colorscheme than our targets is set, ignore the change.
    echom "Colorscheme kept to " . l:cur . " [background is " . &background . "] - Use :SetColorscheme to override"
    return
  endif
  if &background == 'light'
    exe "colorscheme " . a:light_color
  else
    exe "colorscheme " . a:dark_color
  endif
  echom "Colorscheme set to " . g:colors_name . " [background is " . &background . "]"
endf
function! SetColorscheme(force)
  call SetColorschemeForBackground("bew256-dark", "paramount", a:force)
endf
augroup my_colorscheme_setup
  au!
  au OptionSet background call SetColorscheme(v:false)
augroup END
command! SetColorscheme call SetColorscheme(v:true)

if has("vim_starting")
  " Set the colorscheme on startup
  if $TERM_COLOR_MODE == 'light'
    set background=light
  else
    set background=dark
  endif
  silent call SetColorscheme(v:true)
else
  silent call SetColorscheme(v:false)
endif

" Fix lightline not refreshing on &background change
" NOTE: must be done after 'my_colorscheme_setup' autocmd group
augroup lightline_fix_hightlight
  au!
  au OptionSet background call lightline#highlight()
augroup END

command! HiDumpToSplit so $VIMRUNTIME/syntax/hitest.vim

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
command! DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
    \ | wincmd p | diffthis
