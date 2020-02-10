set nocompatible
call plug#begin('~/.config/nvim/plugged')

Plug 'embear/vim-localvimrc'      " Load local .lvimrc files

" -- Vim feature enhancer

Plug 'simnalamburt/vim-mundo'     " undo tree (fork of gundo)
Plug 'szw/vim-ctrlspace'        " Control your space (buffers/tags/workspaces/etc..)
Plug 'tpope/vim-abolish'        " Helpers for abbreviation, cased substitution & coercion
Plug 'thinca/vim-visualstar'      " * for visualy selected text
Plug 'mileszs/ack.vim'          " Use ack for vimgrep
Plug 'tpope/vim-surround'       " vim-surround
Plug 'itchyny/lightline.vim'      " statusline builder

Plug 'neomake/neomake'          " Asynchronous linting and make framework
let g:neomake_virtualtext_prefix = "  ❰❰ "
let g:neomake_error_sign = {
      \ 'text': '█',
      \ 'texthl': 'NeomakeErrorSign',
      \ }
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

" Motions on speed!
Plug 'easymotion/vim-easymotion'

" -- Insert mode helpers

Plug 'Raimondi/delimitMate'       " auto insert of second ()''{}[]\"\" etc...
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

" -- UI

Plug 'nathanaelkane/vim-indent-guides'    " Add colored indent guides

" Adjust indent guides color (TODO: light theme version)
let g:indent_guides_auto_colors = 0
autocmd Colorscheme * :hi IndentGuidesOdd  ctermbg=236
autocmd Colorscheme * :hi IndentGuidesEven ctermbg=235


Plug 'Shougo/denite.nvim'         " Generic interactive menu framework

Plug 'mhinz/vim-startify'         " add a custom startup screen for vim

Plug 'bew/vim-colors-solarized'       " vim-colors-solarized - favorite colorscheme <3
Plug 'vim-scripts/xterm-color-table.vim'  " Provide some commands to display all cterm colors
Plug 'ryanoasis/vim-devicons'

Plug 'drzel/vim-line-no-indicator'      " Simple and expressive line number indicator

Plug 'tweekmonster/nvim-api-viewer'

" -- Per Lang / Tech plugins

"# git commit mode
Plug 'rhysd/committia.vim'

"# Nix
Plug 'LnL7/vim-nix'

"# C / CPP
Plug 'octol/vim-cpp-enhanced-highlight' " Better highlight
Plug 'Shougo/deoplete-clangx'     " FINALLY it works properly (C/C++)

" Read why in $VIMRUNTIME/autoload/dist/ft.vim
let g:c_syntax_for_h=1

Plug 'Shougo/echodoc.vim' " It prints the documentation you have completed.

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
" 'plasticboy/vim-markdown' might be nice too
Plug 'gabrielelana/vim-markdown'    " Complete environment to create Markdown files with a syntax highlight that doesn't suck!
" 'SidOfc/mkdx' looks awesome!!!!

" E.g disable auto change of << to «
let g:markdown_enable_input_abbreviations = 0


"# Python
Plug 'hynek/vim-python-pep8-indent'   " PEP8 indentation
Plug 'zchee/deoplete-jedi'

" More Python tools (e.g: goto def)
Plug 'davidhalter/jedi-vim'
let g:jedi#completions_enabled = 0

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
Plug 'Shougo/neco-vim'

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
runtime! options.vim
runtime! mappings.vim
runtime! autocmd.vim

" map leader definition - space
let mapleader = " "

call togglebg#install_mapping('<f12>')

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
augroup END

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
        \ | wincmd p | diffthis
endif

