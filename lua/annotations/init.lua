local M = {}

local DEFAULT_OPTIONS = {
	storage_path = vim.fn.stdpath("data") .. "/annotations.json",
	sidebar_position = "left",
	notify_level = vim.log.levels.INFO,
	highlight_colors = {
		-- colors from goated neovim default colorscheme
		color_0 = { "#f4d88c", "smart" },
		color_1 = { "#9fd8ff", "smart" },
		color_2 = { "#83efef", "smart" },
		color_3 = { "#aaedb7", "smart" },
		color_4 = { "#ebeef5", "smart" },
		color_5 = { "#d7dae1", "smart" },
		color_6 = { "#c4c6cd", "smart" },
		color_7 = { "#9b9ea4", "smart" },
		color_8 = { "#ffc3fa", "smart" },
		color_9 = { "#ffbcb5", "smart" },
	},
	integrations = {
		["mini.ai"] = {
			enable = true,
			text_object = "h",
		},
	},
}

M.options = DEFAULT_OPTIONS

local function set_options(opts)
	for k, v in pairs(opts) do
		if M.options[k] ~= nil then
			if type(v) == "table" and type(M.options[k]) == "table" then
				for sk, sv in pairs(v) do
					M.options[k][sk] = sv
				end
			else
				M.options[k] = v
			end
		end
	end
end

local function setup_commands()
	vim.api.nvim_create_user_command("AnnotationsAdd", function(opts)
		require("annotations.main").add(opts.args ~= "" and opts.args or "0")
	end, {
		nargs = "?",
		force = true,
		complete = function()
			return { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
		end,
	})

	vim.api.nvim_create_user_command("AnnotationsQuickfix", function()
		require("annotations.main").quickfix()
	end, { force = true })

	vim.api.nvim_create_user_command("AnnotationsClear", function()
		require("annotations.main").clear()
	end, { force = true })

	vim.api.nvim_create_user_command("AnnotationsSidebar", function(opts)
		require("annotations.main").sidebar(opts.args)
	end, {
		nargs = "?",
		force = true,
		complete = function()
			return { "left", "right" }
		end,
	})

	vim.api.nvim_create_user_command("AnnotationsRestore", function()
		require("annotations.main").restore_manual()
	end, { force = true })

	vim.api.nvim_create_user_command("AnnotationsToggle", function()
		require("annotations.main").toggle_highlights()
	end, { force = true })
end

function M.setup(opts)
	if opts then
		set_options(opts)
	end

	setup_commands()
	require("annotations.highlight").setup_highlight_groups()

	if M.options.integrations["mini.ai"].enable ~= false then
		local ok = pcall(require, "mini.ai")
		if ok then
			pcall(function()
				require("annotations.integrations.mini-ai").setup(M.options.integrations["mini.ai"])
			end)
		end
	end

	local is_valid_buffer = function()
		return vim.bo.buftype == "" and vim.fn.expand("%:p") ~= ""
	end

	local group = vim.api.nvim_create_augroup("AnnotationsPlugin", { clear = true })

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		pattern = "*",
		callback = function()
			if require("annotations.main").highlights_hidden or not is_valid_buffer() then
				return
			end
			vim.schedule(function()
				require("annotations.main").restore()
			end)
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "*",
		callback = function()
			if not is_valid_buffer() then
				return
			end
			if require("annotations.main").highlights_hidden then
				local ns = require("annotations.highlight").get_namespace()
				vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
				return
			end
			vim.schedule(function()
				require("annotations.main").restore()
			end)
		end,
	})

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		pattern = "*",
		callback = function()
			require("annotations.highlight").setup_highlight_groups()
			if require("annotations.main").highlights_hidden then
				return
			end
			vim.schedule(function()
				require("annotations.main").restore()
			end)
		end,
	})

	vim.schedule(function()
		if not require("annotations.main").highlights_hidden then
			require("annotations.main").restore()
		end
	end)
end

return M
