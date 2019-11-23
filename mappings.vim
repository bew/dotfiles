" VIM - mappings

" Redraw
nnoremap <C-r> <C-l>

" Save buffer
nnoremap <M-Space> :w<cr>
inoremap <M-Space> <Esc>:w<cr>
vnoremap <M-Space> <Esc>:w<cr>
nnoremap <M-s> :w<cr>
inoremap <M-s> <Esc>:w<cr>
vnoremap <M-s> <Esc>:w<cr>

" toggle wrap
nnoremap <M-w> :set wrap! wrap?<cr>

" toggle relativenumber
nnoremap <M-r>  :set relativenumber! relativenumber?<CR>

nnoremap <M-m> :Neomake<cr>

" Start interactive EasyAlign in visual mode (e.g. vipgea)
xmap gea <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. geaip)
nmap gea <Plug>(EasyAlign)

" Discard last search highlight
nnoremap <silent> § :noh \| echo "Search cleared"<cr>

nnoremap <silent> <C-Space> :CtrlSpace<cr>
nnoremap <M-f> :FZF<cr>

" Toggle indent guides
nnoremap <M-g> :IndentGuidesToggle<cr>

"-- Navigation
"------------------------------------------------------------------

" Short navigation left/right in insert mode
inoremap <M-h> <Left>
inoremap <M-l> <Right>


" Windows navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" When mapping <C-j> has no effect
nmap <cr> <C-j>

" When mapping <C-h> has no effect
nmap <BS> <C-h>


" Goto tabs
nnoremap <M-J> gT
nnoremap <M-K> gt
inoremap <M-J> <esc>gT
inoremap <M-K> <esc>gt
" experimental version Alt-a/z
nnoremap <M-a> gT
nnoremap <M-z> gt
inoremap <M-a> <esc>gT
inoremap <M-z> <esc>gt


" Move tabs
nnoremap <M-H> :tabmove -1<cr>
nnoremap <M-L> :tabmove +1<cr>
inoremap <M-H> <esc>:tabmove -1<cr>
inoremap <M-L> <esc>:tabmove +1<cr>
" experimental version Alt-Shift-a/z
nnoremap <M-A> :tabmove -1<cr>
nnoremap <M-Z> :tabmove +1<cr>
inoremap <M-A> <esc>:tabmove -1<cr>
inoremap <M-Z> <esc>:tabmove +1<cr>

" Goto next/previous buffer
nnoremap <M-n> :bnext<cr>
nnoremap <M-p> :bprevious<cr>


" Visual - Move a selection of text
vnoremap <Left> <gv
vnoremap <Right> >gv
vnoremap <Up> :move '<-2<cr>gv
vnoremap <Down> :move '>+1<cr>gv


" Insert empty lines below or above
inoremap <M-o> <C-o>o
inoremap <M-O> <C-o>O
nnoremap <M-o> o<esc>
nnoremap <M-O> O<esc>

" Move cursor to end of displayed line (useful when text wraps)
nnoremap <M-$> g$

" Insert a new line below using <cr>, useful in comments when `formatoptions`
" has `r` (to auto-add comment start char on <cr> but not o/O) and the cursor
" is not at eol.
inoremap <M-CR> <C-o>A<cr>
" Also works in normal mode, goes in insert mode with a leading comment.
nnoremap <M-CR> A<cr>

" Quickely navigate between quickfix or location list's lines

" quickfix only (M-S-n/p)
nnoremap <M-N> :cnext<cr>
nnoremap <M-P> :cprevious<cr>

nnoremap <leader>j :call GotoQfOrLoc("next", "first")<cr>
nnoremap <leader>k :call GotoQfOrLoc("previous", "last")<cr>

" First try the quickfix list, if empty, uses the location list
function! GotoQfOrLoc(direction, rewind_name)
    let qflist = getqflist()
    let loclist = getloclist(0)

    if len(qflist) == 1
        exe ":cc"
    elseif len(qflist) > 1
        try
            exe ":c" . a:direction
        catch
            echom "No more items, rewinding.."
            exe ":c" . a:rewind_name
        endtry
    elseif len(loclist) == 1
        exe ":ll"
    elseif len(loclist) > 1
        try
            exe ":l" . a:direction
        catch
            echom "No more items, rewinding.."
            exe ":l" . a:rewind_name
        endtry
    else
        echo "Nothing in quickfix or location list"
    endif
endfunction

" Trigger completion manually
inoremap <expr> <C-b> deoplete#manual_complete()

" Insert common string during completion
inoremap <expr> <M-b> deoplete#complete_common_string()


" Exit the terminal grabber
tnoremap <M-q> <C-\><C-n>
tmap  <M-q>

" Shortcut
nnoremap Q :q<cr>

" THE missing one (and still not working :/)
"nnoremap ci( f(ci)
"nnoremap ci) F)ci)

" Insert a TAB (thanks Epitech for that habit)
inoremap <M-i> <C-v><Tab>

" Disable <M-i> in normal mode, otherwise it hangs the terminal
nnoremap <M-i> <nop>


" Indent line(s)
nnoremap <Tab> mi==`i
inoremap <Tab> <Esc>mi==`il

" note: '<,'> is automatically inserted on ':'
vnoremap <Tab> :normal! ==<cr>

" Format the file
nnoremap <C-f> gg=G``


" Copy/Paste with system clipboard
vnoremap <silent> <M-c> :'<,'>w !xclip -in -selection clipboard<cr>
nnoremap <silent> <M-v> :r !xclip -out -selection clipboard<cr>

" Save the file as sudo
cnoremap w!! w !env SUDO_ASKPASS=$HOME/.bin/zenity_passwd.sh sudo tee % >/dev/null


" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first make a new undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-u> <C-g>u<C-u>

" logical undo
nnoremap U <C-r>

" Search with{,out} word boundaries
vmap * <Plug>(visualstar-*)
vmap <M-*> <Plug>(visualstar-g*)
nmap <M-*> g*

vnoremap <M-p> :call VisualPaste()<cr>
function! VisualPaste()
  " NOTE: unnamed register " is preserved
  let old_reg = getreg('"', 1, v:true)
  let old_regtype = getregtype('"')

  normal gvp

  call setreg('"', old_reg, old_regtype)
endfunction


" Taken from visual-at.vim from Practical Vim 2nd Edition
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction


" Toggle Mundo tree
nnoremap <F5> :MundoToggle<cr>

" Open or focus NERDTree window
nnoremap <F6> :call NERDTreeFocus()<CR>
if !has('mac')
    " Note: Shift-F6 is F16 (on urxvt)
    nnoremap <F16> :NERDTreeFind<CR>
else
    " Note: Shift-F6 is F18 (on iTerm2)
    nnoremap <F18> :NERDTreeFind<CR>
endif

" Show highlight infos
nmap <F2> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">" <CR>

