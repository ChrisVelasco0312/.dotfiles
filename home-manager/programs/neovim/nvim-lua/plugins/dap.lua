local dap = require('dap')

-- Visual indicators (signs) for breakpoints / current execution line.
-- Without these, toggling a breakpoint can feel like "nothing happened".
vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn', linehl = '', numhl = '' })
vim.fn.sign_define('DapLogPoint', { text = '▶', texthl = 'DiagnosticInfo', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '→', texthl = 'DiagnosticOk', linehl = 'Visual', numhl = '' })

-- NixOS typically ships the adapter as `lldb-dap` (not `lldb-vscode`).
local lldb_adapter = vim.fn.exepath('lldb-dap')
if lldb_adapter == '' then
  lldb_adapter = vim.fn.exepath('lldb-vscode')
end
if lldb_adapter == '' then
  lldb_adapter = 'lldb-dap' -- last resort; will error with a clearer message from nvim-dap
end

dap.adapters.lldb = {
  type = 'executable',
  command = lldb_adapter,
  name = 'lldb'
}

local lldb_config = {
  {
    name = 'Launch',
    type = 'lldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
    runInTerminal = false,
  },
  {
    name = 'Attach to process',
    type = 'lldb',
    request = 'attach',
    pid = require('dap.utils').pick_process,
    args = {},
  },
}

dap.configurations.cpp = lldb_config
dap.configurations.c = lldb_config
dap.configurations.rust = lldb_config

-- Keymaps for debugging
local map = vim.keymap.set
map('n', '<F5>', function() require('dap').continue() end, { desc = 'Debug: Continue' })
map('n', '<F10>', function() require('dap').step_over() end, { desc = 'Debug: Step Over' })
map('n', '<F11>', function() require('dap').step_into() end, { desc = 'Debug: Step Into' })
map('n', '<F12>', function() require('dap').step_out() end, { desc = 'Debug: Step Out' })
map('n', '<leader>b', function() require('dap').toggle_breakpoint() end, { desc = 'Debug: Toggle Breakpoint' })
map('n', '<leader>B', function() require('dap').set_breakpoint() end, { desc = 'Debug: Set Breakpoint' })
map('n', '<leader>lp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end, { desc = 'Debug: Log Point' })
map('n', '<leader>dr', function() require('dap').repl.open() end, { desc = 'Debug: Open REPL' })
map('n', '<leader>dl', function() require('dap').run_last() end, { desc = 'Debug: Run Last' })
