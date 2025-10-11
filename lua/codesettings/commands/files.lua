local Util = require('codesettings.util')
local View = require('codesettings.commands.view')

return function()
  local configs = vim
    .iter(Util.get_local_configs())
    :map(function(path)
      return '- ' .. vim.fn.fnamemodify(path, ':~:.')
    end)
    :totable()
  View.show(vim.list_extend({ '# Local configuration files found:', '' }, configs))
end
