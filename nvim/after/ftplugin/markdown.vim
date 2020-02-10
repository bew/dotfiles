inoremap <buffer> <Tab> <Esc>
nnoremap <buffer> <Tab> <nop>


"setlocal wrapmargin=4

" Without count, move in displayed lines, with count move in real line
nnoremap <expr> j (v:count == 0) ? 'gj' : 'j'
nnoremap <expr> k (v:count == 0) ? 'gk' : 'k'
