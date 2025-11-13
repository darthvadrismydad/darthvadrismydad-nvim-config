-- Neovim from-scratch config (v2)
-- Adds: vtsls (TS), nvim-cmp completion, Telescope LSP mappings
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
vim.opt.smartindent = false

require('opts');

-----------------------------------------------------------
-- 1) Plugin manager: lazy.nvim bootstrap
-----------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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
        return builtin.find_files({ hidden = false })
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
        indent = { enable = false },
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

  -- Statusline with git info
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = { globalstatus = true },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
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
      local compare = require("cmp.config.compare")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      local function deprioritize_text(entry1, entry2)
        local text_kind = cmp.lsp.CompletionItemKind.Text
        local kind1 = entry1:get_kind()
        local kind2 = entry2:get_kind()
        if kind1 == text_kind and kind2 ~= text_kind then
          return false
        elseif kind2 == text_kind and kind1 ~= text_kind then
          return true
        end
      end

      local priority_kinds = {
        [cmp.lsp.CompletionItemKind.Field] = 0,
        [cmp.lsp.CompletionItemKind.Property] = 0,
        [cmp.lsp.CompletionItemKind.Method] = 0,
      }
      local function prioritize_fields_methods(entry1, entry2)
        local p1 = priority_kinds[entry1:get_kind()] or math.huge
        local p2 = priority_kinds[entry2:get_kind()] or math.huge
        if p1 ~= p2 then
          return p1 < p2
        end
      end

      local source_priority = {
        ["nvim_lsp:ts_ls"] = 0,
        ["nvim_lsp:tsserver"] = 0,
        ["nvim_lsp:typescript-language-server"] = 0,
        nvim_lsp = 1,
        path = 5,
        buffer = 10,
      }
      local function prefer_ts_sources(entry1, entry2)
        local function get_name(entry)
          if entry.source.get_debug_name then
            return entry.source:get_debug_name()
          end
          return entry.source.name
        end
        local p1 = source_priority[get_name(entry1)] or math.huge
        local p2 = source_priority[get_name(entry2)] or math.huge
        if p1 ~= p2 then
          return p1 < p2
        end
      end

      local ts_client_names = {
        tsserver = true,
        ts_ls = true,
        ["typescript-language-server"] = true,
      }
      local function filter_ts_text(entry, _)
        local source = entry.source and entry.source.source
        local client = source and source.client
        if client and ts_client_names[client.name] then
          if entry:get_kind() == cmp.lsp.CompletionItemKind.Text then
            return false
          end
        end
        return true
      end

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
        sources = cmp.config.sources({
          { name = "nvim_lsp", entry_filter = filter_ts_text },
          { name = "path" },
        }, {
          { name = "buffer", keyword_length = 3 },
        }),
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = function(entry, vim_item)
            local debug_name = entry.source.get_debug_name and entry.source:get_debug_name() or entry.source.name
            vim_item.menu = string.format("[%s]", debug_name)
            return vim_item
          end,
        },
        sorting = {
          comparators = {
            prefer_ts_sources,
            prioritize_fields_methods,
            deprioritize_text,
            compare.offset,
            compare.exact,
            compare.score,
            compare.recently_used,
            compare.locality,
            compare.kind,
            compare.length,
            compare.order,
          },
        },
      })
    end,
  },

  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { { "nvim-lua/plenary.nvim" } }
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
mason_lsp.setup({ ensure_installed = { "lua_ls", "ts_ls" } })

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
  map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev diagnostic")
  map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")

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

vim.lsp.config("ts_ls", {
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
    vim.lsp.enable("ts_ls")
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

local harpoon = require("harpoon")

-- Harpoon!
harpoon:setup()

map("n", "<leader>a", function() harpoon:list():add() end)
map("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
map("n", "<C-h>", function() harpoon:list():select(1) end)
map("n", "<C-t>", function() harpoon:list():select(2) end)
map("n", "<C-n>", function() harpoon:list():select(3) end)
map("n", "<C-s>", function() harpoon:list():select(4) end)

-- Toggle previous & next buffers stored within Harpoon list
map("n", "<C-S-P>", function() harpoon:list():prev() end)
map("n", "<C-S-N>", function() harpoon:list():next() end)

-- basic telescope configuration
local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
  local file_paths = {}
  for _, item in ipairs(harpoon_files.items) do
    table.insert(file_paths, item.value)
  end

  require("telescope.pickers").new({}, {
    prompt_title = "Harpoon",
    finder = require("telescope.finders").new_table({
      results = file_paths,
    }),
    previewer = conf.file_previewer({}),
    sorter = conf.generic_sorter({}),
  }):find()
end

map("n", "<C-e>", function() toggle_telescope(harpoon:list()) end,
  { desc = "Open harpoon window" })
