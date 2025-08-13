if vim.g.current_compiler ~= nil then
	return
end
vim.g.current_compiler = "ninja"

vim.cmd.CompilerSet("makeprg=ninja\\ $*")
