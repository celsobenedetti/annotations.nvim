local M = {}

function M.info(msg)
	local config = require("annotations").options
	if config.notify_level ~= vim.log.levels.WARN then
		vim.notify(msg, vim.log.levels.INFO)
	end
end

function M.warn(msg)
	vim.notify(msg, vim.log.levels.WARN)
end

return M
