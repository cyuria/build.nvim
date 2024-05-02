
local M = {}

M.indicators = {
    ["CMakeLists.txt"] = "cmake",
    ["Makefile"] = "make",
    ["meson.build"] = "meson",
    ["Cargo.toml"] = "cargo",
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
    cargo = function (_, _)
        -- Consider changing to `cargo check`?
        return "cargo build"
    end,
}

return M
