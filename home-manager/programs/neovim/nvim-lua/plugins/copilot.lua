vim.g.copilot_enabled = 0;
vim.keymap.set('n', ';cc', ':Copilot enable<ENTER>', { silent = true, desc = 'Copilot Enable' })
vim.keymap.set('n', ';cd', ':Copilot disable<ENTER>', {
  silent = true, desc = 'Copilot Disable'
})
