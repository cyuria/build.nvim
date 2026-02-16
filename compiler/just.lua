if vim.g.current_compiler ~= nil then
	return
end
vim.g.current_compiler = "just"

vim.cmd.CompilerSet("makeprg=just\\ $*")
