if vim.g.current_compiler ~= nil then
	return
end
vim.g.current_compiler = "cmake"

if vim.g.build_system_file == nil then
	vim.cmd.CompilerSet("makeprg=cmake\\ $*")
else
	local d = vim.g.build_system_file
	d = vim.fs.dirname(d)
	d = string.gsub(d, ' ', '\\ ')
	vim.cmd.CompilerSet("makeprg=cmake\\ -S\\ '" .. d .. "' $*")
end
