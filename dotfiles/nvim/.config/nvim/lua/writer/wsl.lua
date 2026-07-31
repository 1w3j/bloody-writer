-- Windows/WSL-specific integration.
if vim.fn.has("wsl") ~= 1 then
  return
end

local copy_command = { "clip.exe" }
local paste_command = {
  "powershell.exe",
  "-NoLogo",
  "-NoProfile",
  "-Command",
  "[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; Get-Clipboard -Raw",
}

vim.g.clipboard = {
  name = "Windows clipboard through WSL",
  copy = {
    ["+"] = copy_command,
    ["*"] = copy_command,
  },
  paste = {
    ["+"] = paste_command,
    ["*"] = paste_command,
  },
  cache_enabled = 0,
}

vim.opt.clipboard = "unnamedplus"

-- Windows-style copying.
vim.keymap.set("n", "<C-c>", '"+yy', {
  silent = true,
  desc = "Copy current line to Windows",
})

vim.keymap.set("x", "<C-c>", '"+y', {
  silent = true,
  desc = "Copy selection to Windows",
})

-- Windows-style pasting.
vim.keymap.set("n", "<C-v>", '"+p', {
  silent = true,
  desc = "Paste from Windows",
})

vim.keymap.set("x", "<C-v>", '"+P', {
  silent = true,
  desc = "Replace selection from Windows",
})

vim.keymap.set("i", "<C-v>", "<C-r>+", {
  silent = true,
  desc = "Paste from Windows",
})

vim.keymap.set("c", "<C-v>", "<C-r>+", {
  silent = true,
  desc = "Paste from Windows",
})

-- Preserve Visual Block mode.
vim.keymap.set({ "n", "x" }, "<C-q>", "<C-v>", {
  silent = true,
  desc = "Visual Block mode",
})
