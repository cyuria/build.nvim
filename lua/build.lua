---@class BuildNvim
local M = {}

---@class BuildNvimConfig
vim.g.build_nvim_options = {
	---@type string[]
	root = {
		".bzr",
		".git",
		".hg",
		".svn",
		"_darcs",
		"package.json",
	},

	---@type { [string]: string }[]
	compilers = {
		{
            ["build.sh"] = "build_sh",
        },
		{
			["CMakeLists.txt"] = "cmake",
			["Cargo.toml"] = "cargo",
			["Justfile"] = "just",
			["build.zig"] = "zig",
			["justfile"] = "just",
			["meson.build"] = "meson",
			["setup.py"] = "setuptools",
		},
		{
			["Makefile"] = "make",
			["build.ninja"] = "ninja",
			["package.json"] = "npm",
		},
	},

	---@deprecated
	---@type string[]?
	update_events = nil,

	---@deprecated
	---@type string[]?
	root_extra = nil,

	---@deprecated
	---@type { [string]: string }[]?
	compilers_extra = nil,
}

-- Merge extra options from root and compilers. Will be removed with next major version release
--
---@param root_extra? string[]
---@param compilers_extra? { [string]: string }[]
local function merge_extras(root_extra, compilers_extra)
	if root_extra ~= nil then
		vim.list_extend(vim.g.build_nvim_options.root, root_extra)
	end

	if compilers_extra ~= nil then
		-- can't use vim.tbl_deep_extend() because we need to merge the lists
		for stage, v in ipairs(compilers_extra) do
			vim.g.build_nvim_options.compilers[stage] = vim.tbl_extend('force', vim.g.build_nvim_options.compilers[stage] or {}, v)
		end
	end
end

-- Set autocommands to change the compiler
--
---@param autocmds string[]
function M.autocmds(autocmds)
	local augroup = vim.api.nvim_create_augroup("build.nvim", { clear = true })
	if #autocmds == 0 then
		return
	end
	vim.api.nvim_create_autocmd(autocmds, {
		group = augroup,
		callback = function()
			M.search()
		end,
	})
end

-- Change the options for build.nvim, sets vim.g.build_nvim_options and calls
--
---@param opts? BuildNvimConfig
function M.setup(opts)
	vim.g.build_nvim_options = vim.tbl_extend("force", vim.g.build_nvim_options, opts or {})

	-- deprecated behaviour from here on
	if vim.g.build_nvim_options.root_extra ~= nil or vim.g.build_nvim_options.compilers_extra ~= nil then
		vim.deprecate(
			"setup() root and compiler extra arguments",
			"vim.g.build_nvim_options.root_extra and vim.g.build_nvim_options.comnpilers_extra",
			"3.0.0",
			"build.nvim"
		)
		merge_extras(vim.g.build_nvim_options.root_extra, vim.g.build_nvim_options.compilers_extra)
		vim.g.build_nvim_options.root_extra = nil
		vim.g.build_nvim_options.compilers_extra = nil
	end

	if vim.g.build_nvim_options.update_events ~= nil then
		vim.deprecate(
			"setup() update_events argument",
			"require('build').autocmds({...}) directly",
			"3.0.0",
			"build.nvim"
		)
		M.autocmds(vim.g.build_nvim_options.update_events)
	end
end

-- Searches for the project root directory from the current open buffer file path
---@return string? project root directory
-- Finds the project's build system
---@param root string project root directory
---@return string|nil
local function find_build_system(root)
	local path = vim.fs.normalize(vim.fs.abspath(root))

	for _, compilers in ipairs(vim.g.build_nvim_options.compilers) do
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

	local root = vim.fs.root(0, vim.g.build_nvim_options.root)
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
