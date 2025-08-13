if vim.g.current_compiler ~= nil then
	return
end
vim.g.current_compiler = "cmake"

vim.cmd.CompilerSet("makeprg=cmake\\ $*")
