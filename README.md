# annotations.nvim

Annotate visually selected text in Neovim. Annotations persist across sessions via JSON and restore highlights automatically on open.

## features

- [x] persist annotations to `stdpath("data")/annotations.json` with text, position, and file path.
- [x] auto-restore highlights when opening a file (verifies text+position match, prunes stale annotations).
- [x] toggle exact-match annotation off by re-selecting the same text.
- [x] remove an existing annotation by selecting text wholly contained within it.
- [x] merge overlapping annotations into one when they intersect.
- [x] send all annotations for the current file to the quickfix list (`AnnotationsQuickfix`).
- [x] sidebar listing all annotations for the current buffer (`AnnotationsSidebar`), multi-line support with thin separator, `<CR>` jumps to source.
- [x] toggle highlight visibility without altering stored annotations (`AnnotationsToggle`).
- [x] clear all annotations for the current file (`AnnotationsClear`).
- [ ] `nvim-mini/mini.ai` integration, "annotation" text object.

## references

- [pocco81/high-str.nvim](https://github.com/pocco81/high-str.nvim), essentially copied the highlight implementation from there.
- [stevearc/aerial.nvim](https://github.com/stevearc/aerial.nvim), based the sidebar.
