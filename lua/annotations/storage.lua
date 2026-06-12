local M = {}
local merge = require("annotations.merge")

local function get_storage_path()
  local config = require("annotations").options
  return config.storage_path or vim.fn.stdpath("data") .. "/annotations.json"
end

local function load()
  local path = get_storage_path()
  local ok, data = pcall(function()
    local lines = vim.fn.readfile(path)
    return vim.json.decode(table.concat(lines, "\n"))
  end)
  if ok and type(data) == "table" then
    return data
  end
  return {}
end

local function save(data)
  local path = get_storage_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
  vim.fn.writefile({vim.json.encode(data)}, path)
end

function M.get_annotations_for_file(filepath)
  local data = load()
  return data[filepath] or {}
end

function M.add_annotation(filepath, annotation)
  local data = load()
  if not data[filepath] then
    data[filepath] = {}
  end
  table.insert(data[filepath], annotation)
  data[filepath] = merge.deduplicate(data[filepath])
  save(data)
end

function M.save_annotations_for_file(filepath, annotations)
  local data = load()
  if #annotations > 0 then
    data[filepath] = merge.deduplicate(annotations)
  else
    data[filepath] = nil
  end
  save(data)
end

function M.remove_annotation_by_position(filepath, beg_line, beg_col, end_line, end_col)
  local data = load()
  if not data[filepath] then return false end

  for i, ann in ipairs(data[filepath]) do
    if ann.beg_line == beg_line and ann.beg_col == beg_col
       and ann.end_line == end_line and ann.end_col == end_col then
      table.remove(data[filepath], i)
      if #data[filepath] == 0 then
        data[filepath] = nil
      end
      save(data)
      return true
    end
  end
  return false
end

function M.clear_annotations_for_file(filepath)
  local data = load()
  data[filepath] = nil
  save(data)
end

return M
