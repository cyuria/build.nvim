if vim.g.current_compiler ~= nil then
	return
end
vim.g.current_compiler = "build_sh"

if vim.g.build_system_file == nil then
	vim.cmd.CompilerSet("makeprg=./build.sh\\ $*")
else
	local f = vim.g.build_system_file
	f = string.gsub(f, ' ', '\\ ')
	vim.cmd.CompilerSet("makeprg=" .. f .. "\\ $*")
end
