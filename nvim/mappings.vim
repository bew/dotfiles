" VIM - mappings

" TODO: improve organization!

" Disable keybindings

" <C-LeftMouse> default to <C-]> but it's annoying to have it everywhere
" (like in markdown files).
" Also, I use Ctrl LeftMouse's Up event on my terminal to open links, the Down
" event will always be passed to the application (neovim) so I must handle it
" gracefully (disable!).
nnoremap <C-LeftMouse> <nop>

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

" Start interactive EasyAlign in visual mode (e.g. vipgea)
xmap gea <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. geaip)
nmap gea <Plug>(EasyAlign)

" Discard last search highlight
nnoremap <silent> § :noh \| echo "Search cleared"<cr>

nnoremap <silent> <C-Space> :CtrlSpace<cr>

nnoremap <M-f> :FilesSmart<cr>
nnoremap <M-F> :Files<cr>

" Focus or create a Floaterm with the given name.
" Hides the current Floaterm if any.
function! s:FloatermFocusOrNew(name, cmd)
  let target_bufnr = floaterm#terminal#get_bufnr(a:name)
  let curr_bufnr = bufnr()

  if getwininfo(win_getid())[0].terminal == 1
    " Hide the floaterm if the current terminal is a floaterm
    call floaterm#window#hide_floaterm(l:curr_bufnr)
    if l:curr_bufnr == l:target_bufnr
      return
    endif
  endif

  if l:target_bufnr != -1
    call floaterm#terminal#open_existing(l:target_bufnr)
  else
    call floaterm#new(a:cmd, {"name": a:name}, {}, v:false)
  endif
endf
nnoremap <silent> <M-y> :call <SID>FloatermFocusOrNew("scratch", "zsh")<cr>
tnoremap <silent> <M-y> <C-\><C-n>:call <SID>FloatermFocusOrNew("scratch", "zsh")<cr>

nnoremap <silent> <M-Y> :call <SID>FloatermFocusOrNew("scratch-alt", "zsh")<cr>
tnoremap <silent> <M-Y> <C-\><C-n>:call <SID>FloatermFocusOrNew("scratch-alt", "zsh")<cr>

"-- Navigation
"------------------------------------------------------------------

" Short navigation on the line in insert mode
"
" This makes it possible to use the cursor keys in Insert mode, without breaking
" the undo sequence and therefore using . (redo) will work as expected.
inoremap <Left>  <C-g>U<Left>
inoremap <Right> <C-g>U<Right>
" We use imap to use the above left/right mapping
imap <M-h> <Left>
imap <M-l> <Right>
" Move back/forward by word, I'm too used to it in the shell and nvim's
" cmdline!
inoremap <M-b> <C-g>U<S-Left>
inoremap <M-w> <C-g>U<S-Right>


" Windows navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" When mapping <C-j> has no effect
" nmap <cr> <C-j>

" When mapping <C-h> has no effect
" nmap <BS> <C-h>


" Goto tabs Alt-a/z
nnoremap <M-a> gT
nnoremap <M-z> gt
inoremap <M-a> <esc>gT
inoremap <M-z> <esc>gt

" Move tabs Alt-A/Z
nnoremap <M-A> :tabmove -1<cr>
nnoremap <M-Z> :tabmove +1<cr>
inoremap <M-A> <esc>:tabmove -1<cr>
inoremap <M-Z> <esc>:tabmove +1<cr>

" Close tab Alt-d (with confirmation)
nnoremap <M-d> :call <SID>TabCloseWithConfirmation()<cr>
function! s:TabCloseWithConfirmation()
  if len(gettabinfo()) == 1
    echo "Cannot close last tab"
    return
  endif
  let choice = confirm("Close tab?", "&Yes\n&Cancel", 0)
  redraw " clear cmdline, remove the confirm prompt
  if choice == 1   " Yes
    tabclose
  else
    echo "Close tab cancelled"
  endif
endf

" Open current buffer in new tab (in a new window)
nnoremap <silent> <M-t> :tab split<cr>
" Move current window to new tab
nnoremap <silent> <M-T> <C-w>T

" Goto next/previous buffer
nnoremap <M-n> :bnext<cr>
nnoremap <M-p> :bprevious<cr>
" FIXME: I'll probably remove these since they're not that common,
" and the keys could be better used.
" > Maybe use <Tab> <S-Tab> for tab-local-n/p-buffer & <M-Tab> <M-S-Tab> for global-n/p-buffer

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


" V: Move a selection of text
" Indent/Dedent
vnoremap <Left>  <gv
vnoremap <Right> >gv
" Move Up/Down
" TODO: make it work with v:count ?
vnoremap <Up>   :move '<-2<cr>gv
vnoremap <Down> :move '>+1<cr>gv


" Insert empty lines below or above
inoremap <M-o> <C-o>o
inoremap <M-O> <C-o>O
nnoremap <M-o> o<esc>
nnoremap <M-O> O<esc>

" I: M-Space <-- [] --> Space
"
" <Space>: add space to the left of cursor:    ab[c]d -> ab [c]d
" <M-Space>: add space to the right of cursor: ab[c]d -> ab[ ]cd
" Note: <C-G>U is used to avoid breaking the undo sequence on cursor movement
" meaning that we can repeat (with .) a change that includes a cursor
" movement.
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


" Exit the terminal grabber
tnoremap <M-q> <C-\><C-n>
tmap  <M-q>

" Shortcut
nnoremap Q :q<cr>

" Indent/Format lines/file
" I: Indent line, stay in insert mode (default, see :h i_CTRL-F)
inoremap <C-f> <C-f>
" V: Indent visual selection, back to normal mode
vnoremap <C-f> =
" N: Indent current line
nnoremap <C-f> mi==`i
" N: Format the entire file
nnoremap <M-C-f> gg=G``


" un-join (split) the current line at the cursor position
nnoremap <M-J> i<c-j><esc>k$

" Copy/Paste with system clipboard (using nvim's clipboard provider)
" Register "+ is session clipboard
" Register "* is OS/system clipboard
let g:clipboard = {
    \   'name': 'myClipboard',
    \   'copy': {
    \      '+': 'cli-clipboard-provider copy-to smart-session',
    \      '*': 'cli-clipboard-provider copy-to system',
    \    },
    \   'paste': {
    \      '+': 'cli-clipboard-provider paste-from smart-session',
    \      '*': 'cli-clipboard-provider paste-from system',
    \   },
    \ }

" Copy
xnoremap <M-c> "+y :echo "Copied to session clipboard!"<cr>
xnoremap <M-C> "*y :echo "Copied to system clipboard!"<cr>

" Paste
nnoremap <M-v> "+p
nnoremap <M-V> o<esc>"+p
xnoremap <M-v> "+p
cnoremap <M-v> <C-r>+
" Paste in insert mode inserts an undo breakpoint
inoremap <silent> <M-v> <C-g>u<C-r>+
" TODO?: Add system paste bindings

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first make a new undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-u> <C-g>u<C-u>

" logical undo
nnoremap U <C-r>

" mark position before search
nnoremap / ms/

" Search with{,out} word boundaries
" V: search selection with word boundaries
vmap * <Plug>(visualstar-*)
" V: search selection without word boundaries
vmap <M-*> <Plug>(visualstar-g*)
" N: search current word without word boundaries
nnoremap <M-*> g*

vnoremap <M-p> <cmd>call VisualPaste()<cr>
" Visual paste with the current register, preserving the content of
" the unnamed register.
function! VisualPaste()
  " Save unnamed register (will be overwritten with the normal visual paste)
  let save_reg = getreg('"', 1, v:true)
  let save_regtype = getregtype('"')

  exe 'normal! "' . v:register . 'p'

  " Restore unnamed register
  call setreg('"', save_reg, save_regtype)
endfunction


" Taken from visual-at.vim from Practical Vim 2nd Edition
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<cr>
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal! @".nr2char(getchar())
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


" ---- Various Leader key mappings ----
" (NOTE: some mappings are in init.vim)
"
" Nice example of mappings! (https://github.com/phaazon/config/blob/ea8378065/nvim/key_bindings.vim)

" Helper guide on <Leader>
nnoremap <Leader> <cmd>WhichKey '<Space>'<cr>
vnoremap <Leader> <cmd>WhichKeyVisual '<Space>'<cr>

" -- Code
let g:which_key_map.c = {"name": "+code"}

" code comment
let g:which_key_map.c.c = {"name": "+comment"}
nmap <Leader>cc<space> <plug>NERDCommenterToggle
vmap <Leader>cc<space> <plug>NERDCommenterToggle
nmap <Leader>ccc       <plug>NERDCommenterComment
nmap <Leader>ccu       <plug>NERDCommenterUncomment
nmap <Leader>cci       <plug>NERDCommenterInvert
let g:which_key_map.c.c["<space>"] = "toggle"
let g:which_key_map.c.c.c = "force"
let g:which_key_map.c.c.u = "remove"
let g:which_key_map.c.c.i = "invert"

" code language tools (not done globally.. LSP would solve this..)
" cr   rename
" cu   show usages
" cd   goto definition
"
" Currently my main usage is with jedi-vim, which I configure manually
" when a python buffer opens.
" NOTE: I don't know how to set a which_key_map for a single buffer

" -- Edit
let g:which_key_map.e = {"name": "+edit"}
" Use this to make a few nice mappings
" Taken from: http://vimcasts.org/episodes/the-edit-command/
nmap <leader>ee  :e %%
nmap <leader>es  :spl %%
nmap <leader>ev  :vsp %%
nmap <leader>et  :tabe %%
let g:which_key_map.e.e = "relative here"
let g:which_key_map.e.s = "relative in split"
let g:which_key_map.e.v = "relative in vertical split"
let g:which_key_map.e.t = "relative in tab"

" -- Git
nmap <leader>hp <Plug>(GitGutterPreviewHunk)
nmap <leader>hu <Plug>(GitGutterUndoHunk)
nmap <leader>hf <cmd>GitGutterFold<cr>
let g:which_key_map.h = {"name": "+git-hunks"}
let g:which_key_map.h.p = "preview"
let g:which_key_map.h.u = "undo"
let g:which_key_map.h.f = "fold non-hunk"
