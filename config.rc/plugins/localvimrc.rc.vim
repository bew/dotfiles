" Disable .lvimrc loading on startup, to load use :LocalVimRCEnable
let g:localvimrc_enable = 0

" Make the decisions given when asked before sourcing local vimrc files
" persistent over multiple vim runs and instances. The decisions are written to
" the file defined by and |g:localvimrc_persistence_file|.
"
" - Value '0': Don't store and restore any decisions.
" - Value '1': Store and restore decisions only if the answer was given in
"   upper case (Y/N/A).
" - Value '2': Store and restore all decisions.
let g:localvimrc_persistent = 1

" Disable auto-lvimrc load on autocmds
let g:localvimrc_event = []
