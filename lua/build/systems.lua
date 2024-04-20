
local M = {}

M.indicators = {
    ["CMakeLists.txt"] = "cmake",
    ["Makefile"] = "make",
    ["meson.build"] = "meson",
}

M.programs = {
    cmake = function (root, build)
        return "cmake --build " .. (build or root or '.')
    end,
    make = function (root, _)
        return "make" .. (root and " -C " .. root or "")
    end,
    meson = function (_, build)
        return "meson compile" .. (build and " -C " .. build or "")
    end,
}

return M
