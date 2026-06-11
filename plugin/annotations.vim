if exists('g:loaded_annotations') | finish | endif

let s:save_cpo = &cpo
set cpo&vim

function! annotations#get_first_arg(...)
  return get(a:, 1, '0')
endfunction

function! s:complete_annotations_add(arg, line, pos) abort
  return "0\n1\n2\n3\n4\n5\n6\n7\n8\n9"
endfunction

command! -nargs=? -complete=custom,s:complete_annotations_add AnnotationsAdd call v:lua.require("annotations.main").add(annotations#get_first_arg(<f-args>))
command! -nargs=0 AnnotationsShow call v:lua.require("annotations.main").show()
command! -nargs=0 AnnotationsClear call v:lua.require("annotations.main").clear()

let &cpo = s:save_cpo
unlet s:save_cpo
let g:loaded_annotations = 1
