" Open the current entry and expand all folds (actually show the diffs)
nmap <buffer> <M-o> o<C-w><C-w>zR<C-w><C-w>

nmap <buffer> <M-j> j<M-o>
nmap <buffer> <M-k> k<M-o>

let b:bew_statusline_comment = "M-o: preview | M-j/k: n/p preview"
