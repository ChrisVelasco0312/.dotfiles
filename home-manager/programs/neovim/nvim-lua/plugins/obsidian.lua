require('obsidian').setup({
  workspaces = {
    {
      name = "vaults",
      path = "~/Desktop/vaults",
    }
  },
  follow_url_func = function(url)
    vim.fn.jobstart({"xdg-open", url})
  end
})
