require("writer.wsl")
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

require("writer.options")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local result = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Could not install lazy.nvim:\n", "ErrorMsg" },
      { result, "WarningMsg" },
    }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(require("writer.plugins"), {
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  install = { missing = true },
  ui = { border = "rounded" },
  rocks = { enabled = false },
})

require("writer.keymaps")
require("writer.autocmds")
require("writer.theme").setup()

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  callback = function()
    require("writer.theme").setup()
  end,
})
