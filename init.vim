set nocompatible
call plug#begin('~/.config/nvim/plugged')

Plug 'embear/vim-localvimrc'			" Load local .lvimrc files

" -- Vim feature enhancer

Plug 'simnalamburt/vim-mundo'			" undo tree (fork of gundo)
Plug 'szw/vim-ctrlspace'				" Control your space (buffers/tags/workspaces/etc..)
Plug 'tpope/vim-abolish'				" Helpers for abbreviation, cased substitution & coercion
Plug 'thinca/vim-visualstar'			" * for visualy selected text
Plug 'mileszs/ack.vim'					" Use ack for vimgrep
Plug 'tpope/vim-surround'				" vim-surround
Plug 'itchyny/lightline.vim'			" statusline builder
Plug 'neomake/neomake'					" Asynchronous linting and make framework
Plug 'tpope/vim-repeat'					" Repeat for plugins
Plug 'Shougo/deoplete.nvim',			" Dark-powered completion engine
            \ { 'do': ':UpdateRemotePlugin' }
let g:deoplete#enable_at_startup = 1

Plug 'scrooloose/nerdcommenter'			" Comment stuff out
Plug 'scrooloose/nerdtree'				" Tree based file explorer

Plug 'airblade/vim-gitgutter'			" Git diff in the gutter

" Motions on speed!
Plug 'easymotion/vim-easymotion'

" -- Insert mode helpers

Plug 'Raimondi/delimitMate'				" auto insert of second ()''{}[]\"\" etc...
Plug 'SirVer/ultisnips'					" Advanced snippets

" -- Text refactor / formater

Plug 'autozimu/LanguageClient-neovim',
            \ {
            \   'branch': 'next',
            \   'do': 'bash install.sh',
            \ }
let g:LanguageClient_serverCommands = {
    \ 'crystal': [$HOME . '/Projects/opensource/scry/bin/scry'],
    \ }

Plug 'junegunn/vim-easy-align'			" An advanced, easy-to-use Vim alignment plugin.

Plug 'tpope/vim-fugitive'				" A Git wrapper so awesome, it should be illegal

" -- UI

Plug 'nathanaelkane/vim-indent-guides'		" Add colored indent guides
Plug 'Shougo/denite.nvim'					" Generic interactive menu framework

Plug 'mhinz/vim-startify'					" add a custom startup screen for vim

Plug 'bew/vim-colors-solarized'				" vim-colors-solarized - favorite colorscheme <3
Plug 'vim-scripts/xterm-color-table.vim'	" Provide some commands to display all cterm colors
Plug 'ryanoasis/vim-devicons'

Plug 'drzel/vim-line-no-indicator'			" Simple and expressive line number indicator

Plug 'tweekmonster/nvim-api-viewer'

" -- Per language plugins

"# C / CPP
Plug 'octol/vim-cpp-enhanced-highlight'	" Better highlight
Plug 'Shougo/deoplete-clangx'			" FINALLY it works properly (C/C++)

" Read why in $VIMRUNTIME/autoload/dist/ft.vim
let g:c_syntax_for_h=1

Plug 'Shougo/echodoc.vim'	" It prints the documentation you have completed.

"# Arduino
"Plug 'jplaut/vim-arduino-ino'			" Arduino project compilation and deploy
"Plug 'sudar/vim-arduino-syntax'			" Arduino syntax
"Plug 'sudar/vim-arduino-snippets'		" Arduino snippets

"# Crystal lang
Plug 'rhysd/vim-crystal'				" Crystal lang integration for vim

"# LLVM IR
Plug 'EdJoJob/llvmir-vim'				" LLVM IR syntax & other stuff

"# QML
Plug 'peterhoeg/vim-qml'				" QML syntax

"# Markdown
" 'plasticboy/vim-markdown' might be nice too
Plug 'gabrielelana/vim-markdown'		" Complete environment to create Markdown files with a syntax highlight that doesn't suck!
" 'SidOfc/mkdx' looks awesome!!!!

" E.g disable auto change of << to «
let g:markdown_enable_input_abbreviations = 0


"# Python
Plug 'hynek/vim-python-pep8-indent'		" PEP8 indentation
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

"# Slim templating (for HTML)
Plug 'slim-template/vim-slim'

"# Vuejs
Plug 'posva/vim-vue'

"# Vimscript
Plug 'Shougo/neco-vim'

"# Elixir
Plug 'elixir-editors/vim-elixir'

"# OpenSCAD syntax
Plug 'sirtaj/vim-openscad'

call plug#end()

let g:vimhome = $HOME . "/.config/nvim"

" Configuration file loader

function! s:sourceFile(path)
	if filereadable(a:path)
		exec "source " . a:path
		return v:true
	endif
	return v:false
endfunction

function! s:loadConfigFile(path)
	if s:sourceFile(a:path)
		return
	endif
	if s:sourceFile(g:vimhome . "/config.rc/" . a:path)
		return
	endif
	if s:sourceFile(g:vimhome . "/config.rc/" . a:path . ".rc.vim")
		return
	endif
endfunction

function! s:loadConfigDir(dirpath)
	for filepath in split(globpath(g:vimhome . "/config.rc/" . a:dirpath, "*.rc.vim"), "\n")
		call s:loadConfigFile(filepath)
	endfor
endfunction


"""""""""""""""""""""""""""""""""

call s:loadConfigDir("plugins")

if has("gui")
	" Disable every gvim gui stuff
	set guioptions=
	set guifont="DejaVu Sans Mono for Powerline 11"
endif

" map leader definition
let mapleader = ","

call s:loadConfigFile("mappings")

" Source the options
runtime options.vim

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

" Nice colors for TabLine
hi TabLineSel  cterm=NONE    ctermfg=187 ctermbg=235
hi TabLine     cterm=NONE    ctermfg=230 ctermbg=239
hi TabLineFill cterm=reverse ctermfg=187 ctermbg=244

hi clear Visual Todo Comment
hi Visual ctermbg=237
" We need the ctermbg=NONE at the end, I don't know why...
hi Todo cterm=bold ctermfg=11 ctermbg=NONE " fg: yellow
hi Comment ctermfg=242 " bg: light grey

hi Normal ctermfg=248

" Markdown
hi markdownCode ctermfg=29

hi clear BadSpell
hi BadSpell cterm=underline

hi clear SignColumn
hi SignColumn ctermbg=234


" Ruby Colors
hi clear rubyInstanceVariable
hi rubyInstanceVariable ctermfg=33
hi clear rubySymbol
hi rubySymbol ctermfg=208

" Lua Colors
hi clear luaTableReference
hi luaTableReference ctermfg=208
hi clear luaFunction
hi link luaFunction luaStatement

hi luaVariableTag cterm=italic ctermfg=30

" C Colors (can color c++ as well ?)
hi link cStructure cStatement
hi link cStorageClass cStatement
hi clear cStructInstance cOperator cBoolComparator
hi cStructInstance ctermfg=208
hi cArithmOp ctermfg=3
hi cBoolComparator cterm=bold ctermfg=3

hi cVariableTag cterm=italic ctermfg=30

" Because &background is not dark we have to set this manually
"let g:indent_guides_auto_colors = 0
"autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=233
"autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=235

call s:loadConfigFile("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
	command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
				\ | wincmd p | diffthis
endif

