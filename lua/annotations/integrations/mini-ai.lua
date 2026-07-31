local M = {}

function M.create_text_object()
	return function()
		local filepath = vim.fn.expand("%:p")
		if filepath == "" then
			return nil
		end
		local annotations = require("annotations.storage").get_annotations_for_file(filepath)
		if #annotations == 0 then
			return nil
		end

		table.sort(annotations, function(a, b)
			if a.beg_line ~= b.beg_line then
				return a.beg_line < b.beg_line
			end
			return a.beg_col < b.beg_col
		end)

		local cursor = vim.api.nvim_win_get_cursor(0)
		local cursor_line = cursor[1]
		local cursor_col = cursor[2] + 1

		for _, ann in ipairs(annotations) do
			local cursor_before_end = ann.end_line > cursor_line
				or (ann.end_line == cursor_line and ann.end_col >= cursor_col)

			if cursor_before_end then
				local current_text =
					require("annotations.highlight").get_text(0, ann.beg_line, ann.beg_col, ann.end_line, ann.end_col)

				if current_text and current_text == ann.text then
					return {
						from = { line = ann.beg_line, col = ann.beg_col },
						to = { line = ann.end_line, col = ann.end_col },
					}
				end
			end
		end

		return nil
	end
end

function M.setup(config)
	local key = config.text_object or "h"

	local spec = M.create_text_object()

	local ok, mini_ai = pcall(require, "mini.ai")
	if ok then
		mini_ai.config = mini_ai.config or {}
		mini_ai.config.custom_textobjects = mini_ai.config.custom_textobjects or {}
		mini_ai.config.custom_textobjects[key] = spec
	end

	vim.g.miniai_config = vim.g.miniai_config or {}
	vim.g.miniai_config.custom_textobjects = vim.g.miniai_config.custom_textobjects or {}
	vim.g.miniai_config.custom_textobjects[key] = spec
end

return M
