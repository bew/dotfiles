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
nnoremap <silent> <M-s> :w<cr>
inoremap <silent> <M-s> <Esc>:w<cr>
vnoremap <silent> <M-s> <Esc>:w<cr>

" toggle wrap
nnoremap <silent> <M-w> :set wrap! wrap?<cr>

" toggle relativenumber
nnoremap <silent> <M-r> :set relativenumber! relativenumber?<cr>

" Toggles signcolumn, number & relativenumber at once
function! ToggleSignsAndLineNumbers()
  if exists('w:saved_signs_and_linenum_options')
    let status = "restored"

    " Restore saved option values
    let &signcolumn = w:saved_signs_and_linenum_options['signcolumn']
    let &number = w:saved_signs_and_linenum_options['number']
    let &relativenumber = w:saved_signs_and_linenum_options['relativenumber']

    if w:saved_signs_and_linenum_options["indentLine_enabled"]
      IndentLinesEnable
    endif

    unlet w:saved_signs_and_linenum_options
  else
    let status = "saved & disabled"

    " Save options and disable them
    let w:saved_signs_and_linenum_options = {
        \ 'signcolumn': &signcolumn,
        \ 'number': &number,
        \ 'relativenumber': &relativenumber,
        \ }
    if exists("b:indentLine_enabled")
      " If the buffer local var exists, g:indentLine_enabled should not be checked
      " (it's always 1, even when disabled locally)
      let w:saved_signs_and_linenum_options.indentLine_enabled = b:indentLine_enabled
    else
      let w:saved_signs_and_linenum_options.indentLine_enabled = g:indentLine_enabled
    endif
    let &signcolumn = "no"
    let &number = 0
    let &relativenumber = 0
    IndentLinesDisable
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

nnoremap <silent> <M-f> :FilesSmart<cr>
nnoremap <silent> <M-F> :Files<cr>

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
nnoremap <silent> <M-A> :tabmove -1<cr>
nnoremap <silent> <M-Z> :tabmove +1<cr>
inoremap <silent> <M-A> <esc>:tabmove -1<cr>
inoremap <silent> <M-Z> <esc>:tabmove +1<cr>

" Close tab Alt-d (with confirmation)
nnoremap <silent> <M-d> :call <SID>TabCloseWithConfirmation()<cr>
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
nnoremap <silent> <M-n> :bnext<cr>
nnoremap <silent> <M-p> :bprevious<cr>
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
" TODO: investigate why <C-w>o mapping does not seem to be overriden...
" nnoremap <silent> <C-w>o  :call <SID>zoom_toggle()<cr>
" nnoremap <silent> <C-w>O  :call <C-w>o<cr>


" V: Move a selection of text
" Indent/Dedent
vnoremap <Left>  <gv
vnoremap <Right> >gv
" Move Up/Down
" TODO: make it work with v:count ?
vnoremap <silent> <Up>   :move '<-2<cr>gv
vnoremap <silent> <Down> :move '>+1<cr>gv


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
inoremap <M-$> <End>

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
nnoremap <silent> Q :q<cr>

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
" Register '+' is session clipboard (e.g: tmux)
" Register '*' is OS/system clipboard
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
xnoremap <silent> <M-c> "+y :echo "Copied to session clipboard!"<cr>
xnoremap <silent> <M-C> "*y :echo "Copied to system clipboard!"<cr>

" Paste
nnoremap <M-v> "+p
nnoremap <M-V> o<esc>"+p
xnoremap <M-v> "+p
cnoremap <M-v> <C-r><C-o>+
" Paste in insert mode inserts an undo breakpoint
" C-r C-o {reg}    -- inserts the reg content literaly
inoremap <silent> <M-v> <C-g>u<C-r><C-o>+
" TODO?: Add system paste bindings

" Copy absolute filepath
nnoremap <silent> y%% :let @" = expand("%:p") \| echo "File path copied (" . @" . ")"<cr>

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first make a new undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-u> <C-g>u<C-u>

" logical undo
nnoremap U <C-r>

" Select last inserted region
nnoremap gV `[v`]

" mark position before search
nnoremap / ms/

" Vim eval-and-replace:
" Evaluate the current selection as a vimscript expression and replace
" the selection with the result
" NOTE1: changes the unnamed register
" NOTE2: <C-r><C-r>{register} takes the register content verbatim
"   (whereas <C-r> inserts the register content as if typed)
vnoremap <Plug>(my-EvalAndReplaceVimExpr-visual) c<C-r>=<C-r><C-r>"<cr><esc>

" Vim eval-as-ex:
" Run the current line/selection as an EX command
" NOTE: changes the unnamed register
function! s:EvalAsExFromUnnamed()
  let l:splitted_reg = split(@", "\n")
  echom "Sourcing " . len(l:splitted_reg) . " lines..."
  execute @"
  echom "Done sourcing " . len(l:splitted_reg) . " lines!"
endf
nnoremap <Plug>(my-EvalAsVimEx-normal) yy:call <SID>EvalAsExFromUnnamed()<cr>
vnoremap <Plug>(my-EvalAsVimEx-visual) y:call <SID>EvalAsExFromUnnamed()<cr>

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
xnoremap <silent> @ :<C-u>call ExecuteMacroOverVisualRange()<cr>
function! ExecuteMacroOverVisualRange()
  echo "@".getcmdline()
  execute ":'<,'>normal! @".nr2char(getchar())
endfunction

" Fold ranged open/close
" NOTE: this does not change the 'foldlevel'.
" FIXME: these mappings must be typed fast, otherwise you get normal behavior.
" Make sure to read `:h fold-commands` for all the details.
" open all folds in range
vnoremap <silent> zo  :<C-u>'<,'>foldopen!<cr>
" close all manually opened folds in range
vnoremap <silent> zc  zx

" Duplicate the visual selection
vnoremap <C-d> <cmd>call <sid>DuplicateVisualSelection()<cr>
function! s:DuplicateVisualSelection()
  " Save unnamed register (will be overwritten when copying current visual selection)
  let save_reg = getreg('"', 1, v:true)
  let save_regtype = getregtype('"')

  " Copy, go to the end of the selection, paste
  exe 'normal! y`>p'

  " Restore unnamed register
  call setreg('"', save_reg, save_regtype)
endf

" Toggle Mundo tree
nnoremap <silent> <F5> :MundoToggle<cr>

" Open or focus NERDTree window
nnoremap <silent> <F6> :call NERDTreeFocus()<cr>
" Note: Shift-F6 is F16 (on urxvt)
nnoremap <silent> <F16> :NERDTreeFind<cr>

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

" -- Vim
nmap <leader>vx <Plug>(my-EvalAsVimEx-normal)
vmap <leader>vx <Plug>(my-EvalAsVimEx-visual)
" let g:which_key_nmap.v = {"name": "+vim"}
" let g:which_key_vmap.v = deepcopy(g:which_key_nmap.v)
" let g:which_key_nmap.v.x = "eval current line/sel as EX"
" let g:which_key_vmap.v.x = g:which_key_nmap.v.x
vmap <leader>ve <Plug>(my-EvalAndReplaceVimExpr-visual)
" let g:which_key_vmap.v.e = "eval sel as vim expression"

" -- Code
let g:which_key_map.c = {"name": "+code"}

" code comment
let g:which_key_map.c.c = {"name": "+comment"}
nmap <Leader>cc<space> <plug>NERDCommenterToggle
vmap <Leader>cc<space> <plug>NERDCommenterToggle
nmap <Leader>ccc       <plug>NERDCommenterComment
vmap <Leader>ccc       <plug>NERDCommenterComment
nmap <Leader>ccu       <plug>NERDCommenterUncomment
vmap <Leader>ccu       <plug>NERDCommenterUncomment
nmap <Leader>cci       <plug>NERDCommenterInvert
vmap <Leader>cci       <plug>NERDCommenterInvert
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

" TODO: Setup virtual keys for language tools/actions (with default msg),
"   and enable for python (jedi) and when the language client is active

" -- Edit
let g:which_key_map.e = {"name": "+edit"}
" Use this to make a few nice mappings
" Taken from: http://vimcasts.org/episodes/the-edit-command/
nmap <silent> <leader>ee  :e %%
nmap <silent> <leader>es  :spl %%
nmap <silent> <leader>ev  :vsp %%
nmap <silent> <leader>et  :tabe %%
let g:which_key_map.e.e = "relative here"
let g:which_key_map.e.s = "relative in split"
let g:which_key_map.e.v = "relative in vertical split"
let g:which_key_map.e.t = "relative in tab"

" -- Git
" FIXME (not just here): Why not use nnoremap for these? Oo
nmap <leader>hp <Plug>(GitGutterPreviewHunk)
nmap <leader>hu <Plug>(GitGutterUndoHunk)
nmap <leader>hf <cmd>GitGutterFold<cr>
nmap <leader>hn <cmd>GitGutterNextHunk<cr>
nmap <leader>hN <cmd>GitGutterPrevHunk<cr>
nmap <leader>hb <Plug>(git-messenger)
let g:which_key_map.h = {"name": "+git-hunks"}
let g:which_key_map.h.p = "preview"
let g:which_key_map.h.u = "undo"
let g:which_key_map.h.f = "fold non-hunk"
let g:which_key_map.h.n = "next hunk"
let g:which_key_map.h.N = "prev hunk"
let g:which_key_map.h.b = "blame"
