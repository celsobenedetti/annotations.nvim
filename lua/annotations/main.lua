local M = {}
local log = require("annotations.log")
local storage = require("annotations.storage")
local highlight = require("annotations.highlight")

local function col_start(ann, line)
	return ann.beg_line == line and ann.beg_col or 1
end

local function col_end(ann, line)
	return ann.end_line == line and ann.end_col or math.huge
end

local function ranges_overlap(a, b)
	local ob = math.max(a.beg_line, b.beg_line)
	local oe = math.min(a.end_line, b.end_line)
	if ob > oe then
		return false
	end
	if ob == oe then
		return math.max(col_start(a, ob), col_start(b, ob)) <= math.min(col_end(a, ob), col_end(b, ob))
	end
	return true
end

local function reapply_all(bufnr, annotations)
	vim.api.nvim_buf_clear_namespace(bufnr, highlight.get_namespace(), 0, -1)
	for _, ann in ipairs(annotations) do
		highlight.apply_highlight(bufnr, ann.hi_index, ann.beg_line, ann.beg_col, ann.end_line, ann.end_col)
	end
end

function M.add(hi_index)
	hi_index = tonumber(hi_index) or 0

	local _, beg_line, beg_col, _ = unpack(vim.fn.getpos("'<"))
	if beg_line == 0 then
		log.warn("Annotations: no visual selection")
		return
	end

	local _, end_line, end_col, _ = unpack(vim.fn.getpos("'>"))

	local filepath = vim.fn.expand("%:p")
	local annotations = storage.get_annotations_for_file(filepath)
	local new_range = { beg_line = beg_line, beg_col = beg_col, end_line = end_line, end_col = end_col }

	for _, ann in ipairs(annotations) do
		if
			ann.beg_line == beg_line
			and ann.beg_col == beg_col
			and ann.end_line == end_line
			and ann.end_col == end_col
		then
			storage.remove_annotation_by_position(filepath, beg_line, beg_col, end_line, end_col)
			reapply_all(0, storage.get_annotations_for_file(filepath))
			pcall(function()
				require("annotations.sidebar").refresh()
			end)
			log.info("Annotations: removed annotation")
			return
		end
	end

	for i = #annotations, 1, -1 do
		local ann = annotations[i]
		if
			ann.beg_line <= beg_line
			and ann.end_line >= end_line
			and (ann.beg_line < beg_line or ann.beg_col <= beg_col)
			and (ann.end_line > end_line or ann.end_col >= end_col)
			and not (
				ann.beg_line == beg_line
				and ann.beg_col == beg_col
				and ann.end_line == end_line
				and ann.end_col == end_col
			)
		then
			storage.remove_annotation_by_position(filepath, ann.beg_line, ann.beg_col, ann.end_line, ann.end_col)
			reapply_all(0, storage.get_annotations_for_file(filepath))
			pcall(function()
				require("annotations.sidebar").refresh()
			end)
			log.info("Annotations: removed containing annotation")
			return
		end
	end

	local overlapping = {}
	local non_overlapping = {}
	for _, ann in ipairs(annotations) do
		if ranges_overlap(new_range, ann) then
			table.insert(overlapping, ann)
		else
			table.insert(non_overlapping, ann)
		end
	end

	if #overlapping > 0 then
		local merged_beg_line = beg_line
		local merged_beg_col = beg_col
		local merged_end_line = end_line
		local merged_end_col = end_col

		for _, ann in ipairs(overlapping) do
			if ann.beg_line < merged_beg_line then
				merged_beg_line = ann.beg_line
				merged_beg_col = ann.beg_col
			elseif ann.beg_line == merged_beg_line then
				merged_beg_col = math.min(merged_beg_col, ann.beg_col)
			end

			if ann.end_line > merged_end_line then
				merged_end_line = ann.end_line
				merged_end_col = ann.end_col
			elseif ann.end_line == merged_end_line then
				merged_end_col = math.max(merged_end_col, ann.end_col)
			end
		end

		local merged_text = highlight.get_text(0, merged_beg_line, merged_beg_col, merged_end_line, merged_end_col)

		storage.save_annotations_for_file(filepath, non_overlapping)
		storage.add_annotation(filepath, {
			beg_line = merged_beg_line,
			beg_col = merged_beg_col,
			end_line = merged_end_line,
			end_col = merged_end_col,
			text = merged_text,
			hi_index = hi_index,
		})

		reapply_all(0, storage.get_annotations_for_file(filepath))
		pcall(function()
			require("annotations.sidebar").refresh()
		end)
		log.info("Annotations: merged " .. #overlapping .. " annotation(s)")
		return
	end

	highlight.setup_highlight_groups()
	highlight.highlight_visual_selection(hi_index)
	pcall(function()
		require("annotations.sidebar").refresh()
	end)
end

function M.sidebar(dir)
	require("annotations.sidebar").toggle(dir)
end

function M.toggle_highlights()
	local bufnr = vim.api.nvim_get_current_buf()
	local ns = highlight.get_namespace()

	if vim.b[bufnr].annotations_hidden then
		vim.b[bufnr].annotations_hidden = nil
		M.restore()
		log.info("Annotations: highlights visible")
	else
		vim.b[bufnr].annotations_hidden = true
		vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
		log.info("Annotations: highlights hidden")
	end
end

function M.restore_manual()
	M.restore()
end

function M.quickfix()
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

	vim.api.nvim_buf_clear_namespace(0, highlight.get_namespace(), 0, -1)
	storage.clear_annotations_for_file(filepath)
	pcall(function()
		require("annotations.sidebar").refresh()
	end)
	log.info("Annotations: cleared for " .. filepath)
end

function M.restore()
	local filepath = vim.fn.expand("%:p")
	if filepath == "" then
		return
	end

	local annotations = storage.get_annotations_for_file(filepath)
	if #annotations == 0 then
		return
	end

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

	vim.b[bufnr].annotations_hidden = nil

	if removed > 0 then
		storage.save_annotations_for_file(filepath, valid)
		log.warn(string.format("Annotations: removed %d stale annotation(s)", removed))
	end
end

return M
