local M = {}

local sidebar_bufnr = nil
local sidebar_winid = nil
local source_bufnr = nil

local SEPARATOR = ""

local function get_annotations()
	if not source_bufnr or not vim.api.nvim_buf_is_valid(source_bufnr) then
		return {}
	end
	local filepath = vim.api.nvim_buf_get_name(source_bufnr)
	return require("annotations.storage").get_annotations_for_file(filepath)
end

function M.toggle(dir)
	if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
		M.close()
		return
	end
	source_bufnr = vim.api.nvim_get_current_buf()
	M.open(dir)
end

function M.open(dir)
	dir = dir or ""
	if dir == "" then
		dir = require("annotations").options.sidebar_position
	end

	if not source_bufnr or not vim.api.nvim_buf_is_valid(source_bufnr) then
		source_bufnr = vim.api.nvim_get_current_buf()
	end

	sidebar_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(sidebar_bufnr, "annotations://sidebar")

	if dir == "right" then
		vim.cmd("noau botright vertical 1split")
	else
		vim.cmd("noau topleft vertical 1split")
	end

	sidebar_winid = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(sidebar_winid, sidebar_bufnr)

	vim.wo[sidebar_winid].list = false
	vim.wo[sidebar_winid].number = false
	vim.wo[sidebar_winid].relativenumber = false
	vim.wo[sidebar_winid].signcolumn = "no"
	vim.wo[sidebar_winid].winfixwidth = true
	vim.wo[sidebar_winid].spell = false
	vim.api.nvim_win_set_width(sidebar_winid, 40)

	vim.b[sidebar_bufnr].source_buffer = source_bufnr

	vim.api.nvim_buf_set_keymap(sidebar_bufnr, "n", "<CR>", "", {
		callback = M.jump,
		noremap = true,
		silent = true,
	})

	vim.api.nvim_buf_set_keymap(sidebar_bufnr, "n", "q", "", {
		callback = M.close,
		noremap = true,
		silent = true,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = sidebar_bufnr,
		once = true,
		callback = function()
			sidebar_bufnr = nil
			sidebar_winid = nil
			source_bufnr = nil
		end,
	})

	M.render()
end

function M.close()
	if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
		vim.api.nvim_win_close(sidebar_winid, true)
	end
	if sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) then
		vim.api.nvim_buf_delete(sidebar_bufnr, { force = true })
	end
	sidebar_bufnr = nil
	sidebar_winid = nil
	source_bufnr = nil
end

function M.render()
	if not (sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr)) then
		return
	end

	local annotations = get_annotations()
	local lines = {}
	local line_to_ann = {}

	for idx, ann in ipairs(annotations) do
		local text = ann.text or ""
		local parts = vim.split(text, "\n", { plain = true })
		if #parts == 0 or (#parts == 1 and parts[1] == "") then
			parts = { "(no text)" }
		end

		for _, part in ipairs(parts) do
			table.insert(lines, part)
			table.insert(line_to_ann, idx)
		end

		if idx < #annotations then
			table.insert(lines, string.rep(SEPARATOR, 40))
			table.insert(line_to_ann, 0)
		end
	end

	if #lines == 0 then
		lines = { "(no annotations)" }
		line_to_ann = {}
	end

	vim.bo[sidebar_bufnr].modifiable = true
	vim.api.nvim_buf_set_lines(sidebar_bufnr, 0, -1, false, lines)
	vim.bo[sidebar_bufnr].modifiable = false
	vim.b[sidebar_bufnr].line_to_ann = line_to_ann
end

function M.jump()
	if not (sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid)) then
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(sidebar_winid)
	local line_to_ann = vim.b[sidebar_bufnr].line_to_ann or {}
	local ann_idx = line_to_ann[cursor[1]]
	if not ann_idx or ann_idx == 0 then
		return
	end

	local annotations = get_annotations()
	local ann = annotations[ann_idx]
	if not ann then
		return
	end
	if not (source_bufnr and vim.api.nvim_buf_is_valid(source_bufnr)) then
		M.close()
		return
	end

	local target_win = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == source_bufnr then
			target_win = win
			break
		end
	end

	if target_win then
		vim.api.nvim_set_current_win(target_win)
	else
		vim.api.nvim_set_current_buf(source_bufnr)
	end
	vim.api.nvim_win_set_cursor(0, { ann.beg_line, ann.beg_col - 1 })
	vim.cmd("normal! zz")
end

function M.refresh()
	if sidebar_bufnr and vim.api.nvim_buf_is_valid(sidebar_bufnr) then
		M.render()
	end
end

return M
