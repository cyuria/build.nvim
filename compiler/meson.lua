if vim.g.current_compiler ~= nil then
	return
end
vim.g.current_compiler = "meson"

vim.cmd.CompilerSet("makeprg=meson\\ $*")
