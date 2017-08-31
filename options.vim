"
" OPTIONS
"

filetype plugin indent on
" Enable omni completion
set omnifunc=syntaxcomplete#Complete

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set backup		" keep a backup file

" always show the statusline
set laststatus=2

set history=99		" keep 99 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands

set hlsearch		" do highlight the serched text
set incsearch		" incremental search as you type

" apply smart case searching
set ignorecase
set smartcase

set number
set relativenumber

set cursorline		" highlight the current line
set cursorcolumn	" highlight the current column

set mouse=nv " normal & visual

set display=lastline

set linebreak		" when 'wrap' is on, wrap the line on word break

set hidden

set timeoutlen=300

" Auto indent the next line
set autoindent

" Completion popup
set pumheight=20

" Show non visible chars (tabs/trailing spaces/too long lines/etc..)
set list
set listchars=tab:·\ ,trail:@,precedes:<,extends:> " how to show differents categories of invisible chars

set scrolloff=3					" minimum lines to keep above and below cursor
set sidescrolloff=16			" minimum chars to keep on the left/right of the cursor
set sidescroll=1				" scroll chars one by one

" Command line options
set wildmenu					" show list instead of just completing
set wildmode=longest:full,full	" commandline <Tab> completion, list matches, then longest common part, then all.

" setup default fold
"set foldmethod=syntax
"set foldcolumn=2
"set nofoldenable " leave fold open on file open

""" Format options

" Disable auto wrap comment automatically
set formatoptions-=c
set formatoptions-=a

" Enable correct comment join (remove comment start)
set formatoptions+=j

"""

""" search ignore

" obj files
set wildignore+=*.o

" java/scala build files
set wildignore+=*.jar
set wildignore+=*.class
set wildignore+=project/target/*
set wildignore+=target/scala*
set wildignore+=target/streams*

" Default indentation
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab " Always expand TAB to spaces


" TODO Setup X clipboard
" > Use register "* for all yank/delete/change
"""" > Use register "+ for X11 clipboard
"set clipboard=unnamed

" Setting colorscheme
set t_Co=256
let g:solarized_termcolors = 256
syntax enable " Not 'syntax on' which overrides colorscheme
colorscheme solarized

set background=dark
if (!has("gui_running"))
	set background=light " this is weird but it fixes dark color...
endif


""""""""""""""""""""""""""""""""""""""""""""""""
" Set backup / swp / undo dirs in ~/.vim/

" Save your backups to a less annoying place than the current directory.
" If you have .vim-backup in the current directory, it'll use that.
" Otherwise it saves it to ~/.vim/backup or . if all else fails.
if isdirectory($HOME . '/.vim/backup') == 0
	:silent !mkdir -p ~/.vim/backup >/dev/null 2>&1
endif
set backupdir-=.
set backupdir+=.
set backupdir-=~/
set backupdir^=~/.vim/backup/
set backupdir^=./.vim-backup/
set backup

" Save your swp files to a less annoying place than the current directory.
" If you have .vim-swap in the current directory, it'll use that.
" Otherwise it saves it to ~/.vim/swap, ~/tmp or .
if isdirectory($HOME . '/.vim/swap') == 0
	:silent !mkdir -p ~/.vim/swap >/dev/null 2>&1
endif
set directory=./.vim-swap//
set directory+=~/.vim/swap//
set directory+=~/tmp//
set directory+=.

if exists("+undofile")
	" undofile - This allows you to use undos after exiting and restarting
	" This, like swap and backups, uses .vim-undo first, then ~/.vim/undo
	" :help undo-persistence
	" This is only present in 7.3+
	if isdirectory($HOME . '/.vim/undo') == 0
		:silent !mkdir -p ~/.vim/undo > /dev/null 2>&1
	endif
	set undodir=./.vim-undo//
	set undodir+=~/.vim/undo//
	set undofile
endif


