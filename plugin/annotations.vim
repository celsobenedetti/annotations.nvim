if exists('g:loaded_annotations') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

function! annotations#get_first_arg(...)
  return get(a:, 1, '0')
endfunction

function! annotations#get_toggle_arg(...)
  return get(a:, 1, '')
endfunction

function! s:complete_annotations_add(arg, line, pos) abort
  return "0\n1\n2\n3\n4\n5\n6\n7\n8\n9"
endfunction

function! s:complete_annotations_toggle(arg, line, pos) abort
  return "left\nright"
endfunction

command! -nargs=? -complete=custom,s:complete_annotations_add AnnotationsAdd call v:lua.require("annotations.main").add(annotations#get_first_arg(<f-args>))
command! -nargs=0 AnnotationsQuickfix call v:lua.require("annotations.main").quickfix()
command! -nargs=0 AnnotationsClear call v:lua.require("annotations.main").clear()
command! -nargs=? -complete=custom,s:complete_annotations_toggle AnnotationsToggle call v:lua.require("annotations.main").toggle(annotations#get_toggle_arg(<f-args>))

let &cpo = s:save_cpo
unlet s:save_cpo
let g:loaded_annotations = 1
