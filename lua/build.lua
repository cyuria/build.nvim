---@class BuildNvim
local M = {}

---@class BuildNvimConfig
local options = {
	---@type string[]
	update_events = {
		"DirChanged",
		"BufRead",
	},

	---@type string[]
	root = {
		".bzr",
		".git",
		".hg",
		".svn",
		"_darcs",
		"package.json",
	},
	---@type string[]
	root_extra = {},

	---@type { [string]: string }[]
	compilers = {
		{
			["Justfile"] = "just",
			["Makefile"] = "make",
			["build.ninja"] = "ninja",
			["justfile"] = "just",
		},
		{
			["CMakeLists.txt"] = "cmake",
			["Cargo.toml"] = "cargo",
			["build.zig"] = "zig",
			["meson.build"] = "meson",
			["setup.py"] = "setuptools",
		},
		{
			["package.json"] = "npm",
		},
	},

	---@type { [string]: string }[]
	compilers_extra = {},
}

-- Change the options for build.nvim
--
---@param opts? BuildNvimConfig
function M.setup(opts)
	options = vim.tbl_extend("force", options, opts or {})

	vim.list_extend(options.root, options.root_extra)
	-- can't use vim.tbl_deep_extend() because we need to merge the lists
	for stage, v in ipairs(options.compilers_extra) do
		options.compilers[stage] = vim.tbl_extend('force', options.compilers[stage] or {}, v)
	end

	local augroup = vim.api.nvim_create_augroup("build.nvim", {})
	if #options.update_events ~= 0 then
		vim.api.nvim_create_autocmd(options.update_events, {
			group = augroup,
			callback = function()
				M.search()
			end,
		})
	end
end

-- Searches for the project root directory from the current open buffer file path
---@return string? project root directory
-- Finds the project's build system
---@param root string project root directory
---@return string|nil
local function find_build_system(root)
	local path = vim.fs.normalize(vim.fs.abspath(root))

	for _, compilers in ipairs(options.compilers) do
		local file = vim.fs.find(vim.tbl_keys(compilers), { path = path })[1]
		if file ~= nil then
			vim.g.build_system_file = file
			return compilers[vim.fs.basename(file)]
		end
	end
	return nil
end

-- Attempts to detect the build system and call `:compiler` accordingly
---@param global? boolean set the compiler globally with `:compiler!`
---@param force? boolean set the compiler even if it has already been set
---@see vim.o.makeprg
function M.search(global, force)
	if not force then
		if global then
			if vim.g.current_compiler ~= nil then
				-- Compiler already set
				return
			end
		else
			if vim.b.current_compiler ~= nil then
				return
			end
		end
	end

	local root = vim.fs.root(0, options.root)
	if root == nil then
		vim.notify("Could not find project root", vim.log.levels.WARN)
		return
	end

	local system = find_build_system(root)
	if system == nil then
		return
	end

	if global then
		vim.cmd["compiler!"](system)
	else
		vim.cmd.compiler(system)
	end
end

return M
