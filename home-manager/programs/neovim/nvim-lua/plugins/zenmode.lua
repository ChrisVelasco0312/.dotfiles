local zenmode = require("zen-mode")

zenmode.setup({
  window = {
    backdrop = 0.95, -- shade the backdrop of the Zen window
    width = 120, -- width of the Zen window (matching your noneck config)
    height = 1, -- height of the Zen window
    -- by default, no options are changed for the Zen window
    -- keeping all UI elements visible for centered functionality only
    options = {
      -- signcolumn = "yes", -- keep signcolumn visible
      -- number = true, -- keep line numbers visible
      -- relativenumber = true, -- keep relative numbers if enabled
      -- cursorline = true, -- keep cursorline visible
      -- cursorcolumn = false, -- keep cursor column setting
      -- foldcolumn = "auto", -- keep fold column visible
    },
  },
  plugins = {
    options = {
      enabled = false, -- disable global vim options changes to keep UI
      -- ruler = true, -- keep ruler visible
      -- showcmd = true, -- keep command visible
      -- laststatus = 2, -- keep statusline visible
    },
    twilight = { enabled = false }, -- disable twilight integration
    gitsigns = { enabled = true }, -- keep git signs visible
    tmux = { enabled = false }, -- keep tmux statusline
    todo = { enabled = true }, -- keep todo-comments highlights
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