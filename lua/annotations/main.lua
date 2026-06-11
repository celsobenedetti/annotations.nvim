local M = {}
local storage = require("annotations.storage")
local highlight = require("annotations.highlight")

function M.add(hi_index)
  hi_index = tonumber(hi_index) or 0

  local _, beg_line, beg_col, _ = unpack(vim.fn.getpos("'<"))
  if beg_line == 0 then
    vim.notify("Annotations: no visual selection", vim.log.levels.WARN)
    return
  end

  local _, end_line, end_col, _ = unpack(vim.fn.getpos("'>"))

  local filepath = vim.fn.expand("%:p")
  local annotations = storage.get_annotations_for_file(filepath)

  for _, ann in ipairs(annotations) do
    if ann.beg_line == beg_line and ann.beg_col == beg_col
       and ann.end_line == end_line and ann.end_col == end_col then
      storage.remove_annotation_by_position(filepath, beg_line, beg_col, end_line, end_col)
      vim.api.nvim_buf_clear_namespace(0, 0, 0, -1)
      for _, remaining in ipairs(storage.get_annotations_for_file(filepath)) do
        highlight.apply_highlight(0, remaining.hi_index, remaining.beg_line, remaining.beg_col, remaining.end_line, remaining.end_col)
      end
      vim.notify("Annotations: removed annotation")
      return
    end
  end

  highlight.setup_highlight_groups()
  highlight.highlight_visual_selection(hi_index)
end

function M.show()
  local filepath = vim.fn.expand("%:p")
  local annotations = storage.get_annotations_for_file(filepath)
  local qf_list = {}

  for _, ann in ipairs(annotations) do
    table.insert(qf_list, {
      filename = filepath,
      lnum = ann.beg_line,
      col = ann.beg_col,
      text = ann.text,
    })
  end

  vim.fn.setqflist(qf_list)
  vim.cmd("copen")
end

function M.clear()
  local filepath = vim.fn.expand("%:p")

  vim.api.nvim_buf_clear_namespace(0, 0, 0, -1)
  storage.clear_annotations_for_file(filepath)
  vim.notify("Annotations: cleared for " .. filepath)
end

function M.restore()
  local filepath = vim.fn.expand("%:p")
  if filepath == "" then return end

  local annotations = storage.get_annotations_for_file(filepath)
  if #annotations == 0 then return end

  local bufnr = vim.api.nvim_get_current_buf()
  local valid = {}
  local removed = 0

  for _, ann in ipairs(annotations) do
    local current_text = highlight.get_text(bufnr, ann.beg_line, ann.beg_col, ann.end_line, ann.end_col)

    if current_text and current_text == ann.text then
      highlight.apply_highlight(bufnr, ann.hi_index, ann.beg_line, ann.beg_col, ann.end_line, ann.end_col)
      table.insert(valid, ann)
    else
      removed = removed + 1
    end
  end

  if removed > 0 then
    storage.save_annotations_for_file(filepath, valid)
    vim.notify(string.format("Annotations: removed %d stale annotation(s)", removed))
  end
end

return M
