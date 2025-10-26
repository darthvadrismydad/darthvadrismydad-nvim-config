-- Neovim from-scratch config (v2)
-- Adds: vtsls (TS), ESLint on save, nvim-cmp completion, Telescope LSP mappings
-- Drop at: ~/.config/nvim/init.lua

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

require('opts');

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
                    if vim.fn.executable("make") == 1 then
                        vim.cmd([[silent! !make]])
                    end
                end,
            },
        },
        config = function()
            local telescope = require("telescope")
            local builtin = require("telescope.builtin")
            telescope.setup({
                defaults = {
                    mappings = {
                        i = { ["<C-u>"] = false, ["<C-d>"] = false },
                    },
                },
            })
            pcall(telescope.load_extension, "fzf")

            -- General Telescope keymaps
            local map = vim.keymap.set
            map("n", "<leader>sf", function()
                return builtin.find_files({ hidden = true })
            end, { desc = "Telescope: find files" })
            map("n", "<leader>sg", builtin.live_grep, { desc = "Telescope: live grep" })
            map("n", "<leader>sb", builtin.buffers, { desc = "Telescope: buffers" })
            map("n", "<leader>sh", builtin.help_tags, { desc = "Telescope: help tags" })
            map("n", "<leader>sa", builtin.grep_string, { desc = "Telescope: word under cursor" })
            map("n", "<leader>sr", builtin.resume, { desc = "Telescope: resume" })

            -- LSP-flavored Telescope
            map("n", "<leader>sd", builtin.lsp_definitions, { desc = "Telescope: LSP definitions" })
            map("n", "<leader>sr", builtin.lsp_references, { desc = "Telescope: LSP references" })
            map("n", "<leader>ss", builtin.lsp_document_symbols, { desc = "Telescope: document symbols" })
            map("n", "<leader>sS", builtin.lsp_workspace_symbols, { desc = "Telescope: workspace symbols" })
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
                    map({ "n", "v" }, "<leader>hs", gs.stage_hunk, "Stage hunk")
                    map({ "n", "v" }, "<leader>hr", gs.reset_hunk, "Reset hunk")
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
    { "williamboman/mason.nvim",          config = true },
    { "williamboman/mason-lspconfig.nvim" },

    -- Completion (nvim-cmp + sources + snippets)
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "saadparwaiz1/cmp_luasnip",
            "L3MON4D3/LuaSnip",
            "rafamadriz/friendly-snippets",
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({ { name = "nvim_lsp" }, { name = "path" } }, { { name = "buffer" } }),
            })
        end,
    },

    -- ESLint helper (provides :EslintFixAll)
    {
        "MunifTanjim/eslint.nvim",
        config = function()
            require("eslint").setup({
                -- you can pass opts here if needed
            })
        end,
    },

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
-- 4) LSP setup (Lua, TypeScript) using new API (Nvim 0.11+)
-----------------------------------------------------------
-- NOTE: Use core vim.lsp.config/enable instead of legacy lspconfig setup framework
local mason_lsp = require("mason-lspconfig")

-- Ensure language servers installed via Mason
mason_lsp.setup({ ensure_installed = { "lua_ls", "vtsls", "eslint" } })

-- Diagnostic UX
vim.diagnostic.config({ float = { border = "rounded" }, severity_sort = true, update_in_insert = false })
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- Completion capabilities advertised to LSP
local cmp_caps_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
local capabilities = vim.lsp.protocol.make_client_capabilities()
if cmp_caps_ok then capabilities = cmp_nvim_lsp.default_capabilities(capabilities) end

-- on_attach: LSP keymaps + peek definition
local on_attach = function(_, bufnr)
    local map = function(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc }) end

    -- Core LSP mappings
    map("n", "K", vim.lsp.buf.hover, "LSP: hover docs")
    map("n", "gd", vim.lsp.buf.definition, "LSP: goto definition")
    map("n", "gD", vim.lsp.buf.declaration, "LSP: goto declaration")
    map("n", "gi", vim.lsp.buf.implementation, "LSP: goto impl")
    map("n", "gr", vim.lsp.buf.references, "LSP: references")
    map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: rename symbol")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
    map("n", "<leader>ff", function() vim.lsp.buf.format({ async = true }) end, "LSP: format")

    -- Diagnostics
    map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
    map("n", "[d", vim.diagnostic.jump({ count = -1, float = true }), "Prev diagnostic")
    map("n", "]d", vim.diagnostic.jump({ count = 1, float = true }), "Next diagnostic")

    -- Peek definition
    local function peek_definition()
        local params = vim.lsp.util.make_position_params(0, 'utf-8')
        vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
            if err or not result or vim.tbl_isempty(result) then
                vim.notify("No definition found", vim.log.levels.INFO)
                return
            end
            local location = (vim.islist(result) and result[1]) or result
            vim.lsp.util.preview_location(location)
        end)
    end
    map("n", "<leader>pd", peek_definition, "LSP: peek definition")
end

-- Server configurations
vim.lsp.config("lua_ls", {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
            telemetry = { enable = false },
        },
    },
})

vim.lsp.config("vtsls", {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        typescript = {
            inlayHints = { parameterNames = { enabled = "literals" } },
            preferences = { includePackageJsonAutoImports = "on" },
        },
        javascript = {
            inlayHints = { parameterNames = { enabled = "literals" } },
        },
    },
})

vim.lsp.config("eslint", {
    on_attach = on_attach,
    capabilities = capabilities,
})

-- Filetype-based enabling (lazy attach)
local ft_enable = vim.api.nvim_create_augroup("LspEnableByFiletype", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = ft_enable,
    pattern = { "lua" },
    callback = function() vim.lsp.enable("lua_ls") end,
})
vim.api.nvim_create_autocmd("FileType", {
    group = ft_enable,
    pattern = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    callback = function()
        vim.lsp.enable("vtsls")
        vim.lsp.enable("eslint")
    end,
})

-- ESLint on save (uses eslint.nvim's :EslintFixAll then format via LSP)
local eslint_group = vim.api.nvim_create_augroup("EslintOnSave", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
    group = eslint_group,
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
    callback = function()
        -- Apply ESLint fixes if available
        if vim.fn.exists(":EslintFixAll") == 2 then
            vim.cmd("silent! EslintFixAll")
        end
        -- Then format via LSP if a server offers it
        pcall(vim.lsp.buf.format, { async = false })
    end,
})

-----------------------------------------------------------
-- 5) Convenience general keymaps
-----------------------------------------------------------
local map = vim.keymap.set
map("n", "<leader>pv", ":Ex<CR>", { desc = "Open netrw Ex" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostics for line" })
map("n", "<leader>qq", ":qa<CR>", { desc = "Quit all" })
map("n", "<leader>ww", ":w<CR>", { desc = "Write buffer" })

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
    callback = function() vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 }) end,
})
