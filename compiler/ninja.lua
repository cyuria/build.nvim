if vim.g.current_compiler ~= nil then
	return
end
vim.g.current_compiler = "ninja"

if vim.g.build_system_file == nil then
	vim.cmd.CompilerSet("makeprg=ninja\\ $*")
else
	local d = vim.g.build_system_file
	d = vim.fs.dirname(d)
	d = string.gsub(d, ' ', '\\ ')
	local b = vim.g.build_system_file
	b = vim.fs.basename(b)
	b = string.gsub(b, ' ', '\\ ')
	vim.cmd.CompilerSet("makeprg=ninja\\ -C\\ '" .. d .. "'\\ -f\\ '" .. b .. "'\\ $*")
end
