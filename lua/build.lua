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

	---@type { [string]: string }
	compilers = {
		["CMakeLists.txt"] = "cmake",
		["Cargo.toml"] = "cargo",
		["build.ninja"] = "ninja",
		["build.zig"] = "zig",
		["Justfile"] = "just",
		["justfile"] = "just",
		["meson.build"] = "meson",
		["package.json"] = "npm",
		["setup.py"] = "setuptools",
	},

	---@type { [string]: string }
	compilers_extra = {},
}

-- Merge 2 tables into a new one
--
---@param t1 table
---@param t2 table
---@return table
local function merge_tables(t1, t2)
	local new_table = {}
	for k, v in pairs(t1) do
		new_table[k] = v
	end
	for k, v in pairs(t2) do
		new_table[k] = v
	end
	return new_table
end

-- Change the options for build.nvim
--
---@param opts BuildNvimConfig
function M.setup(opts)
	options = vim.tbl_extend("force", options, opts or {})

	vim.list_extend(options.root, options.root_extra)
	options.compilers = merge_tables(options.compilers, options.compilers_extra)

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

	local file = vim.fs.find(vim.tbl_keys(options.compilers), { path = path })[1]
	return options.compilers[vim.fs.basename(file)]
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
