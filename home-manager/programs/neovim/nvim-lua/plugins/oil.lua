require("oil").setup({
  default_file_explorer = true,
  float = {
    max_width = 40,
    max_height = 20,
  }
})

vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })

-- open in floating window
vim.keymap.set("n", "sf", require("oil").open_float, { desc = "Open parent directory in floating window" })
