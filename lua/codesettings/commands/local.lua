local View = require('codesettings.commands.view')

return function()
  local config = require('codesettings').local_settings():totable()
  View.show(([[
# Resolved configuration from local config files

```lua
%s
```
]]):format(vim.inspect(config)))
end
