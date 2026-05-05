-- opencode.nvim configuration
-- Note: snacks.nvim dependency should be configured separately via Nix

---@type opencode.Opts
vim.g.opencode_opts = {
  provider = {
    enabled = "terminal",
  },
}

vim.o.autoread = true -- Required for `opts.events.reload`

-- Recommended/example keymaps (using ; prefix for tmux compatibility)
vim.keymap.set({ "n", "x" }, ";oa", function() require("opencode").ask("@this: ", { submit = true }) end,
  { desc = "[O]pencode [A]sk…" })
vim.keymap.set({ "n", "x" }, ";ox", function() require("opencode").select() end,
  { desc = "[O]pencode e[X]ecute action…" })
vim.keymap.set({ "n", "t" }, ";ot", function() require("opencode").toggle() end, { desc = "[O]pencode [T]oggle" })

vim.keymap.set({ "n", "x" }, ";og", function() return require("opencode").operator("@this ") end,
  { desc = "[O]pencode add ran[G]e", expr = true })
vim.keymap.set("n", ";ol", function() return require("opencode").operator("@this ") .. "_" end,
  { desc = "[O]pencode add [L]ine", expr = true })

vim.keymap.set("n", ";ou", function() require("opencode").command("session.half.page.up") end,
  { desc = "[O]pencode scroll [U]p" })
vim.keymap.set("n", ";od", function() require("opencode").command("session.half.page.down") end,
  { desc = "[O]pencode scroll [D]own" })
