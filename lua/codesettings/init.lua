local Settings = require('codesettings.settings')
local SpecialCases = require('codesettings.schema.special-cases')

local M = {}

---For more granular control, load settings manually through this
---function and use the Settings API. For example:
---```lua
---local c = require('codesettings')
---local eslint_settings = c.local_settings():schema('eslint'):merge({
---  eslint = {
---    codeAction = {
---     disableRuleComment = {
---       enable = true,
---       location = 'sameLine'
---      }
---    }
---  }
---}):get('eslint') -- return only the `eslint` subtable
---```
---@return Settings config settings object, if any local config files were found, empty Settings object otherwise
function M.local_settings()
  return Settings.load_all()
end

---Load settings from VS Code settings.json file
---@param lsp_name string the name of the LSP, like 'rust-analyzer' or 'tsserver'
---@param config table the LSP config to merge the vscode settings into
---@param merge_opts MergeOpts? options for merging; if nil, uses the default from config
---@return table config the merged config
function M.with_local_settings(lsp_name, config, merge_opts)
  return Settings.new(config)
    :merge(M.local_settings():schema(lsp_name):get(SpecialCases[lsp_name]), 'settings', merge_opts)
    :totable()
end

function M.setup(opts)
  require('codesettings.config').setup(opts)
end

return M
