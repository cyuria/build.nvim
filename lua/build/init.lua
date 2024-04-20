
local systems = require('build.systems')

local M = {}

local opts = {
    set_makeprg_immediately = true,
    update_on_event = { "DirChanged", },
    root_files = {
        ".git",
        "package.json",
        "_darcs",
        ".hg",
        ".hg",
        ".bzr",
        ".svn",
    },
    build_dirs = {
        "build", "builddir", "bin"
    },
    extra_indicators = {},
    extra_programs = {},
    build_dirs_file = vim.fn.stdpath('data') .. '/build.nvim/build_directories.json',
}

local build_dirs_override = {}

local function read_file_async(filename, callback)
    vim.uv.fs_open(filename, 'r', 438, function (err_open, fd)
        if err_open then return err_open end
        vim.uv.fs_stat(filename, function (err_stat, stat)
            if err_stat then return err_stat end
            vim.uv.fs_read(fd, stat.size, 0, function (err_read, data)
                if err_read then return err_read end
                vim.uv.fs_close(fd, function (err_close)
                    if err_close then return err_close end
                    return callback(data)
                end)
            end)
        end)
    end)
end
local function write_file_async(filename, data, callback)
    if callback == nil then callback = function () end end
    vim.uv.fs_mkdir(vim.fs.dirname(filename), 448, function (err_mkdir)
        if err_mkdir then return err_mkdir end
        vim.uv.fs_open(filename, 'w', 438, function (err_open, fd)
            if err_open then return err_open end
            vim.uv.fs_write(filename, data, 0, function (err_write, bytes)
                if err_write or bytes ~= string.len(data) then return err_write end
                vim.uv.fs_close(fd, function (err_close)
                    if err_close then return err_close end
                    return callback()
                end)
            end)
        end)
    end)
end

local function load_build_overrides()
    return read_file_async(opts.build_dirs_file, function (content)
        if content == nil then return end
        build_dirs_override = vim.json.decode(content)
    end)
end
local function store_build_overrides()
    local data = vim.json.encode(build_dirs_override)
    write_file_async(opts.build_dirs_file, data)
end

local function find_root()
    return vim.fs.dirname(vim.fs.find(opts.root_files, {
        upward = true,
        stop = vim.uv.os_homedir(),
        path = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    })[1])
end

local function find_build_dir(root)
    if root == nil then root = find_root() end

    local dir = build_dirs_override[root]
    if dir ~= nil then return dir end

    return vim.fs.find(opts.build_dirs, {
        upward = true,
        stop = root,
        path = root
    })[1]
end

local function find_system(root)
    if root == nil then root = find_root() end

    local buildcfgfiles = {}
    local n = 0
    for k,_ in pairs(opts.indicators) do
        n = n + 1
        buildcfgfiles[n] = k
    end
    local file = vim.fs.basename(vim.fs.find(buildcfgfiles, { path = root, })[1])
    return opts.indicators[file]
end

function M.set_makeprg()
    local root = find_root()
    local system = find_system(root)
    local builddir = find_build_dir(root)

    local makeprg_builder = systems.programs[system]
    if makeprg_builder == nil then return end

    vim.o.makeprg = makeprg_builder(root, builddir)
end

function M.set_build_dir(dir, root)
    if dir == nil then return end

    if root == nil then
        root = find_root()
    end
    build_dirs_override[root] = dir
    store_build_overrides()
end

function M.setup(user_opts)
    opts = vim.tbl_extend("force", opts, user_opts or {})

    opts.indicators = vim.tbl_extend("force", systems.indicators, opts.extra_indicators)
    opts.programs = vim.tbl_extend("force", systems.programs, opts.extra_programs)

    load_build_overrides()
    if opts.set_makeprg_immediately then
        M.set_makeprg()
    end
    if #opts.update_one_event ~= 0 then
        vim.api.nvim_create_autocmd(opts.update_on_event, {
            callback = M.set_makeprg,
        })
    end

    vim.api.nvim_create_user_command("SetMakeprg", function (_)
        M.set_makeprg()
    end, { nargs = "0" })
    vim.api.nvim_create_user_command("SetBuildDir", function (info)
        if info.nargs > 2 then
            print("Too many arguments passed to command", info.name)
            print("Expected at most two arguments")
            return
        end
        M.set_build_dir(info.args[1], info.args[2])
    end, { nargs = "*", complete = "dir" })
end

return M
