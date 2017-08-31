set nocompatible
call plug#begin('~/.config/nvim/plugged')

" -- Vim feature enhancer

Plug 'sjl/gundo.vim'					" undo tree
Plug 'szw/vim-ctrlspace'				" Control your space (buffers/tags/workspaces/etc..)
Plug 'tpope/vim-abolish'				" Helpers for abbreviation, cased substitution & coercion
Plug 'thinca/vim-visualstar'			" * for visualy selected text
Plug 'mileszs/ack.vim'					" Use ack for vimgrep
"Plug 'pelodelfuego/vim-swoop'			" Search everywhere with context
Plug 'tpope/vim-surround'				" vim-surround
Plug 'scrooloose/nerdcommenter'			" Dark powred commenter
Plug 'itchyny/lightline.vim'			" statusline builder
Plug 'Shougo/vimfiler.vim'				" File explorer

" Dependency of vimfiler, as it doesn't support denite...
Plug 'Shougo/unite.vim'

" -- Insert mode helpers

Plug 'Raimondi/delimitMate'				" auto insert of second ()''{}[]\"\" etc...
Plug 'SirVer/ultisnips'					" Advanced snippets

" -- Text refactor / formater

Plug 'junegunn/vim-easy-align'			" An advanced, easy-to-use Vim alignment plugin.

Plug 'neomake/neomake'					" Asynchronous linting and make framework
Plug 'Shougo/deoplete.nvim',			" Dark powered asynchronous completion framework
			\ { 'do': ':UpdateRemotePlugins' }

" -- UI

Plug 'nathanaelkane/vim-indent-guides'		" Add colored indent guides
Plug 'Shougo/denite.nvim'					" Generic interactive menu framework

Plug 'mhinz/vim-startify'					" add a custom startup screen for vim

Plug 'Bew78LesellB/vim-colors-solarized'	" vim-colors-solarized - favorite colorscheme <3
Plug 'xterm-color-table.vim'				" Provide some commands to display all cterm colors
Plug 'ryanoasis/vim-devicons'

" -- Per language plugins

" Vimperator
Plug 'superbrothers/vim-vimperator'

" Markdown
"Plug 'gabrielelana/vim-markdown' " markdown advanced syntax highlighter and editor

" C / CPP
Plug 'octol/vim-cpp-enhanced-highlight'	" Better highlight

" Arduino
"Plug 'jplaut/vim-arduino-ino'			" Arduino project compilation and deploy
"Plug 'sudar/vim-arduino-syntax'			" Arduino syntax
"Plug 'sudar/vim-arduino-snippets'		" Arduino snippets

" OCaml
"Plug 'the-lambda-church/merlin'			" Context sensitive completion for OCaml + errors + type infos + source browsing
"Plug 'vim-scripts/omlet.vim'			" This mode offers automatic indentation and keyword highlighting

" Crystal lang
Plug 'rhysd/vim-crystal'				" Crystal lang integration for vim

" Scala
Plug 'derekwyatt/vim-scala'				" Syntax highlighting
Plug 'ensime/ensime-vim'

" Python
Plug 'hynek/vim-python-pep8-indent'		" PEP8 python indentation
Plug 'zchee/deoplete-jedi'				" Jedi powered autocompletion
Plug 'lepture/vim-jinja'				" Jinja templating syntax & indent

call plug#end()

" Config Helper - TODO: convert as a vim plugin (customizable)
if has('win32') || has('win64')
	let $VIMHOME = $VIM."/vimfiles" " Note: I never tested on windows!
else
	let $VIMHOME = $HOME."/.config/nvim"
endif

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
	if s:sourceFile($VIMHOME . "/config.rc/" . a:path)
		return
	endif
	if s:sourceFile($VIMHOME . "/config.rc/" . a:path . ".rc.vim")
		return
	endif
endfunction

function! s:loadConfigDir(dirpath)
	for filepath in split(globpath($VIMHOME . "/config.rc/" . a:dirpath, "*.rc.vim"), "\n")
		call s:loadConfigFile(filepath)
	endfor
endfunction


"""""""""""""""""""""""""""""""""

call s:loadConfigDir("plugins")
let g:deoplete#enable_at_startup = 1

if (has("gui"))
	" Disable every gvim gui stuff
	set guioptions=
	set guifont=DejaVu\ Sans\ Mono\ for\ Powerline\ 11
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

