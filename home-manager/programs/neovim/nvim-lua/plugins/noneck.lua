local neckPain = require("no-neck-pain")

neckPain.setup({
  killAllBuffersOnDisable = true,
  width = 120,
  autocmds = {
    enableOnVimEnter = true,
    enableOnTabEnter = true,
  }
})
