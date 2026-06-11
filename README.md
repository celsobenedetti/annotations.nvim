# annotations.nvim

This plugin does two things:

1. allows you to highlight (annotations) visually selected text in neovim.
    - we store the text, filename and the position in a json file.
    - when we open a file that has annotations, we verify whether the text and position match. If they do, we highlight the text. otherwise, we remove the annotation.
2. allows us to show all annotations for the given file in quickfix list

## features

- [x] add annotations by visually selecting text.
- [x] merge one or more annotations into one if they overlap.
- [x] remove existing annotations if visual is wholy contained within it.
- [x] send annotations to quickfix list.
- [ ] restore existing highlights when opening a file.
- [x] show annotations in sidebar
- [ ] `nvim-mini/mini.ai` integration, "annotation" text object.

## references

- [pocco81/high-str.nvim](https://github.com/pocco81/high-str.nvim), essentially copied the highlight implementation from there.
- [stevearc/aerial.nvim](https://github.com/stevearc/aerial.nvim), based the sidebar.
