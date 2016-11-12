"=============================================================================
" FILE: autoload/operator/gtrans.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:SelectedText = vital#gtrans#import('Vim.SelectedText')

let s:INT = { 'MAX': 2147483647 }

" operator#gtrans#buffer() translates text and outputs translated text
" to buffer.
"
" @param {'char'|'line'|'block'} wise
function! operator#gtrans#buffer(wise) abort
  call gtrans#buffer(s:text(a:wise), '', '')
endfunction

" operator#gtrans#echom() translates text and echom translated text.
"
" @param {'char'|'line'|'block'} wise
function! operator#gtrans#echom(wise) abort
  call gtrans#echo(s:text(a:wise), '', 'echom')
endfunction

function! s:text(wise) abort
  let [begin, end] = [getpos("'["), getpos("']")]
  if a:wise ==# 'block'
    normal! gv
    let curswant = winsaveview().curswant
    if curswant ==# s:INT.MAX
      if begin[2] > end[2]
        let begin[2] = s:INT.MAX
      else
        let end[2] = s:INT.MAX
      endif
    endif
    execute 'normal!' "\<Esc>"
  endif
  return s:SelectedText.text(a:wise, begin, end)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
