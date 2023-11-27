local status, null_ls = pcall(require, "null-ls")
local builtins = null_ls.builtins
if (not status) then return end

-- local group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false })
-- local event = "BufWritePre" -- or "BufWritePost"
-- local async = event == "BufWritePost"
--

local sources = {
  builtins.diagnostics.eslint.with({
    diagnostics_format = '[eslint] #{m}\n(#{c})'
  }),
  builtins.diagnostics.fish,
  builtins.formatting.prettierd.with({
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "css", "scss", "json", "yaml",
      "markdown", "html", "vue" },
  }),

}

local on_attach = function(client, bufnr)
  if client.supports_method("textDocument/formatting") then
    vim.keymap.set("n", "<Leader>f", function()
      vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
    end, { buffer = bufnr, desc = "[lsp] format" })
  end

  if client.supports_method("textDocument/rangeFormatting") then
    vim.keymap.set("x", "<Leader>f", function()
      vim.lsp.buf.format({ bufnr = vim.api.nvim_get_current_buf() })
    end, { buffer = bufnr, desc = "[lsp] format" })
  end
end

null_ls.setup({
  debug = true,
  on_attach = on_attach,
  sources = sources,
})
