local status, saga = pcall(require, "lspsaga")
if (not status) then return end

saga.setup({
  ui = {
    winblend = 10,
    border = 'rounded',
    colors = {
      normal_bg = '#002b36'
    }
  },
  symbol_in_winbar = {
    enable = false
  },
  server_filetype_map = {
    typescript = 'typescript',
  }
})

vim.keymap.set('n', '<C-j>', '<Cmd>Lspsaga diagnostic_jump_next<CR>',
  { noremap = true, silent = true, desc = '[saga] go to next diagnostic message' })
vim.keymap.set('n', 'gF', '<Cmd>Lspsaga finder<CR>', {
  noremap = true, silent = true, desc = '[saga] finder'
})
vim.keymap.set('n', 'gl', '<Cmd>Lspsaga show_line_diagnostics<CR>', {
  noremap = true, silent = true, desc = '[saga] show line diagnostic'
})
vim.keymap.set('n', 'K', '<Cmd>Lspsaga hover_doc<CR>', {
  noremap = true, silent = true, desc = '[saga] show documentation for symbol'
})
vim.keymap.set('n', '<Leader>K', '<cmd>lua vim.lsp.buf.signature_help()<CR>', {
  noremap = true, silent = true, desc = '[saga] show signature help'
})
vim.keymap.set('n', 'gp', '<Cmd>Lspsaga peek_definition<CR>', {
  noremap = true, silent = true, desc = '[saga] peek definition'
})
vim.keymap.set('n', 'gr', '<Cmd>Lspsaga rename<CR>', {
  noremap = true, silent = true, desc = '[saga] rename symbol' })


-- go to definition
vim.keymap.set('n', 'gd', '<Cmd>Lspsaga goto_definition<CR>', {
  noremap = true, silent = true, desc = '[saga] go to definition'
})
-- go to type definition
vim.keymap.set('n', 'gt', '<Cmd>Lspsaga goto_type_definition<CR>', {
  noremap = true, silent = true, desc = '[saga] go to type definition'
})
-- hover docs
vim.keymap.set('n', 'K', '<Cmd>Lspsaga hover_doc<CR>', {
  noremap = true, silent = true, desc = '[saga] show documentation for symbol'
})
--toggle outline
vim.keymap.set('n', 'ln', '<Cmd>Lspsaga outline<CR>', {
  noremap = true, silent = true, desc = '[saga] toggle outline'
})

-- code action
vim.keymap.set({ "n", "v" }, ";ca", "<cmd>Lspsaga code_action<CR>", {
  desc = "[saga] run code actions"
})
