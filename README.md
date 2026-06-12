# annotations.nvim

Annotate (<mark>highlight</mark>) visually selected text in Neovim.

<details>
<summary>What are annotations?</summary>

Really, they are actually _"highlights"_, as in _<mark>"highlighted text"</mark>_.

I call them _"annotations"_ since _"highlights"_ mean something else in Neovim (`:h hi`).

</details>

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
- [nvim-mini/mini.ai](https://github.com/nvim-mini/mini.ai) integration: custom _annotations_ (`h`) textobject. Auto-detected if `mini.ai` is installed.

## setup

See [init.lua](https://github.com/celsobenedetti/annotations.nvim/blob/main/lua/annotations/init.lua) for configuration options.

```lua

{
    'celsobenedetti/annotations.nvim',
    config = function()
        require("annotations").setup() -- see options and defaults in init.lua
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
