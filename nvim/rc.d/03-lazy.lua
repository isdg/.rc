-- lazy.nvim and the plugins are installed by .rcboot's nvim module. Without
-- them nvim starts plain: a config loads plugins, it does not fetch them.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    return
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({ { import = "plugins" } })
