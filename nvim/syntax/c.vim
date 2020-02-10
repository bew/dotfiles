
" match 't_new_type' and 's_new_type'
sy match cType /\<\(t_\|s_\)\w\+\>/

" match 'myvar.' and 'myvar->' (without . & ->)
sy match cStructInstance /\<\h\w\+\>\ze\(->\|\.\)/

" match the arithmetic operators
sy match cArithmOp /\s\zs+\ze\s/
sy match cArithmOp /\s\zs-\ze\s/
sy match cArithmOp /\s\zs\*\ze\s/
sy match cArithmOp "\s\zs/\ze\s"
sy match cArithmOp /\s\zs%\ze\s/

" match the operators we can find in a conditional block
sy match cBoolComparator / == /
sy match cBoolComparator / != /
sy match cBoolComparator / < /
sy match cBoolComparator / <= /
sy match cBoolComparator / > /
sy match cBoolComparator / >= /

sy match cBoolComparator / && /
sy match cBoolComparator / || /

