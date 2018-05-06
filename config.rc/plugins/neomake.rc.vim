autocmd! BufWritePost,BufEnter * Neomake

let g:neomake_cpp_enabled_makers=['clang']
let g:neomake_cpp_clang_args = ["-std=c++11"]
