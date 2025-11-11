local Util = require('codesettings.util')

local M = {}

function M.setup()
  local configs = Util.get_local_configs()
  local filetypes = {}
  vim.iter(configs):each(function(f)
    filetypes[f] = 'jsonc'
  end)
  vim.filetype.add({
    filename = filetypes,
  })
  -- lazy loading; go through currently open buffers and explicitly set filetype
  -- if they are already open
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if filetypes[name] then
      vim.bo[buf].filetype = 'jsonc'
    end
  end
end

return M
