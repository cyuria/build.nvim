
local M = {}

M.indicators = {
    ["CMakeLists.txt"] = "cmake",
    ["Makefile"] = "make",
    ["meson.build"] = "meson",
    ["Cargo.toml"] = "cargo",
    ["build.zig"] = "zig",
}

M.programs = {
    cmake = function (root, build)
        return "cmake --build " .. (build or root or '.')
    end,
    make = function (root, _)
        return "make" .. (root and " -C " .. root or "")
    end,
    meson = function (_, build)
        return "meson $*" .. (build and " -C " .. build or "")
    end,
    cargo = function (_, _)
        return "cargo $*"
    end,
    zig = function (_, _)
        return "zig build $*"
    end,
}

return M
