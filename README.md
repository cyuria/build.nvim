# build.nvim

A neovim plugin written in lua which automatically detects the build system of
your current project and sets `makeprg` accordingly.

## Requirements

- neovim >= 0.8.0

## Features

- Automatically detects your build system based on the first build file found,
  currently supports:
  - CMake (`CMakeLists.txt`)
  - Make (`Makefile`)
  - Meson (`meson.build`)
- Automatically detects project root based on the presence of a file
  - Git, mercurial, svn and a few other version control systems
  - A `package.json` file
- Highly Customisable

## Installation

Install as you would any other plugin with your favourite package manager.

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

## Configuration

*build.nvim* comes with the following options and defaults.

```lua
local opts = {
    -- Set the makeprg variable during the setup call
    set_makeprg_immediately = true,

    -- A list of autocommand events upon which to update/set the makeprg
    -- varaible
    update_on_event = { "DirChanged", },
    -- A list of files used for detecting the project root. If any one of these
    -- files or directories is detected, that directory is selected as the root
    -- directory. If none of the files are found, recursively descend the
    -- directory tree until one of them is found
    root_files = {
        ".git",
        "package.json",
        "_darcs",
        ".hg",
        ".hg",
        ".bzr",
        ".svn",
    },
    -- A list of directories to search for which will be set as the build
    -- directory for the project
    build_dirs = {
        "build", "builddir", "bin"
    },
    -- Use specifiable build system indicators and handlers/programs
    extra_indicators = {},
    extra_programs = {},
    -- The path of the JSON file used to store individually set build
    -- directories on a case by case basis using the project root directory
    build_dirs_file = vim.fn.stdpath('data') .. '/build.nvim/build_directories.json',
}
```

## Usage

*build.nvim* exposes the following lua functions and vim commands.

```lua
local build = require('build')
```

- `:SetMakeprg`/`buildsystem.set_makeprg()`
  - Updates and sets the `makeprg` variable. Nothing will happen if no build
    system has been detected.
- `:SetBuildDir directory`/`buildsystem.set_build_dir(directory, ?root)`
  - Manually overrides the build directory for the current project. Does
    nothing if `directory` is nil. Does NOT check if the build directory exists.
    Optionally specify a project root for the given build directory, the
    existence of the root directory is not checked either.

## Contributing

Please feel free to submit any PRs or issues, especially if they add support for
more build systems. It would be great if we could support every build system
under the sun.

If anyone knows how these build systems work, that would be great, literally
just add the relevant entries from the `extra_indicators` and `extra_programs`
sections of your own configuration to
[lua/build/systems.lua](lua/build/systems.lua)

- build2
- Maven or Gradle or something java I don't know
- Bazel
- Better support for the different variations of Make (i.e. GNU make vs BSD
  make vs NMake etc)

