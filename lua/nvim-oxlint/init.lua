local M = {}

--- Writes to error buffer.
---@param ... string Will be concatenated before being written
local function err_message(...)
	vim.notify(table.concat(vim.iter({ ... }):flatten():totable()), vim.log.levels.ERROR)
	vim.api.nvim_command("redraw")
end

--- @return string | nil
local function local_binary_path()
	local path = vim.fn.getcwd() .. "/.node_modules/oxc_language_server"
	if vim.loop.fs_stat(path) then
		return path
	end

	return nil
end

--- @return string|nil
local function find_global_binary_path(binary_name)
	local path = vim.fn.exepath(binary_name)
	if path == "" then
		return nil -- Binary not found
	end
	return path
end

local oxlint_config_files = {
	"oxlintrc.json",
	".oxlintrc.json",
}

function M.check_config_presence()
	local cwd = vim.fn.getcwd() -- Get the current working directory

	for _, config_file in ipairs(oxlint_config_files) do
		local file_path = cwd .. "/" .. config_file
		if vim.loop.fs_stat(file_path) then
			return true
		end
	end

	return false
end

function M.make_settings(user_config)
	return {
		run = user_config.run or "onType",
		enable = user_config.enable or true,
		config_path = user_config.config_path or ".oxlintrc.json",
	}
end

function M.lsp_start(user_config)
	local lsp_cmd = user_config.bin_path or local_binary_path()

	vim.notify(lsp_cmd)

	vim.api.nvim_create_autocmd("FileType", {
		pattern = vim.tbl_extend("force", {
			"javascript",
			"javascriptreact",
			"javascript.jsx",
			"typescript",
			"typescriptreact",
			"typescript.tsx",
			"vue",
			"svelte",
			"astro",
		}, M.user_config.filetypes or {}),
		callback = function(args)
			vim.lsp.start({
				name = "oxlint",
				cmd = lsp_cmd,
				settings = M.make_settings(args.buf),
				capabilities = user_config.capabilities,
				handlers = vim.tbl_deep_extend("keep", M.user_config.handlers or {}, {
					["workspace/didChangeConfiguration"] = function(_, result, ctx)
						local function lookup_section(table, section)
							local keys = vim.split(section, ".", { plain = true }) --- @type string[]
							return vim.tbl_get(table, unpack(keys))
						end

						local client_id = ctx.client_id
						local client = vim.lsp.get_client_by_id(client_id)
						if not client then
							err_message(
								"LSP[",
								client_id,
								"] client has shut down after sending a workspace/configuration request"
							)
							return
						end
						if not result.items then
							return {}
						end

						--- Insert custom logic to update client settings
						local new_settings = M.make_settings(user_config)
						client.settings = new_settings
						--- end custom logic

						local response = {}
						for _, item in ipairs(result.items) do
							if item.section then
								local value = lookup_section(client.settings, item.section)
								-- For empty sections with no explicit '' key, return settings as is
								if value == nil and item.section == "" then
									value = client.settings
								end
								if value == nil then
									value = vim.NIL
								end
								table.insert(response, value)
							end
						end

						return response
					end,
				}),
			})
		end,
	})
end

function M.setup(user_config)
	if M.check_config_presence() then
		M.lsp_start(user_config)
	end
end

return M
