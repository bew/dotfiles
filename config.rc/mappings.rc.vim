" VIM - mappings

" Easy short navigation in insert mode
inoremap <A-h> <Left>
inoremap <A-l> <Right>
" thoses might be removed:
inoremap <C-h> <Left>
inoremap <C-l> <Right>

" Easy windows navigation
nnoremap <BS> <C-w>h
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Redraw
nnoremap <C-r> <C-l>

" Save buffer
nnoremap <M-Space> :w<cr>
inoremap <M-Space> <Esc>:w<cr>
nnoremap <M-s> :w<cr>
inoremap <M-s> <Esc>:w<cr>

" I don't use theses, but it may be useful when
" <M-Space> is not available (on some terminal)
nnoremap <C-s> :w<cr>
inoremap <C-s> <Esc>:w<cr>

"-- Toggle
"------------------------------------------------------------------

" wrap
nnoremap <M-w> :set wrap! wrap?<cr>

" relativenumber
nnoremap <M-r>	:set relativenumber! relativenumber?<CR>


" Start interactive EasyAlign in visual mode (e.g. vipgea)
xmap gea <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. geaip)
nmap gea <Plug>(EasyAlign)

" Open Tagbar
nnoremap <F8> :TagbarToggle<CR>

" Discard last search highlight
nnoremap <silent> § :noh \| echo "Search cleared"<cr>

nnoremap <silent> <C-Space> :<C-u>CtrlSpace<cr>

nnoremap <M-g> :<C-u>IndentGuidesToggle<cr>

"-- Navigation
"------------------------------------------------------------------

" Goto tabs
nnoremap <M-J> gT
nnoremap <M-K> gt
inoremap <M-J> <esc>gT
inoremap <M-K> <esc>gt

" Move tabs
nnoremap <M-H> :tabmove -1<cr>
nnoremap <M-L> :tabmove +1<cr>
inoremap <M-H> <esc>:tabmove -1<cr>
inoremap <M-L> <esc>:tabmove +1<cr>



"-- Visual Mapping
"------------------------------------------------------------------

vnoremap <Left> <gv
vnoremap <Right> >gv
vnoremap <Up> :m '<-2<cr>gv
vnoremap <Down> :m '>+1<cr>gv


"-- Normal helper
"------------------------------------------------------------------

nnoremap <M-o> o<esc>
nnoremap <M-O> O<esc>

nnoremap Q :q<cr>

" THE missing one:
"nnoremap ci( f(ci) " not working... :(

"-- Insert helper
"------------------------------------------------------------------

" Insert a tabulation (Alt + i) in insert mode
inoremap <M-i> <C-V><Tab>

inoremap <M-o> <C-o>o
inoremap <M-O> <C-o>O

" Disbale <M-i> in normal mode, as it hangs the terminal
nnoremap <M-i> <nop>

" Indent line in normal and insert mode (return to normal mode)
nnoremap <Tab> mi==`i
inoremap <Tab> <Esc>mi==`il

" Indent visual selection
" note that '<,'> is automatically inserted when pressing ':' in visual mode
vnoremap <Tab> :normal! ==<cr>

"-- Global code Manipulation
"------------------------------------------------------------------

" Format the file
nnoremap <C-f> gg=G``

"-- Vim dev helpers
"------------------------------------------------------------------

" Show highlight infos
nmap <F2> :echom "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">" <CR>

" Toggle PASTE mode
nnoremap <M-p> :set paste! paste?<CR>

"-- OS integration
"------------------------------------------------------------------

" Copy/Paste with system clipboard
" > copy from visual mode
vnoremap <M-c> :'<,'>w !xclip -in -selection clipboard<cr>
" > paste in normal mode
nnoremap <silent> <M-v> :r !xclip -out -selection clipboard<cr>

" ask for sudo passwd and save the file
cnoremap w!! w !sudo tee % >/dev/null


" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first make a new undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" logical undo
nnoremap U <C-r>


" Taken from visual-at.vim from Practical Vim 2nd Edition
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
	echo "@".getcmdline()
	execute ":'<,'>normal @".nr2char(getchar())
endfunction


" Some plugins mapping

nnoremap <F5> :GundoToggle<CR>

