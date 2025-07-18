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
                { type = 'file', path = build }
            )[1] or vim.fs.find(
                { 'build.ninja' },
                { type = 'file' }
            )[1] or vim.fs.find(
                { 'build.ninja' },
                { type = 'file', path = root }
            )[1]
        )

        if ninjadir ~= nil then
            return "ninja -C " .. ninjadir .. " $*"
        elseif build ~= nil then
            return "ninja -C " .. build .. " $*"
        else
            return "ninja $*"
        end
    end,
}

return M
