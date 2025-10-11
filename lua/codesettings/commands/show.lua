local View = require('codesettings.commands.view')

return function()
  local text = ''
  vim.iter(vim.lsp.get_clients()):each(function(client)
    text = ('%s# %s\n\n```lua\n%s\n```\n\n'):format(text, client.name, vim.inspect(client.settings))
  end)
  if text == '' then
    text = '# No active LSP clients found'
  end
  View.show(text)
end
