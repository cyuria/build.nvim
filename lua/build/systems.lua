
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
}

---@alias ProgramHandler fun(root?:string, build?:string):string

---@type table<string, ProgramHandler>
M.programs = {
    cmake = function (root, build)
        local directory = build or root or '.'
        return "cmake --build " .. directory
    end,
    make = function (root, _)
        if not root then
            return "make $*"
        else
            return "make $* -C " .. root
        end
    end,
    meson = function (_, build)
        if not build then
            return "meson $*"
        else
            return "meson $* -C " .. build
        end
    end,
    cargo = function (_, _)
        return "cargo $*"
    end,
    zig = function (_, _)
        return "zig build $*"
    end,
    setuptools = function (root, _)
        if not root then
            return "python setup.py build $*"
        else
            return "cd " .. root .. " && python setup.py build $*"
        end
    end,
}

return M
