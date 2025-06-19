local systems = require('build.systems')

---@class BuildNvim
local M = {}

---@class BuildNvimConfig
local opts = {
    ---@type boolean
    set_makeprg_immediately = true,
    ---@type string[]
    update_on_event = { "DirChanged", },
    ---@type string[]
    root_files = {
        ".git",
        "package.json",
        "_darcs",
        ".hg",
        ".bzr",
        ".svn",
    },
    ---@type string[]
    build_dirs = {
        "build", "builddir", "bin"
    },
    ---@type table<string, string>
    extra_indicators = {},
    ---@type table<string, ProgramHandler>
    extra_programs = {},
    ---@type string
    build_dirs_file = vim.fn.stdpath('data') .. '/build.nvim/build_directories.json',
}

---@type table<string, string>
local build_dirs_override = {}

---@param filename string file path to read from
---@return string|nil file_contents
local function read_file(filename)
    local fd, err_open = vim.uv.fs_open(filename, 'r', 438)
    if fd == nil then
        print(err_open)
        return
    end

    local stat, err_stat = vim.uv.fs_stat(filename)
    if stat == nil then
        print(err_stat)
        return
    end

    local data, err_read = vim.uv.fs_read(fd, stat.size, 0)
    if data == nil then
        print(err_read)
        return
    end

    local success, err_close = vim.uv.fs_close(fd)
    if success == nil then
        print(err_close)
        return
    end

    return data
end
---@param filename string file path to write to
---@param data string file contents to write
local function write_file(filename, data)
    local mkdir_success, err_mkdir = vim.uv.fs_mkdir(vim.fs.dirname(filename), 448)
    if mkdir_success == nil then
        print(err_mkdir)
        return
    end

    local fd, err_open = vim.uv.fs_open(filename, 'w', 438)
    if fd == nil then
        print(err_open)
        return
    end

    local bytes, err_write = vim.uv.fs_write(fd, data, 0)
    if bytes ~= string.len(data) then
        print(err_write)
        return
    end

    local close_success, err_close = vim.uv.fs_close(fd)
    if close_success == nil then
        print(err_close)
        return
    end
end

-- Stores the build overrides in the persistent file
local function store_build_overrides()
    local data = vim.json.encode(build_dirs_override)
    write_file(opts.build_dirs_file, data)
end
-- Loads the build overrides into the module variable
local function load_build_overrides()
    local json = read_file(opts.build_dirs_file)
    if json == nil then
        -- Likely because the file doesn't exist, so overwrite it
        store_build_overrides()
        return
    end
    build_dirs_override = vim.json.decode(json)
end

-- Searches for an indicator file somewhere in the project
-- Uses the current working directory if no path is provided
---@param path? string project root path to begin search from
---@return string|nil indicator_path
local function find_indicator(path)
    local buildcfgfiles = {}
    local n = 0
    for k, _ in pairs(systems.indicators) do
        n = n + 1
        buildcfgfiles[n] = k
    end
    return vim.fs.find(buildcfgfiles, { path = path, })[1]
end

-- Searches for the project root directory from the current open buffer file path
---@return string|nil project root directory
local function find_root()
    local root_indicator = vim.fs.find(opts.root_files, {
        upward = true,
        path = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    })[1] or find_indicator()
    return vim.fs.dirname(root_indicator)
end

-- Searches for the project's build directory
---@param root? string project root directory
---@return string|nil project build directory
local function find_build_dir(root)
    root = root or find_root()

    if build_dirs_override[root] ~= nil then
        return build_dirs_override[root]
    end

    return vim.fs.find(opts.build_dirs, { path = root })[1]
end

-- Finds the project's build system
---@param root? string project root directory
---@return string|nil
local function find_build_system(root)
    root = root or find_root()
    local file = vim.fs.basename(find_indicator(root))
    return systems.indicators[file]
end

-- Detects the build system and sets the `vim.o.makeprg` variable accordingly
---@param system? string build system name, autodetect if not present
---@param root? string path to the project root, autodetect if not present
---@param builddir? string path to the build directory, autodetect if not present
---@see vim.o.makeprg
function M.set_makeprg(system, root, builddir)
    root = root or find_root()
    system = system or find_build_system(root)
    builddir = builddir or find_build_dir(root)

    local makeprg_builder = systems.programs[system]
    if makeprg_builder == nil then return end

    vim.o.makeprg = makeprg_builder(root, builddir)
end

-- Manually overrides the build directory for the current project
---@param dir string build directory for the project
---@param root? string project root directory, autodetect if `nil`
function M.set_build_dir(dir, root)
    if dir == nil then return end

    if root == nil then
        root = find_root()
        if root == nil then return end
    end
    build_dirs_override[root] = dir
    store_build_overrides()
end

---@param user_opts BuildNvimConfig
function M.setup(user_opts)
    opts = vim.tbl_extend("force", opts, user_opts or {})

    systems.indicators = vim.tbl_extend("force", systems.indicators, opts.extra_indicators)
    systems.programs = vim.tbl_extend("force", systems.programs, opts.extra_programs)

    load_build_overrides()
    if opts.set_makeprg_immediately then
        M.set_makeprg()
    end
    if #opts.update_on_event ~= 0 then
        vim.api.nvim_create_autocmd(opts.update_on_event, {
            callback = M.set_makeprg,
        })
    end

    vim.api.nvim_create_user_command("SetMakeprg", function(_)
        M.set_makeprg()
    end, { nargs = 0 })
    vim.api.nvim_create_user_command("SetBuildDir", function(info)
        if #info.fargs > 2 then
            print("Too many arguments passed to command", info.name)
            print("Expected at most two arguments")
            return
        end
        M.set_build_dir(info.fargs[1], info.fargs[2])
    end, { nargs = "*", complete = "dir" })
end

return M
