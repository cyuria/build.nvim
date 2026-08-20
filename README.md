# build.nvim

A neovim plugin written in lua which automatically detects the build system of
your current project and sets `makeprg` accordingly.

## Requirements

- neovim >= 0.8

## Features

Automatically detects your build system based on the first build file found,
currently supports:
- CMake (`CMakeLists.txt`)
- Make (`Makefile`)
- Meson (`meson.build`)
- Zig (`build.zig`)
- Cargo (`Cargo.toml`)
- Setuptools (`setup.py`)
- Ninja (`build.ninja`)

Automatically detects project root based on the presence of a file
- Git, mercurial, svn and a few other version control systems
- A `package.json` file
- Failing all else, *build.nvim* searches recursively downwards for known
  build system files

Highly customisable, with sensible defaults
- You can configure almost everything.

## Installation

Install as you would any other plugin.

### vim-plug

```vim
" Vimscript
Plug "cyuria/build.nvim"

lua << EOF
require('build').setup {
    -- put your configuration here
    -- or don't, see the config section for
    -- available options and defaults
}
EOF
```

### lazy

```lua
{
    "cyuria/build.nvim",
    event = { "DirChanged", "BufRead" },
    opts = {}
}
```

### packer

```lua
-- lua
use {
    "cyuria/build.nvim",
    config = function()
        require('build').setup {
            -- put your configuration here
            -- or don't, see the config section for
            -- available options and defaults
        }
    end
}
```

## Usage

For detailed info, see `:help build.nvim`.

*build.nvim* seamlessly integrates with `:compiler` and `:make`, simply call
`:make` and everything should work pretty much out of the box.

## Configuration

*build.nvim* comes with the following options and defaults.

```lua
require('build').setup({
    -- A list of marker files which indicate the parent directory should be
    -- considered the project root
    root = {
    	".bzr",
    	".git",
    	".hg",
    	".svn",
    	"_darcs",
    	"package.json",
    },

    -- A list of marker files and compiler/build system association sorted by
    -- priority
	compilers = {
		{
            ["build.sh"] = "build_sh",
        },
        {
			["CMakeLists.txt"] = "cmake",
			["Cargo.toml"] = "cargo",
			["Justfile"] = "just",
			["build.zig"] = "zig_build",
			["justfile"] = "just",
			["meson.build"] = "meson",
			["setup.py"] = "setuptools",
		},
		{
			["Makefile"] = "make",
			["build.ninja"] = "ninja",
			["package.json"] = "npm",
		},
	},

    -- deprecated options, see `:h build.nvim`
    update_events = nil,
    root_extra = nil,
    compilers_extra = nil,
})
```

## Contributing

Please feel free to submit any PRs or issues, especially if they add support for
more build systems. It would be great if we could support every build system
under the sun.

Some currently unsupported systems which would be nice to support are
- build2
- Maven or Gradle or something java I don't know
- Bazel
- Better support for the different variations of Make (i.e. GNU make vs BSD
  make vs NMake etc)
