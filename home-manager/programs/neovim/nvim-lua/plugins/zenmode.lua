local zenmode = require("zen-mode")

zenmode.setup({
  window = {
    backdrop = 0.95, -- shade the backdrop of the Zen window
    width = 120, -- width of the Zen window (matching your noneck config)
    height = 1, -- height of the Zen window
    options = {
      signcolumn = "no", -- disable signcolumn
      number = false, -- disable number column
      relativenumber = false, -- disable relative numbers
      cursorline = false, -- disable cursorline
      cursorcolumn = false, -- disable cursor column
      foldcolumn = "0", -- disable fold column
    },
  },
  plugins = {
    options = {
      enabled = true,
      ruler = false, -- disables the ruler text in the cmd line area
      showcmd = false, -- disables the command in the last line of the screen
      laststatus = 0, -- turn off the statusline in zen mode
    },
    twilight = { enabled = false }, -- disable twilight integration
    gitsigns = { enabled = false }, -- disables git signs
    tmux = { enabled = false }, -- disables the tmux statusline
    todo = { enabled = false }, -- disable todo-comments highlights
  },
  -- callback where you can add custom code when the Zen window opens
  on_open = function(win)
  end,
  -- callback where you can add custom code when the Zen window closes
  on_close = function()
  end,
})

-- You can toggle zen mode with :ZenMode command
-- Or create a keymap like: vim.keymap.set("n", "<leader>z", "<cmd>ZenMode<cr>", { desc = "Toggle Zen Mode" }) 