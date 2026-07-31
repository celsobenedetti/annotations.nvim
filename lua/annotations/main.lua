local M = {}
local log = require("annotations.log")
local storage = require("annotations.storage")
local highlight = require("annotations.highlight")
local merge = require("annotations.merge")

M.highlights_hidden = false

local MAX_UNDO = 100
local undo_stacks = {}

local function push_undo(filepath, annotations)
	local stack = undo_stacks[filepath]
	if not stack then
		stack = {}
		undo_stacks[filepath] = stack
	end
	table.insert(stack, vim.deepcopy(annotations))
	if #stack > MAX_UNDO then
		table.remove(stack, 1)
	end
end

local function reapply_all(bufnr, annotations)
	vim.api.nvim_buf_clear_namespace(bufnr, highlight.get_namespace(), 0, -1)
	for _, ann in ipairs(annotations) do
		highlight.apply_highlight(bufnr, ann.hi_index, ann.beg_line, ann.beg_col, ann.end_line, ann.end_col)
	end
end

function M.add(hi_index)
	M.highlights_hidden = false

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
			push_undo(filepath, annotations)
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
			push_undo(filepath, annotations)
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
		if merge.ranges_overlap(new_range, ann) then
			table.insert(overlapping, ann)
		else
			table.insert(non_overlapping, ann)
		end
	end

	if #overlapping > 0 then
		local merged = {
			beg_line = beg_line,
			beg_col = beg_col,
			end_line = end_line,
			end_col = end_col,
			text = "",
			hi_index = hi_index,
		}
		for _, ann in ipairs(overlapping) do
			merged = merge.union(merged, ann)
		end
		merged.text = highlight.get_text(0, merged.beg_line, merged.beg_col, merged.end_line, merged.end_col)

		push_undo(filepath, annotations)
		storage.save_annotations_for_file(filepath, non_overlapping)
		storage.add_annotation(filepath, merged)

		reapply_all(0, storage.get_annotations_for_file(filepath))
		pcall(function()
			require("annotations.sidebar").refresh()
		end)
		log.info("Annotations: merged " .. #overlapping .. " annotation(s)")
		return
	end

	push_undo(filepath, annotations)
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

	if M.highlights_hidden then
		M.highlights_hidden = false
		M.restore()
		log.info("Annotations: highlights visible")
	else
		M.highlights_hidden = true
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

	push_undo(filepath, storage.get_annotations_for_file(filepath))
	vim.api.nvim_buf_clear_namespace(0, highlight.get_namespace(), 0, -1)
	storage.clear_annotations_for_file(filepath)
	pcall(function()
		require("annotations.sidebar").refresh()
	end)
	log.info("Annotations: cleared for " .. filepath)
end

function M.undo()
	local filepath = vim.fn.expand("%:p")
	if filepath == "" then
		return
	end

	local stack = undo_stacks[filepath]
	if not stack or #stack == 0 then
		log.info("Annotations: nothing to undo")
		return
	end

	local previous = table.remove(stack)
	storage.save_annotations_for_file(filepath, previous)
	reapply_all(0, storage.get_annotations_for_file(filepath))
	pcall(function()
		require("annotations.sidebar").refresh()
	end)
	log.info("Annotations: undone")
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
	local ns = highlight.get_namespace()

	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

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
		log.warn(string.format("Annotations: removed %d stale annotation(s)", removed))
	end
end

return M
