--[[ keys.lua ]]
local map = vim.api.nvim_set_keymap

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

vim.keymap.set("n", "<leader>p", "\"_dp")

vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv'")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv'")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("i", "kk", "<C-c>")
vim.keymap.set("v", "kk", "<C-c>")

vim.keymap.set("n", "<C-a>", "g0ggvGy")
vim.keymap.set("n", "<C-A>", "g0ggvG\"*y")
