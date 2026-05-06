local status, cmp = pcall(require, "cmp")
if (not status) then return end
local lspkind = require 'lspkind'
local luasnip = require 'luasnip'

-- cmp-buffer still uses deprecated vim.validate({ ... }) on some package versions.
-- Patch its options validator to the new vim.validate(...) form.
local cmp_buffer_status, cmp_buffer_source = pcall(require, "cmp_buffer.source")
if cmp_buffer_status then
  local cmp_buffer_defaults = {
    keyword_length = 3,
    keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\%(\w\|á\|Á\|é\|É\|í\|Í\|ó\|Ó\|ú\|Ú\)*\%(-\%(\w\|á\|Á\|é\|É\|í\|Í\|ó\|Ó\|ú\|Ú\)*\)*\)]],
    get_bufnrs = function()
      return { vim.api.nvim_get_current_buf() }
    end,
    indexing_batch_size = 1000,
    indexing_interval = 100,
    max_indexed_line_length = 1024 * 40,
  }

  cmp_buffer_source._validate_options = function(_, params)
    local opts = vim.tbl_deep_extend("keep", params.option or {}, cmp_buffer_defaults)
    vim.validate("keyword_length", opts.keyword_length, "number")
    vim.validate("keyword_pattern", opts.keyword_pattern, "string")
    vim.validate("get_bufnrs", opts.get_bufnrs, "function")
    vim.validate("indexing_batch_size", opts.indexing_batch_size, "number")
    vim.validate("indexing_interval", opts.indexing_interval, "number")
    return opts
  end
end


cmp.setup({
  enabled = function()
    local ft = vim.api.nvim_buf_get_option(0, "filetype")
    return ft ~= "oil"
  end,
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = true
    }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'codeium' },
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    {
      name = 'nvim_lsp',
        option = {
          markdown_oxide = {
            keyword_pattern = [[\(\k\| \|\/\|#\)\+]]
          }
        }
    },
  }),
  formatting = {
    format = lspkind.cmp_format({ maxwidth = 50, symbol_map = { Codeium = "" } })
  }
})

vim.cmd [[
  set completeopt=menuone,noinsert,noselect
  highlight! default link CmpItemKind CmpItemMenuDefault
]]
