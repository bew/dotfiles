" VIM - mappings

" TODO: improve organization!

" Helper guide on <Leader>
nnoremap <Leader> :WhichKey '<Leader>'<cr>
vnoremap <Leader> :WhichKeyVisual '<Leader>'<cr>

" Save buffer
nnoremap <M-s> :w<cr>
inoremap <M-s> <Esc>:w<cr>
vnoremap <M-s> <Esc>:w<cr>

" toggle wrap
nnoremap <M-w> :set wrap! wrap?<cr>

" toggle relativenumber
nnoremap <M-r> :set relativenumber! relativenumber?<cr>

" Toggles signcolumn, number & relativenumber at once
function! ToggleSignsAndLineNumbers()
  if exists('w:saved_signs_and_linenum_options')
    let status = "restored"

    " Restore saved option values
    let &signcolumn = w:saved_signs_and_linenum_options['signcolumn']
    let &number = w:saved_signs_and_linenum_options['number']
    let &relativenumber = w:saved_signs_and_linenum_options['relativenumber']

    unlet w:saved_signs_and_linenum_options
  else
    let status = "saved & disabled"

    " Save options and disable them
    let w:saved_signs_and_linenum_options = {
        \ 'signcolumn': &signcolumn,
        \ 'number': &number,
        \ 'relativenumber': &relativenumber,
        \ }
    let &signcolumn = "no"
    let &number = 0
    let &relativenumber = 0
  endif

  echo "Signs and line numbers: " . l:status
endf
nnoremap <expr> <M-R>  ToggleSignsAndLineNumbers()

nnoremap <M-m> :Neomake<cr>

" Start interactive EasyAlign in visual mode (e.g. vipgea)
xmap gea <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. geaip)
nmap gea <Plug>(EasyAlign)

" Discard last search highlight
nnoremap <silent> § :noh \| echo "Search cleared"<cr>

nnoremap <silent> <C-Space> :CtrlSpace<cr>

nnoremap <M-f> :Denite -start-filter file/rec/smart<cr>
nnoremap <M-F> :Denite -start-filter file/rec<cr>

nnoremap <Leader>/ :Denite grep/rg<cr>
nnoremap <Leader><M-/> :Denite grep<cr>

"-- Navigation
"------------------------------------------------------------------

" Short navigation left/right in insert mode
"
" This makes it possible to use the cursor keys in Insert mode, without breaking
" the undo sequence and therefore using . (redo) will work as expected.
inoremap <Left>  <C-G>U<Left>
inoremap <Right> <C-G>U<Right>
" We use imap to use the above left/right mapping
imap <M-h> <Left>
imap <M-l> <Right>


" Windows navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" When mapping <C-j> has no effect
" nmap <cr> <C-j>

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

" Open current buffer in new tab (in a new window)
nnoremap <silent> <M-t> :tab split<cr>
" Move current window to new tab
nnoremap <silent> <M-T> <C-w>T

" Goto next/previous buffer
nnoremap <M-n> :bnext<cr>
nnoremap <M-p> :bprevious<cr>
" FIXME: I'll probably remove these since they're not that common,
" and the keys could be better used.

" Toggle zoom on current window
" From justinmk' config https://github.com/justinmk/config/blob/a93dc73fafbdeb583ce177a9d4ebbbdfaa2d17af/.config/nvim/init.vim#L880-L894
function! s:zoom_toggle()
  if 1 == winnr('$')
    " There is only one window
    echo "No need to zoom!"
    return
  endif

  if exists('t:zoom_restore')
    " Restore tab layout
    let status = "restored"
    exe t:zoom_restore
    unlet t:zoom_restore
  else
    " Save tab layout & zoom window
    let status = "saved and window zoomed"
    let t:zoom_restore = winrestcmd()
    wincmd |
    wincmd _
  endif

  echo "Tab layout: " . status
endfunction
nnoremap <silent> +  :call <SID>zoom_toggle()<cr>

" Default <C-w>o is dangerous for the layout, hide it behind <C-w>O (maj o)
" Make it zoom instead (saves the layout for restore)
" FIXME: investigate why <C-w>o mapping does not seem to be overriden...
" nnoremap <silent> <C-w>o  :call <SID>zoom_toggle()<cr>
" nnoremap <silent> <C-w>O  :call <C-w>o<cr>


" Visual - Move a selection of text
vnoremap <Left>  <gv
vnoremap <Right> >gv
vnoremap <Up>   :move '<-2<cr>gv
vnoremap <Down> :move '>+1<cr>gv


" Insert empty lines below or above
inoremap <M-o> <C-o>o
inoremap <M-O> <C-o>O
nnoremap <M-o> o<esc>
nnoremap <M-O> O<esc>

" Insert: M-Space <-- [] --> Space
"
" <Space>: add space to the left of cursor:    ab[c]d -> ab [c]d
" <M-Space>: add space to the right of cursor: ab[c]d -> ab[ ]cd
" Note: <C-G>U is used to avoid breaking the undo sequence on cursor movement
inoremap <expr> <M-Space> ' <C-G>U<Left>'

" Move cursor to end of displayed line (useful when text wraps)
nnoremap <M-$> g$

" Insert a new line below using <cr>, useful in comments when `formatoptions`
" has `r` (to auto-add comment start char on <cr> but not o/O) and the cursor
" is not at eol.
inoremap <M-cr> <C-o>A<cr>
" Also works in normal mode, goes in insert mode with a leading comment.
nnoremap <M-cr> A<cr>

" Quickely navigate between quickfix or location list's lines

" quickfix only (M-S-n/p)
nnoremap <M-N> :cnext<cr>
nnoremap <M-P> :cprevious<cr>

" Trigger completion manually
inoremap <expr> <C-b>  deoplete#manual_complete()

" Insert common string during completion
inoremap <expr> <M-b>  deoplete#complete_common_string()


" Exit the terminal grabber
tnoremap <M-q> <C-\><C-n>
tmap  <M-q>

" Shortcut
nnoremap Q :q<cr>

" Indent line(s)
inoremap <Tab> <Esc>mi==`il
vnoremap <Tab> :normal! ==<cr>
" Do not add to normal mode, to keep CTRL-O CTRL-I working to navigate the jump list.
" nnoremap <Tab> mi==`i

" Format the file
nnoremap <C-f> gg=G``

" un-join (split) the current line at the cursor position
nnoremap <M-J> i<c-j><esc>k$

" Copy/Paste with system clipboard
vnoremap <silent> <M-c> :'<,'>w !xclip -in -selection clipboard<cr>
nnoremap <silent> <M-v> :r !xclip -out -selection clipboard<cr>

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first make a new undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-u> <C-g>u<C-u>

" logical undo
nnoremap U <C-r>

" mark position before search
nnoremap / ms/

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
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<cr>
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal @".nr2char(getchar())
endfunction


" Toggle Mundo tree
nnoremap <F5> :MundoToggle<cr>

" Open or focus NERDTree window
nnoremap <F6> :call NERDTreeFocus()<cr>
" Note: Shift-F6 is F16 (on urxvt)
nnoremap <F16> :NERDTreeFind<cr>

" Show highlight infos
function! s:syntax_query(verbose) abort
  if a:verbose == v:true
    let cmd = "verbose hi"
  else
    let cmd = "hi"
  endif

  echo "--- Syntax stack at line:" . line(".") . " col:" . col(".") . " ---"
  for id in synstack(line("."), col("."))
    execute cmd synIDattr(id, "name")
  endfor
endfunction
nnoremap <silent> <F2> :call <SID>syntax_query(v:false)<cr>
nnoremap <silent> <F3> :call <SID>syntax_query(v:true)<cr>

" ---- Command mode

" Save the file as sudo
cnoremap w!! w !env SUDO_ASKPASS=$HOME/.bin/zenity_passwd.sh sudo tee % >/dev/null

" Cursor movement
cnoremap <M-h> <Left>
cnoremap <M-l> <Right>
cnoremap <M-w> <S-Right>
cnoremap <M-b> <S-Left>

" Command history by prefix
cnoremap <M-k> <Up>
cnoremap <M-j> <Down>
" Command history
cnoremap <M-K> <S-Up>
cnoremap <M-J> <S-Down>

" Expand %% to dir of current file
cnoremap <expr> %% expand("%:h") . "/"

" Use this to make a few nice mappings
" Taken from: http://vimcasts.org/episodes/the-edit-command/
nmap <leader>ee  :e %%
nmap <leader>es  :spl %%
nmap <leader>ev  :vsp %%
nmap <leader>et  :tabe %%
