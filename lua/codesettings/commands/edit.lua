local Util = require('codesettings.util')

return function()
  local configs = Util.get_local_configs({ only_exists = false })
  if #configs == 0 then
    Util.warn('No local configuration files found')
    return
  end
  local function edit_file(path)
    vim.cmd.edit(vim.fn.fnameescape(path))
  end
  if #configs == 1 then
    edit_file(configs[1])
  else
    vim.ui.select(configs, {
      prompt = 'Select a configuration file to edit',
      format_item = function(item)
        local relpath = vim.fn.fnamemodify(item, ':~:.')
        if Util.exists(item) then
          return '  edit ' .. relpath
        else
          return '  create ' .. relpath
        end
      end,
    }, function(choice)
      if choice then
        edit_file(choice)
      end
    end)
  end
end
