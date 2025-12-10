-- =============================================================================
-- LSP Configuration using Neovim 0.11+ native API (vim.lsp.config)
-- =============================================================================

local augroup_format = vim.api.nvim_create_augroup("Format", { clear = true })

-- Global variable to track format on save state
vim.g.format_on_save_enabled = false

local enable_format_on_save = function(bufnr)
  if not vim.g.format_on_save_enabled then
    return
  end

  vim.api.nvim_clear_autocmds({ group = augroup_format, buffer = bufnr })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup_format,
    buffer = bufnr,
    callback = function()
      vim.lsp.buf.format({ bufnr = bufnr })
    end,
  })
end

local disable_format_on_save = function(bufnr)
  vim.api.nvim_clear_autocmds({ group = augroup_format, buffer = bufnr })
end

-- Create global command to toggle format on save
vim.api.nvim_create_user_command('FormatOnSaveToggle', function()
  vim.g.format_on_save_enabled = not vim.g.format_on_save_enabled
  local bufnr = vim.api.nvim_get_current_buf()

  if vim.g.format_on_save_enabled then
    enable_format_on_save(bufnr)
    vim.notify('Format on save enabled', vim.log.levels.INFO)
  else
    disable_format_on_save(bufnr)
    vim.notify('Format on save disabled', vim.log.levels.INFO)
  end
end, { desc = 'Toggle format on save for current buffer' })

-- =============================================================================
-- Global LspAttach autocmd (replaces per-server on_attach)
-- =============================================================================
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', { clear = true }),
  callback = function(ev)
    local bufnr = ev.buf

    local nmap = function(keys, func, desc)
      if desc then
        desc = 'LSP: ' .. desc
      end
      vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
    nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
    nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    nmap('<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
      vim.lsp.buf.format()
    end, { desc = 'Format current buffer with LSP' })

    -- Only enable format on save if it's globally enabled
    if vim.g.format_on_save_enabled then
      enable_format_on_save(bufnr)
    end
  end,
})

-- =============================================================================
-- Capabilities (for autocompletion via nvim-cmp)
-- =============================================================================
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- =============================================================================
-- Diagnostic configuration
-- =============================================================================
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics,
  {
    virtual_text = false,
    signs = true,
    update_in_insert = false,
    underline = true,
  }
)

-- =============================================================================
-- LSP Server Configurations using vim.lsp.config()
-- =============================================================================

-- Setup neodev before lua_ls
require('neodev').setup()

-- Lua Language Server
vim.lsp.config('lua_ls', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  capabilities = capabilities,
  settings = {
    Lua = {
      format = { enable = true },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = { enable = false },
      diagnostics = {
        globals = { 'vim' }
      }
    },
  }
})

-- TypeScript/JavaScript Language Server
vim.lsp.config('ts_ls', {
  cmd = { 'typescript-language-server', '--stdio' },
  filetypes = { 'typescript', 'typescriptreact', 'typescript.tsx', 'javascript', 'javascriptreact' },
  root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  capabilities = capabilities,
})

-- ESLint
vim.lsp.config('eslint', {
  cmd = { 'vscode-eslint-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { '.eslintrc', '.eslintrc.js', '.eslintrc.json', 'package.json', '.git' },
  capabilities = capabilities,
})

-- Python LSP
vim.lsp.config('pylsp', {
  cmd = { 'pylsp' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
  capabilities = capabilities,
  settings = {
    pylsp = {
      flags = {
        debounce_text_changes = 300,
      },
      plugins = {
        pycodestyle = { enabled = false },
        flake8 = { enabled = false },
        ruff = { enabled = true },
        mypy = { enabled = true },
        black = { enabled = true },
        isort = { enabled = true },
        rope_autoimport = { enabled = true },
        rope_completion = { enabled = true },
      },
    }
  }
})

-- Markdown Oxide
vim.lsp.config('markdown_oxide', {
  cmd = { 'markdown-oxide' },
  filetypes = { 'markdown' },
  root_markers = { '.git', '.obsidian' },
  capabilities = vim.tbl_deep_extend(
    'force',
    capabilities,
    {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    }
  ),
})

-- Java (jdtls)
vim.lsp.config('jdtls', {
  cmd = { 'jdtls' },
  filetypes = { 'java' },
  root_markers = { 'pom.xml', 'build.gradle', '.git' },
  capabilities = capabilities,
})

-- Emmet
vim.lsp.config('emmet_ls', {
  cmd = { 'emmet-ls', '--stdio' },
  filetypes = { 'html', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'less' },
  root_markers = { '.git' },
  capabilities = capabilities,
  init_options = {
    html = {
      options = {
        ["bem.enabled"] = true,
      },
    },
    jsx = {
      options = {
        ["jsx.enabled"] = true,
        ["markup.attributes"] = {
          ["class"] = "className",
          ["for"] = "htmlFor",
          ["tabindex"] = "tabIndex",
        },
      }
    },
  }
})

-- Nix (nixd)
vim.lsp.config('nixd', {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
  capabilities = capabilities,
  settings = {
    nixd = {
      formatting = {
        command = { 'nixpkgs-fmt' }
      },
    }
  }
})

-- =============================================================================
-- Enable all LSP servers
-- =============================================================================
vim.lsp.enable({
  'lua_ls',
  'ts_ls',
  'eslint',
  'pylsp',
  'markdown_oxide',
  'jdtls',
  'emmet_ls',
  'nixd',
})

-- =============================================================================
-- Diagnostic float on cursor hold
-- =============================================================================
function OpenDiagnosticIfNoFloat()
  for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(winid).zindex then
      return
    end
  end
  vim.diagnostic.open_float(0, {
    scope = "cursor",
    focusable = false,
    close_events = {
      "CursorMoved",
      "CursorMovedI",
      "BufHidden",
      "InsertCharPre",
      "WinLeave",
    },
  })
end

vim.api.nvim_create_augroup("lsp_diagnostics_hold", { clear = true })
vim.api.nvim_create_autocmd({ "CursorHold" }, {
  pattern = "*",
  command = "lua OpenDiagnosticIfNoFloat()",
  group = "lsp_diagnostics_hold",
})
