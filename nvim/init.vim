set nocompatible

" Load options early in case the initialization of some plugin requires them.
" (e.g: for filetype on)
runtime! options.vim

" Specify the python binary to use for the plugins, this is necessary to be
" able to use them while inside a project' venv (which does not have pynvim)
" FIXME: move somewhere else?
let g:python3_host_prog = "/usr/bin/python3"

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
let g:neomake_error_sign = { 'text': 'x', 'texthl': 'NeomakeErrorSign', }
let g:neomake_warning_sign = { 'text': '!', 'texthl': 'NeomakeWarningSign', }
augroup my_neomake_hi
  au!

  " Signs
  au ColorScheme * hi NeomakeErrorSign cterm=none ctermfg=red
  au ColorScheme * hi NeomakeWarningSign cterm=none ctermfg=yellow

  " Virtual text
  au ColorScheme * hi NeomakeVirtualtextError cterm=italic ctermbg=none ctermfg=red
  au ColorScheme * hi NeomakeVirtualtextInfo cterm=italic ctermbg=none ctermfg=cyan
  au ColorScheme * hi NeomakeVirtualtextWarning cterm=italic ctermbg=none ctermfg=yellow
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
let g:indentLine_char_list = ($ASCII_ONLY == "1" ? ["┆", "┊", "┆", "¦"] : ["|"])
let g:indentLine_fileTypeExclude = ['help', 'startify', 'man', 'defx', 'markdown', 'codi']

Plug 'Shougo/denite.nvim',         " Generic interactive menu framework
    \ { 'do': ':UpdateRemotePlugin' }

autocmd! FileType denite
autocmd FileType denite call s:denite_my_settings()
function! s:denite_my_settings() abort
  nnoremap <silent><buffer><expr> <CR>
      \ denite#do_map('do_action')
  nnoremap <silent><buffer><expr> o
      \ denite#do_map('do_action')
  nnoremap <silent><buffer><expr> <M-v>
      \ denite#do_map('do_action', 'vsplit')
  nnoremap <silent><buffer><expr> <M-s>
      \ denite#do_map('do_action', 'split')
  nnoremap <silent><buffer><expr> <M-t>
      \ denite#do_map('do_action', 'tabopen')
  " FIXME: how can I add my own custom actions?

  nnoremap <silent><buffer><expr> <M-Space>
      \ denite#do_map('toggle_select') . 'j'

  nnoremap <silent><buffer><expr> p
      \ denite#do_map('do_action', 'preview')

  nnoremap <silent><buffer><expr> q
      \ denite#do_map('quit')
  nnoremap <silent><buffer><expr> i
      \ denite#do_map('open_filter_buffer')
endfunction

autocmd! FileType denite-filter
autocmd FileType denite-filter call s:denite_filter_my_settings()
function! s:denite_filter_my_settings() abort
  nnoremap <silent><buffer><expr> q
      \ denite#do_map('quit')

  call deoplete#custom#buffer_option('auto_complete', v:false)
endfunction



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

Plug 'drzel/vim-line-no-indicator'      " Simple and expressive line number indicator

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

"# Python
Plug 'hynek/vim-python-pep8-indent'   " PEP8 indentation
Plug 'zchee/deoplete-jedi'
Plug 'davidhalter/jedi-vim'         " IDE-like tooling
let g:jedi#completions_enabled = 0  " Let my async completion engine do that, using omnifunc

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

call plug#end()

"""""""""""""""""""""""""""""""""

runtime! config.rc/plugins/*.rc.vim

" Source some files
runtime! mappings.vim
runtime! autocmd.vim


" Denite config (must be after plug#end() to work (FIXME?))
call denite#custom#alias('source', 'grep/rg', 'grep')
call denite#custom#var('grep/rg', 'command', ['rg'])
call denite#custom#var('grep/rg', 'default_opts',
    \ ['-i', '--vimgrep', '--no-heading'])
call denite#custom#var('grep/rg', 'recursive_opts', [])
call denite#custom#var('grep/rg', 'pattern_opt', ['--regexp'])
call denite#custom#var('grep/rg', 'separator', ['--'])
call denite#custom#var('grep/rg', 'final_opts', [])

call denite#custom#alias('source', 'file/rec/smart', 'file/rec')
call denite#custom#var('file/rec/smart', 'command',
    \ ['fd', '.', '--type', 'f', '--type', 'l'])

"""""""""""""""""""""""""""""""""

let g:fzf_action = {
    \ 'alt-t': 'tab split',
    \ 'alt-s': 'split',
    \ 'alt-v': 'vsplit',
    \ }

let $FZF_DEFAULT_OPTS = $FZF_BEW_KEYBINDINGS

if has("mac")
  " Homebrew puts the fzf install in non-vim accessible directory
  set rtp+=/usr/local/opt/fzf
endif

"""""""""""""""""""""""""""""""""

augroup my_float_hi
  au!

  au ColorScheme * hi NormalFloat ctermfg=248 ctermbg=232
augroup END

augroup my_custom_language_hi
  au!

  " Markdown
  au ColorScheme * hi markdownCode ctermfg=29

  au ColorScheme * hi clear BadSpell
  au ColorScheme * hi BadSpell cterm=underline


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
  call SetColorscheme(v:true)
else
  call SetColorscheme(v:false)
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
