vim.o.mouse = 'a'
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
vim.o.foldmethod = 'indent' -- Use indentation for folding

local ufo = require('ufo');
-- Set fold options

-- Define keybindings for folding
vim.api.nvim_set_keymap('n', 'za', 'za', { noremap = true, silent = true, desc = "Toggle fold under the cursor" })
vim.api.nvim_set_keymap('n', 'zc', 'zc', { noremap = true, silent = true, desc = "Close fold under the cursor" })
vim.api.nvim_set_keymap('n', 'zo', 'zo', { noremap = true, silent = true, desc = "Open fold under the cursor" })
vim.keymap.set('n', 'zR', ufo.openAllFolds, { noremap = true, silent = true, desc = "Open all folds" })
vim.keymap.set('n', 'zM', ufo.closeAllFolds, { noremap = true, silent = true, desc = "Close all folds" })


local handler = function(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = ('  %d '):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      -- str width returned from truncate() may less than 2nd argument, need padding
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  table.insert(newVirtText, { suffix, 'MoreMsg' })
  return newVirtText
end

-- Option 3: treesitter as a main provider instead
-- Only depend on `nvim-treesitter/queries/filetype/folds.scm`,
-- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`
require('ufo').setup({
  fold_virt_text_handler = handler,
})


-- Custom statscolumn
local fcs = vim.opt.fillchars:get()

-- Stolen from Akinsho
local function get_fold(lnum)
  if vim.fn.foldlevel(lnum) <= vim.fn.foldlevel(lnum - 1) then return ' ' end
  local fold_sym = vim.fn.foldclosed(lnum) == -1 and fcs.foldopen or fcs.foldclose
  return fold_sym
end

_G.get_statuscol = function()
  return "%s%l " .. get_fold(vim.v.lnum) .. " "
end


vim.o.statuscolumn = "%!v:lua.get_statuscol()"

vim.g["conjure#mapping#doc_word"] = { "L" }

vim.keymap.set('n', 'K', function()
  local winid = require('ufo').peekFoldedLinesUnderCursor()
  if not winid then
    vim.lsp.buf.hover()
  end
end)
