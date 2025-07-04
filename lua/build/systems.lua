---@class Systems
local M = {}

---@type table<string, string>
M.indicators = {
    ["CMakeLists.txt"] = "cmake",
    ["Makefile"] = "make",
    ["meson.build"] = "meson",
    ["Cargo.toml"] = "cargo",
    ["build.zig"] = "zig",
    ["setup.py"] = "setuptools",
    ["build.ninja"] = "ninja",
}

---@alias ProgramHandler fun(root?:string, build?:string):string

---@type table<string, ProgramHandler>
M.programs = {
    cmake = function(root, build)
        local directory = build or root or '.'
        return "cmake --build " .. directory
    end,
    make = function(root, _)
        if not root then
            return "make $*"
        else
            return "make $* -C " .. root
        end
    end,
    meson = function(_, build)
        if not build then
            return "meson $*"
        else
            return "meson $* -C " .. build
        end
    end,
    cargo = function(_, _)
        return "cargo $*"
    end,
    zig = function(_, _)
        return "zig build $*"
    end,
    setuptools = function(root, _)
        if not root then
            return "python setup.py build $*"
        else
            return "cd " .. root .. " && python setup.py build $*"
        end
    end,
    ninja = function(root, build)
        -- search the build directory for a build.ninja file. If none such
        -- exist, then search the current working directory, followed by the
        -- entire project from the root for one. Failing that, use the build
        -- directory as a last resort backup

        local ninjadir = vim.fs.dirname(
            vim.fs.find(
                { 'build.ninja' },
                { type = 'file', upward = true, path = build }
            )[0] or vim.fs.find(
                { 'build.ninja' },
                { type = 'file', upward = true }
            )[0] or vim.fs.find(
                { 'build.ninja' },
                { type = 'file', upward = true, path = root }
            )[0]
        )
        if ninjadir == nil then
            ninjadir = build
        end

        if ninjadir == nil then
            return "ninja $*"
        else
            return "ninja -C " .. build .. " $*"
        end
    end,
}

return M
