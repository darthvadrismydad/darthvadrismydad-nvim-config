local lsp = require('lsp-zero')

lsp.preset("recommended")

lsp.ensure_installed({
    'tsserver',
    'eslint'
})

local cmp = require('cmp')
local cmp_select = {behavior = cmp.SelectBehavior.Select}
local cmp_mappings = lsp.defaults.cmp_mappings({
    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ["<C-J>"] = cmp.mapping.complete(),
})

lsp.set_preferences({
    sign_icons = { }
})

lsp.on_attach(function(client, bufnr)
  lsp.default_keymaps({buffer = bufnr})
  lsp.buffer_autoformat()
end)

lsp.format_on_save({
  servers = {
    ['lua_ls'] = {'lua'},
    ['tsserver'] = {'js', 'ts', 'tsx', 'jsx'}
  }
})

lsp.setup()
