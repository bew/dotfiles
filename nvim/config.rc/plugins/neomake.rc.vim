let g:neomake_cpp_enabled_makers=['clang']
let g:neomake_cpp_clang_args = ["-std=c++11"]


" From :help neomake-automake
"function! MyOnBattery()
"    return readfile('/sys/class/power_supply/AC/online') == ['0']
"endfunction

" Run makers on file open/read & write
call neomake#configure#automake('rw')
