" VIM - mappings
"
" "I speek vim" - bew, 2021

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
nnoremap <M-R>  <cmd>call ToggleSignsAndLineNumbers()<cr>

" Start interactive EasyAlign in visual mode (e.g. vipgea)
xmap gea <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. geaip)
nmap gea <Plug>(EasyAlign)

" Discard last search highlight
nnoremap <silent> § :noh \| echo "Search cleared"<cr>

nnoremap <silent> <C-Space> :CtrlSpace<cr>

nnoremap <silent> <M-f> :FuzzyFilesSmart<cr>
nnoremap <silent> <M-F> :FuzzyFiles<cr>

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

" I: Short navigation on the line in insert mode
"
" This makes it possible to use the cursor keys in Insert mode, without breaking
" the undo sequence, therefore using `.` (redo) will work as expected.
inoremap <Left>  <C-g>U<Left>
inoremap <Right> <C-g>U<Right>
" We use imap to use the above left/right mapping
imap <M-h> <Left>
imap <M-l> <Right>
" Move back/forward by word, I'm too used to it in the shell and nvim's
" cmdline!
inoremap <M-b> <C-g>U<S-Left>
inoremap <M-w> <C-g>U<S-Right>

" I: Disable up/down
"
" This is required when running under tmux with scrolling emulation mouse bindings
" for the alternate screen, because it would move Up/Down N times based on the
" scrolling emulation config.
inoremap <Up> <nop>
inoremap <Down> <nop>

" Windows navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Window splits
" FIXME: now I need repeat mode supports, like in tmux!!
"        similar to Hydra plugin in emacs: https://github.com/abo-abo/hydra
nnoremap <C-w><C-h>   <cmd>set nosplitright <bar> vsplit                       <cr>
nnoremap <C-w><C-j>   <cmd>set   splitbelow <bar>  split <bar> set nosplitbelow<cr>
nnoremap <C-w><C-k>   <cmd>set nosplitbelow <bar>  split                       <cr>
nnoremap <C-w><C-l>   <cmd>set   splitright <bar> vsplit <bar> set nosplitright<cr>
" Full-width/height window splits
" FIXME: Do I need this? Would I use this?
" FIXME: Since I use noequalalways, the created splits takes way too much space...
"   => Maybe get current screen size and make the new one third of that?
nnoremap <C-M-w><C-M-h>   <cmd> split<cr><C-w>H
nnoremap <C-M-w><C-M-j>   <cmd>vsplit<cr><C-w>J
nnoremap <C-M-w><C-M-k>   <cmd>vsplit<cr><C-w>K
nnoremap <C-M-w><C-M-l>   <cmd> split<cr><C-w>L
" Keep a mapping for original <C-w> behavior
nnoremap <C-w><C-w>  <cmd>echo "Original ^W behavior..."<cr><C-w>

" NOTE: Keys still available (not used often / ever)
" * <C-M-hjkl>
" * <C-w><C-HJKL>
" * <C-w><C-M-hjkl>
"
" TODO: window actions ideas:
" -> Keys to move current buffer around in the visible (non-float, non-special) windows
" -> (??) Keys to create a full-width/height BUT do not switch to it

" When mapping <C-j> has no effect
" nmap <cr> <C-j>

" When mapping <C-h> has no effect
" nmap <BS> <C-h>


" CrazyIDEA: Map Alt-MouseClick to resize a window by finding nearest edge??

" Goto tabs Alt-a/z
nnoremap <M-a> gT
nnoremap <M-z> gt
inoremap <M-a> <esc>gT
inoremap <M-z> <esc>gt

" Move tabs (with Shift + goto keys)
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

" Navigate arglist
nnoremap <silent> <M-n> :next<cr>
nnoremap <silent> <M-N> :previous<cr>

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

" I: Alt-Backspace to delete last word (like in most other programs)
inoremap <M-BS> <C-w>
cnoremap <M-BS> <C-w>

" N: Move cursor to begin/end of displayed line (useful when text wraps)
nnoremap <M-$> g$
nnoremap <M-^> g^
" I: Move cursor to begin/end of line
inoremap <M-$> <C-g>U<End>
" FIXME: <M-^> is waiting on https://github.com/wez/wezterm/issues/877 to work instantly...
" FIXME: <Home> moves like 0 not like ^
inoremap <M-^> <C-g>U<Home>
" TODO: for <M-^> mappings, support both ^ (first) & 0 (second) (like vscode)
" TODO: Add <M-b> & <M-w> BUT the movement should stay on the same line!

" Insert a new line below using <cr>, useful in comments when `formatoptions`
" has `r` (to auto-add comment start char on <cr> but not o/O) and the cursor
" is not at eol.
inoremap <M-cr> <C-o>A<cr>
" Also works in normal mode, goes in insert mode with a leading comment.
nnoremap <M-cr> A<cr>

" Trigger completion manually
inoremap <silent><expr> <C-b>  (pumvisible() ?
    \ deoplete#complete_common_string() :
    \ deoplete#manual_complete())


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

" V: a count then J on a single visual line does not make sense and is a probably a mistake
" (like when I 'V4j' but fail to release Shift rapidly enough after typing 4 (on azerty layout)),
" sends j instead.
vnoremap <expr> J  (v:count && line(".") == line("v")) ? "j" : "J"

" N: un-join (split) the current line at the cursor position
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

" I: Select last inserted region
nnoremap gV `[v`]
" O: Operate on last inserted region
onoremap gV <cmd>normal! `[v`]<cr>

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
function! ExecuteAsExFromUnnamed(what)
  let l:splitted_reg = split(@", "\n")
  execute @"
  let num_lines = len(l:splitted_reg)
  if num_lines <= 1
    let lines_text = num_lines . " line"
  else
    let lines_text = num_lines . " lines"
  endif
  echom "Sourced " . a:what . "! (" . lines_text . ")"
endf
nnoremap <Plug>(my-ExecuteAsVimEx-normal) yy:call ExecuteAsExFromUnnamed("current line")<cr>
vnoremap <Plug>(my-ExecuteAsVimEx-visual) y:call ExecuteAsExFromUnnamed("visual selection")<cr>gv
nnoremap <Plug>(my-ExecuteAsVimEx-full-file) <cmd>source % <bar> echo "Sourced current file! (" . line("$") . " lines)"<cr>

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


" Inspired from visual-at.vim from Practical Vim 2nd Edition
vnoremap <silent> @ :<C-u>call ExecuteMacroOverVisualRange()<cr>
function! ExecuteMacroOverVisualRange()
  let register = nr2char(getchar())
  if register == "" " this is the ^[ (esc) char
    return
  endif
  if visualmode() == ""  " this is the ^V char
    let column_code = getpos("'<")[2] . "|"
  else
    let column_code = ""
  endif
  execute ":'<,'>normal! " . column_code . "@" . register
endfunction

" V: Record a macro on first line, and repeat it on all other selected lines
" This is the poor-man multiselection... (not even interactive)
" NOTE: Maybe I'll never use it as I can also record macro then apply with @reg..
"       I don't know, but it was interesting to do!
vnoremap qq :<C-u>call <SID>StartRecordMacroForVisualRange()<cr>
function! <SID>StartRecordMacroForVisualRange()
  " Save visual selection, in case the macro makes use of visual selection
  " return format is [_bufnum, lnum, col, _off]
  let b:macro_visual_start = getpos("'<")
  let b:macro_visual_end = getpos("'>")
  let b:macro_visual_is_vblock = visualmode() == ""  " this is the ^V char
  call setpos(".", b:macro_visual_start)
  " TODO: Highlight saved visual selection (in IncSearch hi for example?)
  "       while recording the macro.
  nnoremap <buffer> q  <cmd>call <SID>ExecutePendingMacroOverSavedVisualRange()<cr>
  " Start recording...
  normal! qq
endf
function! <SID>ExecutePendingMacroOverSavedVisualRange()
  " Unmap q, was <buffer> mapped in StartRecordMacroForVisualRange
  nunmap <buffer> q
  " End recording, started in StartRecordMacroForVisualRange
  normal! q

  if getreg("q") == ""
    return
  endif

  let start_next_line = b:macro_visual_start[1] + 1
  let end_line = b:macro_visual_end[1]
  if b:macro_visual_is_vblock
    let column_code = b:macro_visual_start[2] . "|"
  else
    let column_code = ""
  endif

  " Format as `:START,END normal! COL|@q`
  let cmd = ":" . start_next_line . "," . end_line . "normal! " . column_code . "@q"
  " echom cmd
  execute cmd

  let save_final_pos = getpos(".")

  " Restore visual selection to be same as before batch action (including vblock)
  call setpos("'<", b:macro_visual_start)
  call setpos("'>", b:macro_visual_end)
  if b:macro_visual_is_vblock
    " Re-enter visual block temporarily to mark this visual selection as block..
    " FIXME: is there a better way?
    execute "normal! gv"
  endif
  call setpos(".", save_final_pos)

  unlet b:macro_visual_start
  unlet b:macro_visual_end
  unlet b:macro_visual_is_vblock
endf

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
cnoremap <M-$> <End>
cnoremap <M-^> <Home>

" Command history by prefix
cnoremap <M-k> <Up>
cnoremap <M-j> <Down>
" Command history
cnoremap <M-K> <S-Up>
cnoremap <M-J> <S-Down>

" Expand %% to dir of current file
cnoremap <expr> %%  expand("%:h") . "/"


" ---- Various Leader key mappings ----
" (NOTE: some mappings are in init.vim)
"
" Nice example of mappings! (https://github.com/phaazon/config/blob/ea8378065/nvim/key_bindings.vim)

" Helper guide on <Leader>
nnoremap <silent> <leader> <cmd>WhichKey '<Space>'<cr>
vnoremap <silent> <leader> <cmd>WhichKeyVisual '<VisualBindings>'<cr>
" NOTE: I'm trying to understand how to tell WhichKey to use '<Space>' as
" leader indicator, AND use the g:which_key_vmap to search for descriptions

" -- Vim
nmap <leader>vs <Plug>(my-ExecuteAsVimEx-full-file)
nmap <leader>vx <Plug>(my-ExecuteAsVimEx-normal)
vmap <leader>vx <Plug>(my-ExecuteAsVimEx-visual)
let g:which_key_map.v = {"name": "+vim"}
let g:which_key_map.v.s = "source current file"
let g:which_key_map.v.x = "exec current line/selection as VimEx"
" let g:which_key_nmap.v = {"name": "+vim"}
" let g:which_key_nmap.v.x = "eval current line/sel as EX"
" let g:which_key_vmap.v = deepcopy(g:which_key_nmap.v)
" let g:which_key_vmap.v.x = g:which_key_nmap.v.x
nmap <leader>ve gv<Plug>(my-EvalAndReplaceVimExpr-visual)
vmap <leader>ve   <Plug>(my-EvalAndReplaceVimExpr-visual)
let g:which_key_map.v.e = "substitute/eval sel as vim expr"

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
" ca   code actions (from LSP + custom?)
"
" Currently my main usage is with jedi-vim, which I configure manually
" when a python buffer opens.
" NOTE: I don't know how to set a which_key_map for a single buffer
nmap <leader>c²   <Plug>(lcn-menu)
nmap <leader>cd   <Plug>(lcn-definition)
nmap <leader>ct   <Plug>(lcn-type-definition)
nmap <leader>cu   <Plug>(lcn-references)
nmap <leader>cr   <Plug>(lcn-rename)
nmap <leader>ca   <Plug>(lcn-code-action)
nmap <leader>ci   <Plug>(lcn-implementation)
nmap <leader>ch   <Plug>(lcn-hover)
let g:which_key_map.c["²"] = "lang menu"
let g:which_key_map.c.d = "lang goto def"
let g:which_key_map.c.t = "lang goto type"
let g:which_key_map.c.u = "lang references"
let g:which_key_map.c.r = "lang rename"
let g:which_key_map.c.a = "lang code actions"
let g:which_key_map.c.i = "lang implementation"
let g:which_key_map.c.h = "lang hover info"

" TODO: Setup virtual keys for language tools/actions (with default msg),
"   and enable for python (jedi) and when the language client is active

" code/content context (using context.vim plugin)
nmap <Leader>cx   <cmd>ContextPeek<cr>
let g:which_key_map.c.x = "context peek (until move)"

" -- Quickfix / Location lists
let g:which_key_map["!"] = {"name": "+qf-loc-list"}
nmap <leader>!c   <cmd>lclose \| copen<cr>
nmap <leader>!l   <cmd>cclose \| lopen<cr>
let g:which_key_map["!"].c = "open qf list (global)"
let g:which_key_map["!"].l = "open loc list (local)"

" Try to detect the qf or loc list, and save which one is the last one
function! s:TryRegisterLastUsedQfOrLocList()
  let wininfo = getwininfo(win_getid())[0]
  " let r = getwininfo(win_getid())[0] | echo "qf: " . r.quickfix . " loc: " . r.loclist
  let is_qf_list = (wininfo.quickfix && !wininfo.loclist)  " qf: 1 && loc: 0
  let is_loc_list = (wininfo.quickfix && wininfo.loclist)  " qf: 1 && loc: 1
  if is_qf_list
    let w:last_used_qf_or_loc_list = "qf"
  elseif is_loc_list
    let w:last_used_qf_or_loc_list = "loc"
  else
    " Do nothing, leave the current value as is.
  endif
endf
augroup my_detect_last_used_qf_loc_list
  au!
  " Init the win variable on each new win
  autocmd VimEnter,WinNew * let w:last_used_qf_or_loc_list = get(w:, "last_used_qf_or_loc_list", "none")
  " Try to detect the qf or loc list, and save which one is the last one
  autocmd BufWinEnter * call <SID>TryRegisterLastUsedQfOrLocList()
augroup END
function! s:OnLastQfLocListDoTryNextOrFirst()
  let qf_cmds = {"name": "qf", "action_next": "cnext", "action_first": "cfirst"}
  let loc_cmds = {"name": "loc", "action_next": "lnext", "action_first": "lfirst"}
  if w:last_used_qf_or_loc_list == "qf"
    let cmds = qf_cmds
  elseif w:last_used_qf_or_loc_list == "loc"
    let cmds = loc_cmds
  else
    " Default to the location list
    let cmds = loc_cmds
  endif

  try
    " echo "[". cmds.name ." list] trying next: ". cmds.action_next
    execute cmds.action_next
  catch
    try
      " echo "[". cmds.name ." list] nop.. trying first: ". cmds.action_first
      execute cmds.action_first
    catch
      echo "[". cmds.name ." list] nope, it's empty!"
    endtry
  endtry
endf
nmap <leader>!! <cmd>call <SID>OnLastQfLocListDoTryNextOrFirst()<cr>
let g:which_key_map["!"]["!"] = "jump to next/first in last list"

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



" -----------------
" IDEAS: (from vscode)
" M-Up/Down -> Move current line (or range) up/down, following indentations
" M-S-Up/Down -> Copy current line Up/Down
" M-S-Left/Right -> Shrink/Expand (char-)selection (can be simulated in vim?
"     even without proper language support/detection?)
