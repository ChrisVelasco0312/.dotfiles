local augroup_format = vim.api.nvim_create_augroup("Format", { clear = true })

-- Global variable to track format on save state
vim.g.format_on_save_enabled = false

local enable_format_on_save = function(_, bufnr)
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
    enable_format_on_save(nil, bufnr)
    vim.notify('Format on save enabled', vim.log.levels.INFO)
  else
    disable_format_on_save(bufnr)
    vim.notify('Format on save disabled', vim.log.levels.INFO)
  end
end, { desc = 'Toggle format on save for current buffer' })

local on_attach = function(_, bufnr)
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

  -- Lesser used LSP functionality nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration') nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder') nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
  nmap('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[W]orkspace [L]ist Folders')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
  
  -- Only enable format on save if it's globally enabled
  if vim.g.format_on_save_enabled then
    enable_format_on_save(_, bufnr)
  end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

require('neodev').setup();
vim.lsp.config('lua_ls', {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = function()
    return vim.loop.cwd()
  end,
  cmd = { "lua-language-server" },
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
vim.lsp.enable('lua_ls')



local function setup_diags()
  vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, {
      virtual_text = false,
      signs = true,
      update_in_insert = false,
      underline = true,
    })
  end
end

setup_diags()

local server_configs = {
  ts_ls = {
    filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
    cmd = { "typescript-language-server", "--stdio" }
  },
  eslint = {
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    cmd = { "vscode-eslint-language-server", "--stdio" }
  },
  emmet_ls = {
    init_options = {
      filetypes = { "html" },
      html = {
        options = {
          -- For possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#L79-L267
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
  },
  lua_ls = {
    Lua = {
      workspace = {
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    }
  },
  markdown_oxide = {
    filetypes = { "markdown" },
    cmd = { "markdown-oxide", "--stdio" }
  },
  jdtls = {
    filetypes = { "java" },
    cmd = { "jdtls" },
  },
  nixd = {
    filetypes = { "nix" },
    formatting = {
      command = { "nixpkgs-fmt" }
    },
  },
  pylsp = {
    flags = {
      debounce_text_changes = 300,
    },
    plugins = {
      pycodestyle = {
        enabled = false,
      },
      flake8 = {
        enabled = false,
      },
      ruff = {
        enabled = true,
      },
      mypy = {
        enabled = true,
      },
      black = {
        enabled = true,
      },
      isort = {
        enabled = true,
      },
      rope_autoimport = {
        enabled = true,
      },
      rope_completion = {
        enabled = true,
      },
    },
  }
}

vim.lsp.config('ts_ls', {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = server_configs.ts_ls
})
vim.lsp.enable('ts_ls')

vim.lsp.config('eslint', {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = server_configs.eslint
})
vim.lsp.enable('eslint')

vim.lsp.config('pylsp', {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = server_configs.pylsp
})
vim.lsp.enable('pylsp')

vim.lsp.config('markdown_oxide', {
  on_attach = on_attach,
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
vim.lsp.enable('markdown_oxide')

vim.lsp.config('jdtls', {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = server_configs.jdtls
})
vim.lsp.enable('jdtls')

vim.lsp.config('emmet_ls', {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = server_configs.emmet_ls
})
vim.lsp.enable('emmet_ls')

vim.lsp.config('nixd', {
  autostart = true,
  capabilities = capabilities,
  settings = server_configs.nixd
})
vim.lsp.enable('nixd')

-- C/C++ (clangd)
vim.lsp.config('clangd', {
  on_attach = on_attach,
  cmd = {
    'clangd',
    '--background-index',
    '--query-driver=' .. table.concat({
      vim.fn.system('which clang++'):gsub('\n$', ''),
      vim.fn.system('which clang'):gsub('\n$', ''),
      vim.fn.system('which g++'):gsub('\n$', ''),
      vim.fn.system('which gcc'):gsub('\n$', ''),
    }, ','),
  },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
  root_markers = { '.clangd', '.clang-tidy', '.clang-format', 'compile_commands.json', 'compile_flags.txt', 'configure.ac', '.git' },
  capabilities = capabilities,
})
vim.lsp.enable('clangd')

-- Function to check if a floating dialog exists and if not
-- then check for diagnostics under the cursor
function OpenDiagnosticIfNoFloat()
  for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(winid).zindex then
      return
    end
  end
  -- THIS IS FOR BUILTIN LSP
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

-- Show diagnostics under the cursor when holding position
vim.api.nvim_create_augroup("lsp_diagnostics_hold", { clear = true })
vim.api.nvim_create_autocmd({ "CursorHold" }, {
  pattern = "*",
  command = "lua OpenDiagnosticIfNoFloat()",
  group = "lsp_diagnostics_hold",
})
