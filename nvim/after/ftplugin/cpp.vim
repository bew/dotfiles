setlocal tabstop=4 shiftwidth=2 softtabstop=4 expandtab

setlocal cindent
setlocal cinkeys=0{,0},!^F,0=break,*;,0=if,0=return,o,O
setlocal cinoptions=Ls,l1,b1,t0,c0,C0,(0,us,U1,m1,J1

setlocal colorcolumn=85

" Ensure that o/O (in normal) does not auto insert comment line and enter (in insert) does.
setlocal formatoptions-=o formatoptions+=r
