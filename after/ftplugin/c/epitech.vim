"
" Plugin vim pour les headers Epitech | Nathan Appere
"    > Mise a jour de la 1ere ligne et de l'update a la sauvegarde
"    > HeaderF10 remet integralement a jour le header
"    > Genere les .h correspondants au .c

if exists("loaded_epitech")
  finish
else
  let loaded_epitech = 1
endif


" >> Suppression des espaces surnumeraires

function! RemoveST()
  let pos = line(".")
  let ext = expand("%:e")
  if (ext == "h" || ext == "c" || ext == "cpp" || ext == "hpp")
    execute "9,$s/[ \t]*$//"
  else
    execute "0,$s/[ \t]*$//"
  endif
  execute pos
endfunction

"autocmd BufWritePre * :call RemoveST()



"autocmd BufNewFile			*	call HeaderCreate(1)
autocmd BufWritePre,FileWritePre	*	call HeaderUpdate()

nnoremap <F9>	:call InsertPrototypes()<cr>
nnoremap <F10>	:call HeaderF10()<cr>

"
" Format a la norme de l'ecole (/usr/local/share/emacs/site-lisp/std_comment.el)

let s:login		= "lesell_b"
let s:name		= "Benoit LE SELLIER DE CHEZELLES" 
let s:txt_made_by	= "Made by "
let s:txt_login		= "Login   "
let s:txt_mail_s	= "<"
let s:txt_mail_e	= "@epitech.net>"
let s:txt_start		= "Started on  "
let s:txt_last		= "Last update "
let s:txt_for		= " for "
let s:txt_in		= " in "

let s:date_format	= "%a %b %d %H:%M:%S %Y"

function s:GetComStr()
  let hascom = 1
  if &ft == "c"  || &ft == "css" || expand("%:e") == "h"
    let s:cs = "/\*"
    let s:cc = "\*\* "
    let s:ce = "\*/"
  elseif &ft == "cpp" || &ft == "java" || &ft == "pov"
    let s:cs = "//"
    let s:cc = "// "
    let s:ce = "//"
  elseif &ft == "make" || &ft == "text"
    let s:cs = "##"
    let s:cc = "## "
    let s:ce = "##"
  elseif &ft == "php"
    let s:cs = "#!/usr/local/bin/php\n<?php\n/\*"
    let s:cc = "\*\* "
    let s:ce = "\*/"
  elseif &ft == "ruby"
    let s:cs = "#!/usr/local/bin/ruby"
    let s:cc = "## "
    let s:ce = "##"
  elseif &ft == "perl"
    let s:cs = "#!/usr/local/bin/perl -w"
    let s:cc = "## "
    let s:ce = "##"
  elseif &ft == "pascal"
    let s:cs = "{ "
    let s:cc = "   "
    let s:ce = "}"
  elseif &ft == "latex"
    let s:cs = "%%"
    let s:cc = "%% "
    let s:ce = "%%"
  elseif &ft == "lisp"
    let s:cs = ";;"
    let s:cc = ";; "
    let s:ce = ";;"
  elseif &ft == "xdefault"
    let s:cs = "!!"
    let s:cc = "!! "
    let s:ce = "!!"
  else
    let hascom = 0
  endif
  return hascom
endfunction



"
" Fonctions propres aux headers Epitech

function s:LineFind(pat)
  let i = 1
  let l = getline(i)
  while l !~ '^\s*$' && i < 10
    if match(l, a:pat) != -1
      return i
    endif
    let i = i + 1
    let l = getline(i)
  endwhile
  return 0
endfunction

function s:LineUpdate(lnum, newline)
  let oldline = getline(a:lnum)
  if oldline != a:newline
    call setline(a:lnum, a:newline)
  endif
endfunction

function HeaderUpdate()
  if s:GetComStr()
    let lnum = s:LineFind(s:cc . s:txt_last)
    if lnum
      let newline = s:cc . s:txt_last . strftime(s:date_format) .' '. s:name
      call s:LineUpdate(lnum, newline)
    endif
    let lnum = s:LineFind('^\('. s:cc .'\).*\('. s:txt_for. '\).*\('. s:txt_in .'\).*$')
    if lnum
      let newline = s:cc . expand("%:t") . s:txt_for . expand("%:p:h:t") . s:txt_in . expand("%:p:h")
      call s:LineUpdate(lnum, newline)
    endif
  endif
endfunction

function HeaderCreate(new)
  if s:GetComStr()
    setl fo-=o fo-=r fo-=a fo-=c
    setl noautoindent nosmartindent nocindent
    execute "normal! ggO" .
      \ s:cs . "\n".
      \ s:cc . expand("%:t") . s:txt_for . expand("%:p:h:t") . s:txt_in . expand("%:p:h") . "\n".
      \ s:cc . "\n".
      \ s:cc . s:txt_made_by . s:name . "\n".
      \ s:cc . s:txt_login . s:txt_mail_s . s:login . s:txt_mail_e . "\n".
      \ s:cc . "\n".
      \ s:cc . s:txt_start . strftime(s:date_format) .' '. s:name . "\n".
      \ s:cc . s:txt_last . strftime(s:date_format) .' '. s:name . "\n".
      \ s:ce
    if getline(10) !~ '^\s*$' "pb avec le shebang
      execute "normal! 10"
      execute "normal! o"
    endif
    setl fo+=o fo+=r fo+=a fo+=c
    setl autoindent smartindent cindent
    if expand("%:e") == "h" || expand("%:e") == "hpp"
      if a:new
	call s:ProtectHeaders()
	call InsertPrototypes()
      endif
    else
      execute "normal! G"
    endif
  endif
endfunction

function HeaderF10()
  if s:GetComStr()
    if getline(1) == s:cs && getline(9) == s:ce
      execute "normal! gg9dd"
    endif
    call HeaderCreate(0)
  endif
endfunction


"
" Fonctions de generations des .h

function s:ProtectHeaders()
  let filename = substitute(toupper(expand("%:t")), "\\.", "_", "g") . "_"
    execute "normal! Go" .
      \ '#ifndef '. filename . "\n".
      \ '#  define ' . filename . "\n".
      \ "\n\n\n".
      \ '#endif /* !' . filename . ' */'
  normal! kk
endfunction

" Un peu crade... mais au final v/s n'aident pas forcemment
function InsertPrototypes()
  if expand("%:e") != "h" && input("Ce fichier n'est pas un header C, inclure quand meme ? (y/n)", "") != "y"
    return
  endif
  let cfile = expand("%:p:r") . ".cpp"
  if !filereadable(cfile)
    let cfile = expand("%:p:h") . input("Saisir un fichier: ", ".cpp")
    if !filereadable(cfile)
      return
    endif
    return
  endif
  let l = line(".")
  execute 'normal! o<EOIF>'
  silent execute (l) ." read ". cfile
  let lastline = getline(l)
  while lastline != '<EOIF>'
    let newline = getline(l + 1)
    if newline !~ '^{$' || !match(lastline, '.*\<main\>.*') || !match(lastline, '.*\<static\>.*')
      execute l
      execute l . "d"
    else
      call setline(l, lastline . ';')
      let l = l + 1
    endif
    let lastline = newline
  endwhile
  execute "normal! dd"
  if getline(l) !~ '^\s*$'
    execute "normal! O"
  endif
endfunction
