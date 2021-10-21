" This file configures neovim-qt with a config for Windows.
" it should be saved to C:\Users\YOUR_NAME\AppData\Local\nvim\init.vim
" vim:set ff=dos:

" --- Options

set mouse=nv
set number
set relativenumber
set cursorline

set pumheight=20
set completeopt=menuone,preview,longest

set shiftwidth=4
set expandtab

set linebreak " Break lines on word boundaries

" --- Colors fixes
hi Visual ctermbg=239 guibg=#555555
hi Pmenu ctermbg=23 guibg=#005F5F
hi TabLine cterm=none gui=none ctermfg=0 guifg=Black
hi CursorLine cterm=none ctermbg=237 guibg=#353535
hi CursorColumn cterm=none ctermbg=237 guibg=#353535

" Slightly less dark/brigh normal bg/fg
hi Normal guibg=#121212 guifg=#cccccc

function! s:GuiMyInit()
    " Disable 'Gui' features (I prefer 'Terminal' ones)
    GuiPopupmenu v:false
    GuiTabline v:false

    " Set font (ignore warnings)
    GuiFont! Consolas:h14
endfunction
autocmd User GuiInitialized call <SID>GuiMyInit()
" TODO: Add a way to increase/decrease the font size?

" --- Mappings

let mapleader = " "

" Save / Quit
nnoremap <M-s> :w<cr>
inoremap <M-s> <esc>:w<cr>
nnoremap Q :q<cr>

" Tabs
nnoremap <M-z> gt
nnoremap <M-a> gT
nnoremap <M-Z> :tabmove +1<cr>
nnoremap <M-A> :tabmove -1<cr>

" Windows
nnoremap <C-h> <C-w><C-h>
nnoremap <C-j> <C-w><C-j>
nnoremap <C-k> <C-w><C-k>
nnoremap <C-l> <C-w><C-l>

nnoremap § :nohl<cr>

" Cmdline
cnoremap <M-h> <Left>
cnoremap <M-j> <Down>
cnoremap <M-k> <Up>
cnoremap <M-l> <Right>

cnoremap <M-w> <S-Right>
cnoremap <M-b> <S-Left>

" Expand %% to dir of current file
cnoremap <expr> %% expand("%:h") . "/"

" Edits
nnoremap U <C-r>

inoremap <M-o> <C-o>o
inoremap <M-O> <C-o>O
nnoremap <M-o> o<esc>
nnoremap <M-O> O<esc>

nnoremap <expr> j (v:count == 0) ? 'gj' : 'j'
nnoremap <expr> k (v:count == 0) ? 'gk' : 'k'

" In neovim-qt on windows, I can't get ~ to work.
nnoremap gs ~
vnoremap gs ~

" Open files
" Taken from: http://vimcasts.org/episodes/the-edit-command/
nmap <leader>ee  :e %%
nmap <leader>es  :spl %%
nmap <leader>ev  :vsp %%
nmap <leader>et  :tabe %%

" Copy/Paste with system clipboard (using nvim's clipboard provider)
" Copy
vnoremap <silent> <M-c> "+y:echo "Copied!"<cr>
" Paste
nnoremap <silent> <M-v> "+p
nnoremap <silent> <M-V> o<C-u><esc>"+p
vnoremap <silent> <M-v> "+p
cnoremap <silent> <M-v> <C-r><C-o>+
" Paste in insert mode inserts an undo breakpoint
inoremap <silent> <M-v> <C-g>u<C-r>+
