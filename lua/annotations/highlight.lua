local M = {}

local function get_cols(num)
  return vim.api.nvim_eval("col([" .. num .. ", '$'])")
end

local function color_is_bright(r, g, b)
  local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
  return luminance > 0.5
end

function M.setup_highlight_groups()
  local colors = require("annotations").options.highlight_colors

  for opt, _ in pairs(colors) do
    local bg = colors[opt][1]
    local fg = colors[opt][2]
    local num = opt:gsub("color_", "")
    local name = "AnnotationGroup" .. num

    if fg == "smart" then
      local hex = bg:gsub("#", "")
      local r = tonumber("0x" .. hex:sub(1, 2))
      local g = tonumber("0x" .. hex:sub(3, 4))
      local b = tonumber("0x" .. hex:sub(5, 6))
      fg = color_is_bright(r, g, b) and "#000000" or "#ffffff"
    end

    vim.cmd("highlight " .. name .. " guifg=" .. fg .. " guibg=" .. bg)
  end
end

function M.apply_highlight(bufnr, hi_index, beg_line, beg_col, end_line, end_col)
  local hi_group = "AnnotationGroup" .. hi_index

  if beg_line == end_line then
    vim.api.nvim_buf_add_highlight(bufnr, 0, hi_group, beg_line - 1, beg_col - 1, end_col)
  else
    vim.api.nvim_buf_add_highlight(bufnr, 0, hi_group, beg_line - 1, beg_col - 1, get_cols(beg_line) - 1)

    for line = beg_line + 1, end_line - 1 do
      vim.api.nvim_buf_add_highlight(bufnr, 0, hi_group, line - 1, 0, get_cols(line) - 1)
    end

    vim.api.nvim_buf_add_highlight(bufnr, 0, hi_group, end_line - 1, 0, end_col)
  end
end

function M.get_text(bufnr, beg_line, beg_col, end_line, end_col)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if beg_line > line_count or end_line > line_count then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, beg_line - 1, end_line, false)
  if #lines == 0 then return nil end

  if beg_line == end_line then
    local line = lines[1]
    if beg_col > #line or end_col > #line then
      return nil
    end
    return line:sub(beg_col, end_col)
  end

  local first = lines[1]
  if beg_col > #first then
    return nil
  end

  local parts = {}
  parts[#parts + 1] = first:sub(beg_col)

  for i = 2, #lines - 1 do
    parts[#parts + 1] = lines[i]
  end

  local last = lines[#lines]
  if end_col > #last then
    return nil
  end
  parts[#parts + 1] = last:sub(1, end_col)

  return table.concat(parts, "\n")
end

function M.highlight_visual_selection(hi_index)
  vim.api.nvim_exec([[
    let [beg_line, beg_col] = getpos("'<")[1:2]
    let [end_line, end_col] = getpos("'>")[1:2]
  ]], false)

  local beg_line = vim.api.nvim_eval("beg_line")
  local beg_col = vim.api.nvim_eval("beg_col")
  local end_line = vim.api.nvim_eval("end_line")
  local end_col = vim.api.nvim_eval("end_col")

  M.apply_highlight(0, hi_index, beg_line, beg_col, end_line, end_col)

  local text = M.get_text(0, beg_line, beg_col, end_line, end_col)
  local filepath = vim.fn.expand("%:p")

  require("annotations.storage").add_annotation(filepath, {
    beg_line = beg_line,
    beg_col = beg_col,
    end_line = end_line,
    end_col = end_col,
    text = text,
    hi_index = hi_index,
  })
end

return M
