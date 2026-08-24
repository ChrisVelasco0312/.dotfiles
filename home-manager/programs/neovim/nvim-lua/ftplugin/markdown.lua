-- Toggle text wrapping for the current window.
-- When wrap is on, set a max line width guide (colorcolumn) so text
-- stays readable on wide screens.
local wrap_limit = 80

vim.keymap.set('n', ';mw', function()
  vim.wo.wrap = not vim.wo.wrap
  if vim.wo.wrap then
    vim.wo.colorcolumn = tostring(wrap_limit)
    vim.notify('Wrap enabled (max width ' .. wrap_limit .. ')')
  else
    vim.wo.colorcolumn = ''
    vim.notify('Wrap disabled')
  end
end, { buffer = true, silent = true, desc = 'toggle text wrapping' })
