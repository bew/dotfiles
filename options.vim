"
" OPTIONS
"

filetype plugin indent on
" Enable omni completion
set omnifunc=syntaxcomplete#Complete

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" always show the statusline
set laststatus=2

set history=99    " keep 99 lines of command line history
set ruler   " show the cursor position all the time
set showcmd   " display incomplete commands
set noshowmode  " disable -- INSERT -- (necessary for echodoc plugin)

set hlsearch    " do highlight the searched text
set incsearch   " incremental search as you type

" apply smart case searching
set ignorecase
set smartcase

set number
set relativenumber

set cursorline    " highlight the current line
set cursorcolumn  " highlight the current column

set noequalalways " Avoid windows auto-resizing on win opened/closed

set mouse=nv " Enable mouse in normal & visual

set display=lastline

set showbreak=…… " Prefix for wrapped lines
set linebreak    " Wrapping will break lines on word boundaries

set hidden " Allow to have unsaved hidden buffers

set timeoutlen=300

" Auto indent the next line
set autoindent

" Completion popup
set pumheight=20

" Show non visible chars (tabs/trailing spaces/too long lines/etc..)
set list
set listchars=tab:·\ ,trail:@,precedes:<,extends:> " how to show differents categories of invisible chars

" Set the char to use to fill some blanks
set fillchars=
set fillchars+=fold:╶,   " right side of a closed fold (default: '·')
set fillchars+=diff:\ ,  " deleted lines of the 'diff' option (default: '-')
set fillchars+=eob:\ ,   " empty lines at the end of a buffer (default: '~')

set scrolloff=3         " minimum lines to keep above and below cursor
set sidescrolloff=16      " minimum chars to keep on the left/right of the cursor
set sidescroll=1        " scroll chars one by one

" Command line options
set wildmenu          " show list instead of just completing
set wildmode=longest:full,full  " commandline <Tab> completion, list matches, then longest common part, then all.

" setup default fold
"set foldmethod=syntax
"set foldcolumn=2
"set nofoldenable " leave fold open on file open

""" Format options

" Disable auto wrap comment automatically
set formatoptions-=a " for text
set formatoptions-=c " for comments

" Enable auto comment new line when pressing <Enter> in insert mode
set formatoptions+=r

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
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab " Always expand TAB to spaces


" Setting colorscheme
syntax enable " Not 'syntax on' which overrides colorscheme

let g:solarized_termcolors = 256
colorscheme solarized

if $TERM_COLOR_MODE == 'light'
  " Default for solarized is light
  set background=light
else
  set background=dark
endif


""""""""""""""""""""""""""""""""""""""""""""""""
" Put swap & undo files in ~/.nvim/swap_undo/{swap,undo}files/

let swap_undo_dir = $HOME . '/.nvim/swap_undo'

set undofile
set swapfile

let &directory = swap_undo_dir . '/swapfiles'
let &undodir = swap_undo_dir . '/undofiles'

" Ensures the directofies exists!
call mkdir(swap_undo_dir . '/swapfiles', 'p')
call mkdir(swap_undo_dir . '/undofiles', 'p')
