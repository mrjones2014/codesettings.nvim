-- minimal init.lua for running Neovim tests
vim.cmd([[set runtimepath+=.]])

local success = require('busted.runner')({ standalone = false })
vim.schedule(function()
  vim.cmd.quit({ bang = true })
  os.exit(success and 0 or 1)
end)
