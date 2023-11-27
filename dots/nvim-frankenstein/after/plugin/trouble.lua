local trouble = require('trouble')

trouble.setup {
  icons = false,
  mode = 'lsp_hover_diagnostics'
}

vim.api.nvim_set_keymap('n', '<leader>ld', '<cmd>TroubleToggle workspace_diagnostics<CR>',
  { noremap = true, silent = true })
