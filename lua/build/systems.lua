
local M = {}

M.indicators = {
    ["CMakeLists.txt"] = "cmake",
    ["Makefile"] = "make",
    ["meson.build"] = "meson",
    ["Cargo.toml"] = "cargo",
    ["build.zig"] = "zig",
    ["setup.py"] = "setuptools",
}

M.programs = {
    cmake = function (root, build)
        local directory = build or root or '.'
        return "cmake --build " .. directory
    end,
    make = function (root, _)
        if not root then
            return "make $*"
        end
        return "make $* -C " .. root
    end,
    meson = function (_, build)
        if not build then
            return "meson $*"
        end
        return "meson $* -C " .. build
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
        end
        return "cd " .. root .. " && python setup.py build $*"
    end,
}

return M
