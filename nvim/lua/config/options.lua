-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
vim.opt.wrap = true
-- windsurf.vim은 system('uname -m')으로 아키텍처를 판별하는데, shell이 nu면 nu 내장 uname이
-- 불려서 실패한다. 셸을 거치지 않는 libuv 값으로 직접 넘긴다.
local uname = vim.uv.os_uname()
vim.g.codeium_os = uname.sysname
vim.g.codeium_arch = uname.machine
