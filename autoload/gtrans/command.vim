"=============================================================================
" FILE: autoload/command/gtrans.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:ArgumentParser = vital#opengoogletranslate#import('ArgumentParser')

function! s:get_parser() abort
  let s:parser = s:ArgumentParser.new({
  \   'name': 'Gtrans',
  \   'description': 'Translate text using Google Translate',
  \ })
  call s:parser.add_argument(
  \   '--to', '-t', 'language translate to (e.g. en, ja, etc...)', {
  \     'type': s:ArgumentParser.types.value,
  \   }
  \ )
  call s:parser.add_argument(
  \   '--output', '-o', 'output destination', {
  \     'choices': ['buffer', 'echo', 'echom'],
  \   }
  \ )
  return s:parser
endfunction

function! s:parse(...) abort
  let parser = s:get_parser()
  return call(parser.parse, a:000, parser)
endfunction

function! gtrans#command#command(...) abort
  let options = call('s:parse', a:000)
  if empty(options)
    return
  endif
  let to = get(options, 'to', '')
  let output = get(options, 'output', '')
  let input = join(options.__unknown__, ' ')
  if input ==# ''
    let [start, end] = [options.__range__[0], options.__range__[1]]
    let input = join(getline(start, end), "\n")
    if output ==# ''
      let output = 'buffer'
    endif
  endif
  if output ==# 'buffer'
    call gtrans#buffer(input, to, '')
  else
    call gtrans#echo(input, to, output)
  endif
endfunction

function! gtrans#command#complete(...) abort
  let parser = s:get_parser()
  return call(parser.complete, a:000, parser)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
