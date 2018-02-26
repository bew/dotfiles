set nocompatible
call plug#begin('~/.config/nvim/plugged')

" -- Vim feature enhancer

Plug 'sjl/gundo.vim'					" undo tree
Plug 'szw/vim-ctrlspace'				" Control your space (buffers/tags/workspaces/etc..)
Plug 'tpope/vim-abolish'				" Helpers for abbreviation, cased substitution & coercion
Plug 'thinca/vim-visualstar'			" * for visualy selected text
Plug 'mileszs/ack.vim'					" Use ack for vimgrep
Plug 'tpope/vim-surround'				" vim-surround
Plug 'itchyny/lightline.vim'			" statusline builder
Plug 'Shougo/deoplete.nvim',			" Dark powered asynchronous completion framework
            \ { 'do': ':UpdateRemotePlugins' }
Plug 'scrooloose/nerdcommenter'			" Comment stuff out

" Motions on speed!
Plug 'easymotion/vim-easymotion'

" -- Insert mode helpers

Plug 'Raimondi/delimitMate'				" auto insert of second ()''{}[]\"\" etc...
Plug 'SirVer/ultisnips'					" Advanced snippets

" -- Text refactor / formater

" One more try with Scry (25 Feb 2018), but @faustinoaq did everything in his
" vscode plugin, not in Scry :/ So not much fancy in Scry for now..
" Plug 'autozimu/LanguageClient-neovim',	" Language Server Protocol support
"             \ {
"             \   'branch': 'next',
"             \   'do': 'bash install.sh',
"             \ }

Plug 'junegunn/vim-easy-align'			" An advanced, easy-to-use Vim alignment plugin.

Plug 'neomake/neomake'					" Asynchronous linting and make framework

" -- UI

Plug 'nathanaelkane/vim-indent-guides'		" Add colored indent guides
Plug 'Shougo/denite.nvim'					" Generic interactive menu framework

Plug 'mhinz/vim-startify'					" add a custom startup screen for vim

Plug 'Bew78LesellB/vim-colors-solarized'	" vim-colors-solarized - favorite colorscheme <3
Plug 'vim-scripts/xterm-color-table.vim'	" Provide some commands to display all cterm colors
Plug 'ryanoasis/vim-devicons'

" -- Per language plugins

"# Vimperator
Plug 'superbrothers/vim-vimperator'

"# C / CPP
Plug 'octol/vim-cpp-enhanced-highlight'	" Better highlight

"# Arduino
"Plug 'jplaut/vim-arduino-ino'			" Arduino project compilation and deploy
"Plug 'sudar/vim-arduino-syntax'			" Arduino syntax
"Plug 'sudar/vim-arduino-snippets'		" Arduino snippets

"# Crystal lang
Plug 'rhysd/vim-crystal'				" Crystal lang integration for vim

"# LLVM IR
Plug 'EdJoJob/llvmir-vim'				" LLVM IR syntax & other stuff

"# Markdown
Plug 'gabrielelana/vim-markdown'		" Complete environment to create Markdown files with a syntax highlight that doesn't suck!
" 'plasticboy/vim-markdown' might be nice too

"# Python
Plug 'hynek/vim-python-pep8-indent'		" PEP8 indentation
Plug 'zchee/deoplete-jedi'				" Jedi powered autocompletion

" More Python tools (e.g: goto def)
Plug 'davidhalter/jedi-vim'
let g:jedi#completions_enabled = 0

" Jinja templating syntax & indent
Plug 'lepture/vim-jinja'

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
let g:deoplete#enable_at_startup = 1

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

" Nice colors for TabLine
hi TabLineSel  cterm=NONE    ctermfg=187 ctermbg=235
hi TabLine     cterm=NONE    ctermfg=230 ctermbg=239
hi TabLineFill cterm=reverse ctermfg=187 ctermbg=244

hi clear Visual Todo
hi Visual ctermbg=238
" We need the ctermbg=NONE at the end, I don't know why...
hi Todo cterm=bold ctermfg=11 ctermbg=NONE

hi Normal ctermfg=248

" Markdown
hi markdownCode ctermfg=29

hi clear BadSpell
hi BadSpell cterm=underline

hi clear SyntasticWarningSign SyntasticErrorSign
hi SyntasticErrorSign ctermfg=1
hi SyntasticWarningSign ctermfg=11

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
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=233
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=235

call s:loadConfigFile("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
	command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
				\ | wincmd p | diffthis
endif

