inoremap <buffer> <Tab> <Esc>
nnoremap <buffer> <Tab> <nop>


" Without count, move in displayed lines, with count move in real line
nnoremap <buffer> <expr> j (v:count == 0) ? 'gj' : 'j'
nnoremap <buffer> <expr> k (v:count == 0) ? 'gk' : 'k'
