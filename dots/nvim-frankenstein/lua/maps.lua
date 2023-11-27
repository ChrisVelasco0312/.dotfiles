-- [[ Basic Keymaps ]]
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

--save
vim.keymap.set('n', '<Space>w', ':w!<Enter>', { silent = true })
--close
vim.keymap.set('n', '<Space>q', ':q!<Enter>', { silent = true })
vim.keymap.set('n', '<Space>x', ':wq!<Enter>', { silent = true })
--source
vim.keymap.set('n', '<Space>so', ':so<Enter>', { silent = true })

-- Toggle neckpain
vim.keymap.set('n', '<Space>np', ':NoNeckPain<Enter>', { silent = true })

--Primeagen's keymaps

-- Move selected line / block of text in visual modes
vim.keymap.set('v', 'J', ":m'>+1<CR>gv=gv", { silent = true, desc = 'move line down' })
vim.keymap.set('v', 'K', ":m'<-2<CR>gv=gv", { silent = true, desc = 'move line up' })
-- Move current line / block with Alt-j/k ala vscode.
vim.keymap.set('n', '<A-k>', ":m .-2<CR>==", { silent = true, desc = 'move line up' })
vim.keymap.set('n', '<A-j>', ":m .+1<CR>==", { silent = true, desc = 'move line down' })

-- Join line below to the current one and keep the cursor in place
vim.keymap.set('n', 'J', 'mzJ`z', { silent = true, desc = 'join line' })

-- Crtl d and u keeps the cursor in the middle of the screen
vim.keymap.set('n', '<C-d>', '<C-d>zz', { silent = true, desc = 'scroll down' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { silent = true, desc = 'scroll up' })

-- Keep search results centered
vim.keymap.set('n', 'n', 'nzzzv', { silent = true, desc = 'search next' })
vim.keymap.set('n', 'N', 'Nzzzv', { silent = true, desc = 'search previous' })

-- greatest remap ever
vim.keymap.set('x', "<Leader>p", "\"_dP", { silent = true, desc = 'paste over selection' })

-- Yank into system clipboard
vim.keymap.set('n', '<Leader>y', "\"+y", { silent = true, desc = 'yank to clipboard' })
vim.keymap.set('v', '<Leader>y', "\"+y", { silent = true, desc = 'yank to clipboard' })
vim.keymap.set('n', '<Leader>Y', "\"+Y", { silent = true, desc = 'yank to clipboard' })

-- deleting to void register
vim.keymap.set('n', '<Leader>d', "\"_d", { silent = true, desc = 'delete to void' })

-- Dont press capital Q
vim.keymap.set('n', 'Q', '<Nop>', { silent = true, desc = 'dont press capital Q' })

-- Tmux sessionizer
vim.keymap.set('n', '<Leader>ts', '<cmd>silent !tmux neww tmux-sessionizer<CR>',
  { silent = true, desc = 'tmux sessionizer' })

-- quick fixlist navigation
vim.keymap.set('n', '<Leader>qf', '<cmd>copen<CR>',
  { silent = true, desc = 'open quickfix' })
vim.keymap.set('n', '<Leader>qj', '<cmd>cnext<CR>',
  { silent = true, desc = 'next quickfix' })
vim.keymap.set('n', '<Leader>qk', '<cmd>cprev<CR>',
  { silent = true, desc = 'prev quickfix' })
vim.keymap.set('n', '<Leader>ql', '<cmd>cclose<CR>',
  { silent = true, desc = 'close quickfix' })

-- replace all occurences of word under cursor
vim.keymap.set("n", "<leader>z", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { silent = true, desc = 'replace word under cursor' })

-- Make bash script executable
vim.keymap.set('n', '<Leader>me', '<cmd>!chmod +x %<CR>', { silent = true, desc = 'make script executable' })

--if crtl + z is pressed dont do anything
vim.keymap.set('n', '<C-z>', '<Nop>', { silent = true, desc = 'dont do anything' })

-- <Leader>k to save every buffer and quit
vim.keymap.set('n', '<Leader>k', '<cmd>wa<CR>:qa<CR>', { silent = true, desc = 'save and quit' })
