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

" set hlsearch    " do highlight the searched text
" This is the default, and it re-hl the last search when reloading nvim's config, so let's keep it but commented
set incsearch   " incremental search as you type
set inccommand=split " incremental preview of substitution command (NOTE: :s only, not plugin's :S)

" apply smart case searching
set ignorecase
set smartcase

set number
set relativenumber

if has("nvim-0.4.0") " I don't know the exact patch
  " Draw signcolumn only if needed and resize for up to N signs on same line
  set signcolumn=auto:2
endif

set cursorline    " highlight the current line
set cursorcolumn  " highlight the current column

set noequalalways " Avoid windows auto-resizing on win opened/closed

set mouse=nv " Enable mouse in normal & visual

" Change the way text is displayed
set display=
set display+=lastline  " As much as possible of the last line in a window is displayed
set display+=truncate  " Like "lastline" but shows that last line isn't fully rendered
set display+=msgsep    " When showing messages longer than 'cmdheight', only scroll the message lines, not the entire screen.

set showbreak=…… " Prefix for wrapped lines
set linebreak    " Wrapping will break lines on word boundaries

set hidden " Allow to have unsaved hidden buffers

set timeoutlen=1000
set updatetime=500  " Time (ms) before swapfile & CursorHold autocmd triggers

" Auto indent the next line
set autoindent

" Completion popup
set pumheight=20

" Show non visible chars (tabs/trailing spaces/too long lines/etc..)
set list
set listchars=
set listchars+=tab:·\ ,     " Tab char
set listchars+=trail:@,     " Trailing spaces
set listchars+=precedes:<,  " First char when line too long for display
set listchars+=extends:>,   " Last char when line too long for display

" Set the char to use to fill some blanks
set fillchars=
set fillchars+=fold:╶,   " right side of a closed fold (default: '·')
set fillchars+=diff:\ ,  " deleted lines of the 'diff' option (default: '-')
set fillchars+=eob:\ ,   " empty lines at the end of a buffer (default: '~')
set fillchars+=vert:\ ,  " separator between vertical splits

set scrolloff=3         " minimum lines to keep above and below cursor
set sidescrolloff=16      " minimum chars to keep on the left/right of the cursor
set sidescroll=1        " scroll chars one by one

" Command line options
set wildmenu          " show list instead of just completing
set wildmode=longest:full,full  " commandline <Tab> completion, list matches, then longest common part, then all.
set wildignorecase    " ignore case when completing filenames

" setup default fold
"set foldmethod=syntax
"set foldcolumn=2
"set nofoldenable " leave fold open on file open

""" Format options

" Disable auto wrap comment automatically
set formatoptions-=t " for text
set formatoptions-=c " for comments

" Disable auto-format of paragraphs
set formatoptions-=a

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

" vim's continuation line indent defaults to 3 * shiftwidth, it's
" too much, let's reduce it:
let g:vim_indent_cont = 4


" Setting colorscheme
syntax enable " Not 'syntax on' which overrides colorscheme

" Setup swap/undo files
"
" The 'directory' & 'undodir' option ends with '//' so that the swap/undo file
" name will be built from the absolute path to the file with all path separators
" substituted to percent '%' signs. This will ensure file name uniqueness in the
" directory.
set undofile
set swapfile
let swap_undo_dir = $HOME . "/.nvim/swap_undo"
let &directory = swap_undo_dir . "/swapfiles//"
let &undodir = swap_undo_dir . "/undofiles//"
" Ensures the directofies exists!
call mkdir(&directory, "p")
call mkdir(&undodir, "p")
