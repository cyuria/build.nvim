if vim.g.current_compiler ~= nil then
	return
end
vim.g.current_compiler = "npm"

vim.cmd.CompilerSet("makeprg=npm\\ run\\ $*")
