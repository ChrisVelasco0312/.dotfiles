require('trouble').setup {}

vim.keymap.set("n", "<Leader>ld", function() require("trouble").toggle("diagnostics") end)
vim.api.nvim_set_keymap('n', '<leader>td', '<cmd>TroubleToggle todo<CR>',
  { noremap = true, silent = true, desc = '[T]rouble To[D]o' })
