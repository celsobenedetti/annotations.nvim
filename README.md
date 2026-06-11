# annotations.nvim

This plugin does two things:

1. allows you to highlight (annotations) visually selected text in neovim.
    - we store the text, filename and the position in a json file.
    - when we open a file that has annotations, we verify whether the text and position match. If they do, we highlight the text. otherwise, we remove the annotation.
2. allows us to show all annotations for the given file in quickfix list

