vim.keymap.set('n', ';mp', function()
  if vim.bo.filetype == 'markdown' then 
    vim.cmd('MarkdownPreviewToggle') 
  else
    vim.notify('MarkdownPreview: Not a Markdown file', vim.log.levels.WARN) 
  end
end, { noremap = true, silent = true, desc = 'Toggle Markdown Preview' })
