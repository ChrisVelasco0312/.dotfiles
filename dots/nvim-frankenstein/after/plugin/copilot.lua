vim.keymap.set('n', ';ce', ':Copilot enable<ENTER>', { silent = true, desc = 'Copilot Enable' })
vim.keymap.set('n', ';cd', ':Copilot disable<ENTER>', { silent = true, desc = 'Copilot Disable' })
vim.keymap.set('n', ';ci', ':Copilot<ENTER>', { silent = true, desc = 'Copilot suggestions' })
vim.keymap.set('i', '<C-,>', 'copilot#Accept("<CR>")', { expr = true, silent = true, desc = 'Accept Copilot suggestion' })
