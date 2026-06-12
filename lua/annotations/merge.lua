local M = {}

local function col_start(ann, line)
	return ann.beg_line == line and ann.beg_col or 1
end

local function col_end(ann, line)
	return ann.end_line == line and ann.end_col or math.huge
end

function M.ranges_overlap(a, b)
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

function M.union(a, b)
	local merged_beg_line = a.beg_line
	local merged_beg_col = a.beg_col
	local merged_end_line = a.end_line
	local merged_end_col = a.end_col

	if b.beg_line < merged_beg_line then
		merged_beg_line = b.beg_line
		merged_beg_col = b.beg_col
	elseif b.beg_line == merged_beg_line then
		merged_beg_col = math.min(merged_beg_col, b.beg_col)
	end

	if b.end_line > merged_end_line then
		merged_end_line = b.end_line
		merged_end_col = b.end_col
	elseif b.end_line == merged_end_line then
		merged_end_col = math.max(merged_end_col, b.end_col)
	end

	return {
		beg_line = merged_beg_line,
		beg_col = merged_beg_col,
		end_line = merged_end_line,
		end_col = merged_end_col,
		text = a.text,
		hi_index = a.hi_index,
	}
end

function M.deduplicate(annotations)
	local result = {}
	for _, ann in ipairs(annotations) do
		table.insert(result, vim.deepcopy(ann))
	end

	local changed = true
	while changed do
		changed = false
		local i = 1
		while i <= #result do
			local j = i + 1
			while j <= #result do
				if M.ranges_overlap(result[i], result[j]) then
					result[i] = M.union(result[i], result[j])
					table.remove(result, j)
					changed = true
				else
					j = j + 1
				end
			end
			i = i + 1
		end
	end

	return result
end

return M
