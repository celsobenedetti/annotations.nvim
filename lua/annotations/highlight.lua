local M = {}

local ns = vim.api.nvim_create_namespace("annotations")

function M.get_namespace()
	return ns
end

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
		vim.api.nvim_buf_add_highlight(bufnr, ns, hi_group, beg_line - 1, beg_col - 1, end_col)
	else
		vim.api.nvim_buf_add_highlight(bufnr, ns, hi_group, beg_line - 1, beg_col - 1, get_cols(beg_line) - 1)

		for line = beg_line + 1, end_line - 1 do
			vim.api.nvim_buf_add_highlight(bufnr, ns, hi_group, line - 1, 0, get_cols(line) - 1)
		end

		vim.api.nvim_buf_add_highlight(bufnr, ns, hi_group, end_line - 1, 0, end_col)
	end
end

function M.get_text(bufnr, beg_line, beg_col, end_line, end_col)
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	if beg_line > line_count then
		return ""
	end

	local actual_end = math.min(end_line, line_count)
	local lines = vim.api.nvim_buf_get_lines(bufnr, beg_line - 1, actual_end, false)
	if #lines == 0 then
		return ""
	end

	if beg_line == end_line then
		local line = lines[1]
		local start = math.max(1, beg_col)
		local finish = math.min(end_col, #line)
		if start > finish then
			return ""
		end
		return line:sub(start, finish)
	end

	local parts = {}
	local first = lines[1]
	table.insert(parts, first:sub(math.max(1, beg_col)))

	for i = 2, #lines - 1 do
		table.insert(parts, lines[i])
	end

	local last = lines[#lines]
	local finish = end_col
	if finish == 0 or finish > #last then
		finish = #last
	end
	table.insert(parts, last:sub(1, finish))

	return table.concat(parts, "\n")
end

function M.highlight_visual_selection(hi_index)
	vim.api.nvim_exec(
		[[
    let [beg_line, beg_col] = getpos("'<")[1:2]
    let [end_line, end_col] = getpos("'>")[1:2]
  ]],
		false
	)

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
