if vim.g.current_compiler ~= nil then
	return
end
vim.g.current_compiler = "setuptools"

vim.cmd.CompilerSet("makeprg=python\\ setup.py\\ build\\ $*")
