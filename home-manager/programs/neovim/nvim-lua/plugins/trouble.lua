require('trouble').setup {}

vim.keymap.set("n", "<Leader>ld", function() require("trouble").toggle("diagnostics") end)
