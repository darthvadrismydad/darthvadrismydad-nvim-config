-- Neovim from-scratch config
-- Features: LSP (Lua & TypeScript), Telescope, Git signs, dark theme (tokyonight)
-- Drop this file at: ~/.config/nvim/init.lua

-----------------------------------------------------------
-- 0) Leader and basic settings
-----------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = ","

vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400
vim.opt.clipboard = "unnamedplus"

-----------------------------------------------------------
-- 1) Plugin manager: lazy.nvim bootstrap
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-----------------------------------------------------------
-- 2) Plugins
-----------------------------------------------------------
require("lazy").setup({
  -- Colorscheme
  { "folke/tokyonight.nvim", lazy = false, priority = 1000 },

  -- Utilities
  { "nvim-lua/plenary.nvim" },

  -- Telescope (fuzzy finder)
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = function()
          local has_make = (vim.fn.executable("make") == 1)
          if has_make then
            vim.cmd([[silent! !make]])
          end
        end,
      },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          mappings = {
            i = { ["<C-u>"] = false, ["<C-d>"] = false },
          },
        },
      })
      pcall(telescope.load_extension, "fzf")

      local builtin = require("telescope.builtin")
      local map = vim.keymap.set
      map("n", "<leader>ff", builtin.find_files, { desc = "Telescope: find files" })
      map("n", "<leader>fg", builtin.live_grep,  { desc = "Telescope: live grep" })
      map("n", "<leader>fb", builtin.buffers,    { desc = "Telescope: buffers" })
      map("n", "<leader>fh", builtin.help_tags,  { desc = "Telescope: help tags" })
      map("n", "<leader>fs", builtin.grep_string,{ desc = "Telescope: word under cursor" })
      map("n", "<leader>fr", builtin.resume,     { desc = "Telescope: resume" })
    end,
  },

  -- Treesitter (better syntax highlighting)
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      pcall(require("nvim-treesitter.install").update({ with_sync = true }))
    end,
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "javascript", "typescript", "tsx",
          "json", "html", "css", "bash", "markdown", "markdown_inline"
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Git integration (inline hunks, blame, etc.)
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local map = function(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
          end
          map("n", "]h", gs.next_hunk, "Next hunk")
          map("n", "[h", gs.prev_hunk, "Prev hunk")
          map({"n","v"}, "<leader>hs", gs.stage_hunk, "Stage hunk")
          map({"n","v"}, "<leader>hr", gs.reset_hunk, "Reset hunk")
          map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
          map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
          map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
          map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
          map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
        end,
      })
    end,
  },

  -- LSP & tooling
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", config = true },
  { "williamboman/mason-lspconfig.nvim" },

  -- Optional: nice LSP UI (floating windows, code actions)
  { "folke/trouble.nvim", dependencies = { "nvim-tree/nvim-web-devicons" }, opts = {} },
}, {
  ui = { border = "rounded" },
})

-----------------------------------------------------------
-- 3) Colorscheme
-----------------------------------------------------------
vim.cmd.colorscheme("tokyonight-night")

-----------------------------------------------------------
-- 4) LSP setup (Lua & TypeScript) using new API (Nvim 0.11+)
-----------------------------------------------------------
-- NOTE: The legacy `require('lspconfig')` setup() framework is deprecated on Nvim 0.11+.
-- Use the core API: vim.lsp.config() + vim.lsp.enable().
-- Docs: :help lspconfig-nvim-0.11 and :help lsp

local mason_lsp = require("mason-lspconfig")

-- Ensure servers are installed via mason (installer only)
mason_lsp.setup({ ensure_installed = { "lua_ls", "tsserver" } })

-- Diagnostic UX
vim.diagnostic.config({
  float = { border = "rounded" },
  severity_sort = true,
  update_in_insert = false,
})

local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- on_attach sets buffer-local keymaps after a server attaches
local on_attach = function(_, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- Core LSP mappings
  map("n", "K", vim.lsp.buf.hover, "LSP: hover docs")
  map("n", "gd", vim.lsp.buf.definition, "LSP: goto definition")
  map("n", "gD", vim.lsp.buf.declaration, "LSP: goto declaration")
  map("n", "gi", vim.lsp.buf.implementation, "LSP: goto impl")
  map("n", "gr", vim.lsp.buf.references, "LSP: references")
  map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: rename symbol")
  map({"n","v"}, "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
  map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "LSP: format")

  -- Diagnostics
  map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
  map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
  map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")

  -- Trouble toggles (optional)
  map("n", "<leader>xx", require("trouble").toggle, "Trouble: toggle")
  map("n", "<leader>xd", function() require("trouble").toggle("document_diagnostics") end, "Trouble: document diags")
  map("n", "<leader>xw", function() require("trouble").toggle("workspace_diagnostics") end, "Trouble: workspace diags")
end

-- Define configs with the new API
vim.lsp.config("lua_ls", {
  on_attach = on_attach,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.config("tsserver", {
  on_attach = on_attach,
  -- Add per-server settings here if needed
})

-- Enable servers (autostarts on matching filetypes, and attaches to open buffers)
vim.lsp.enable("lua_ls")
vim.lsp.enable("tsserver")

-----------------------------------------------------------
-- 5) Convenience general keymaps
-----------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>qq", ":qa<CR>", { desc = "Quit all" })
map("n", "<leader>ww", ":w<CR>",  { desc = "Write buffer" })
map("n", "<leader>pv", ":Ex<CR>", { desc = "Open netrw Ex" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostics for line" })

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-----------------------------------------------------------
-- 6) Final polish
-----------------------------------------------------------
-- Highlight on yank
local yank_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = yank_group,
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

-- Show which-key style hints if you later add that plugin (placeholder)
-- This config keeps things lean; you can layer cmp, which-key, etc., later.
