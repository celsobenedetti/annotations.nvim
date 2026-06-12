# annotations.nvim

Annotate (highlight) visually selected text in Neovim.

## features

- Annotate visually selected text
  - if current selection overlaps one or more existing annotations, merge them into one.
  - if current selection is wholy contained within an existing annotation, remove it instead.
- Persist annotations to `stdpath("data")/annotations.json` with text, position, and file path.
- Auto-restore highlights when opening a file 
    - verifies text+position match, prunes stale annotations.
- Sidebar listing all annotations for the current buffer (`AnnotationsSidebar`), multi-line support with thin separator, `<CR>` jumps to source.
- Send all annotations for the current file to the quickfix list (`AnnotationsQuickfix`).
- Toggle highlight visibility without altering stored annotations (`AnnotationsToggle`).
- Clear all annotations for the current file (`AnnotationsClear`).
- [ ] `nvim-mini/mini.ai` integration, "annotation" text object.

## setup

```lua

{
    'celsobenedetti/annotations.nvim',
    config = function()
    require('annotations').setup({
        -- defaults
        storage_path = vim.fn.stdpath('data') .. '/annotations.json',
        sidebar_position = 'left',
        highlight_colors = { -- colors from goated default neovim colorscheme
        notify_level = vim.log.levels.INFO,
        color_0 = { '#f4d88c', 'smart' }, -- "smart" for auto bg/fg contrast calculation
        -- ...
        },
    })
    end,
    keys = {
    { '<leader>h', ':<c-u>AnnotationsAdd<CR>', mode = 'x' },
    },
}
```

## usage

- `AnnotationsAdd` to add an annotation to the current buffer.
- `AnnotationsToggle` to toggle the visibility of annotations.
- `AnnotationsClear` to clear all annotations for the current buffer.
- `AnnotationsQuickfix` to send all annotations for the current buffer to the quickfix list.
- `AnnotationsSidebar` to open a sidebar listing all annotations for the current buffer.

## references

- [pocco81/high-str.nvim](https://github.com/pocco81/high-str.nvim), essentially copied the highlight implementation from there.
- [stevearc/aerial.nvim](https://github.com/stevearc/aerial.nvim), reference for the sidebar implementation.
