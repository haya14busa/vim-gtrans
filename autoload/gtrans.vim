"=============================================================================
" FILE: autoload/gtrans.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:Process = vital#gtrans#import('System.Process')
let s:String = vital#gtrans#import('Data.String')

let g:gtrans#buffer_height = get(g:, 'gtrans#buffer_height', &previewheight)

function! gtrans#cmd(target_lang) abort
  let cmd = ['gtrans']
  if a:target_lang !=# ''
    let cmd += ['-to', a:target_lang]
  endif
  return cmd
endfunction

" gtrans#translate() translates text to target lang and returns translated
" text. It's synchronous API.
" target_lang can be empty string and if it's empty, gtrans automatically
" detects it.
function! gtrans#translate(text, target_lang) abort
  if s:check()
    return
  endif
  let result = s:Process.execute(gtrans#cmd(a:target_lang), {'input': a:text})
  return s:String.chomp(result.output)
endfunction

function! gtrans#echo(text, target_lang, echocmd) abort
  if s:check()
    return
  endif
  let echocmd = a:echocmd ==# '' ? 'echo' : a:echocmd
  let job = job_start(gtrans#cmd(a:target_lang), {
  \   'callback': s:genechocb(echocmd),
  \ })
  call ch_sendraw(job, a:text)
  call ch_close_in(job)
endfunction

function! gtrans#buffer(text, target_lang, id) abort
  if s:check()
    return
  endif
  let id = a:id ==# '' ? '0' : a:id
  let bufname = printf('gtrans://result/%s/', id)

  if bufexists(bufname)
    let currentbuf = bufnr('%')
    execute printf(':%d bufdo 1,$delete', bufnr(bufname))
    execute printf(':%d buffer', currentbuf)
  endif

  let job = job_start(gtrans#cmd(a:target_lang), {
  \   'out_io': 'buffer',
  \   'out_name': bufname,
  \   'out_msg': 0,
  \ })

  let bufnr = ch_getbufnr(job, 'out')

  if bufnr !=# -1
    let buftext = join([
    \   a:text,
    \   '---',
    \ ], "\n")
    let currentbuf = bufnr('%')
    execute printf(':%d bufdo put! =buftext | $delete', bufnr(bufname))
    execute printf(':%d buffer', currentbuf)
  endif

  call ch_sendraw(job, a:text)
  call ch_close_in(job)

  if bufwinnr(bufnr) ==# -1
    execute printf(':%dsplit %s', g:gtrans#buffer_height, bufname)
    wincmd p
  endif
endfunction

" gtrans://i/source/$id
" gtrans://i/target/$id
function! gtrans#interactive(text, target_lang, id) abort
  if s:check()
    return
  endif
  let id = a:id ==# '' ? '0' : a:id
  let sbuf = printf('gtrans://i/source/%s', id)
  let tbuf = printf('gtrans://i/target/%s', id)
  execute 'topleft' 'split' tbuf
  execute 'vsplit' sbuf
  let s:interactive.target_lang[id] = a:target_lang
  put! =a:text
  call s:interactive._translate(sbuf, a:target_lang)
endfunction

let s:interactive = { 'target_lang': {} }

function! s:interactive.amatch() abort
  return expand('<amatch>')
endfunction

function! s:interactive.to_tbuf(sbuf) abort
  return substitute(a:sbuf, 'source', 'target', '')
endfunction

function! s:interactive.to_sbuf(sbuf) abort
  return substitute(a:sbuf, 'target', 'source', '')
endfunction

function! s:interactive.id() abort
  return self.amatch()[len('gtrans://i/source/'):]
endfunction

function! s:interactive.unload_target() abort
  call remove(self.target_lang, self.id())
  let tbuf = self.amatch()
  let sbuf = self.to_sbuf(tbuf)
  if bufexists(sbuf)
    execute ':bdelete' sbuf
  endif
  setlocal bufhidden=delete
endfunction

function! s:interactive.init() abort
  setlocal buftype=nowrite
  setlocal bufhidden=hide
endfunction

function! s:interactive.get_target_lang() abort
  return self.target_lang[self.id()]
endfunction

function! s:interactive.translate() abort
  return self._translate(self.amatch(), self.get_target_lang())
endfunction

function! s:interactive._translate(sbuf, target_lang) abort
  let tbuf = self.to_tbuf(a:sbuf)
  call self.resetbuf(tbuf)
  let job = job_start(gtrans#cmd(a:target_lang), {
  \   'out_io': 'buffer',
  \   'out_name': tbuf,
  \   'out_msg': 0,
  \ })
  call ch_sendraw(job, join(getbufline(a:sbuf, 1, '$'), "\n"))
  call ch_close_in(job)
endfunction

function! s:interactive.resetbuf(bufname) abort
  if bufexists(a:bufname)
    let currentbuf = bufname('%')
    let pos = getcurpos()
    execute printf(':%d bufdo 1,$delete', bufnr(a:bufname))
    execute printf(':buffer %s', currentbuf)
    call setpos('.', pos)
  endif
endfunction

augroup gtrans-interactive
  autocmd!
  autocmd BufEnter gtrans://i/* call s:interactive.init()
  autocmd BufHidden gtrans://i/target/* call s:interactive.unload_target()
  autocmd TextChanged gtrans://i/source/* call s:interactive.translate()
  autocmd InsertLeave gtrans://i/source/* call s:interactive.translate()
augroup END

function! s:genechocb(cmd) abort
  let f = {}
  function! f.cb(ch, msg) abort closure
    execute a:cmd string(a:msg)
  endfunction
  return f.cb
endfunction

function! s:check() abort
  if executable('gtrans') !=# 1
    echom 'gtrans not found in PATH'
    return 1
  endif
  return 0
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
