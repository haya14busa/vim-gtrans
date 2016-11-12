"=============================================================================
" FILE: plugin/operator/gtrans.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_operator_gtrans
endif
if exists('g:loaded_operator_gtrans')
  finish
endif
let g:loaded_operator_gtrans = 1
let s:save_cpo = &cpo
set cpo&vim

try
  call operator#user#define('gtrans-buffer', 'operator#gtrans#buffer')
  call operator#user#define('gtrans-echom', 'operator#gtrans#echom')
catch /^Vim\%((\a\+)\)\=:E117/
  " vim-operator-user not found.
endtry


let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
