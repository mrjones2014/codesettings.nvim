local Settings = require('codesettings.settings')

---A mapping of LSP names to the subtable that should be passed to the vim.lsp.config() schema.
---In a few cases this varies slightly from the VS Code extension schema, e.g. for `eslint`,
---the VS Code properties all start with `eslint.*` but the LSP expects to be passed only the subtable.
---The function **is expected** to apply the LSP server schema.
---@type table<string, fun(settings: CodesettingsSettings): CodesettingsSettings>
local SpecialCases = {
  eslint = function(settings)
    -- vscode schema has all properties under `eslint.*`, but the LSP expects just the subtable
    return settings:schema('eslint'):get_subtable('eslint') or settings
  end,
  nixd = function(settings)
    -- nixd vscode plugin nests the settings under `nix.serverSettings`, but the LSP expects just the subtable
    local vscode_table = settings:get_subtable('nix.serverSettings')
    if vscode_table then
      settings:merge(vscode_table)
      settings:set('nix.serverSettings', nil)
    end
    return settings:schema('nixd')
  end,
  tinymist = function(settings)
    return settings:schema('tinymist'):get_subtable('tinymist') or settings
  end,
}

---@class Codesettings
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
---@param opts CodesettingsConfigOverrides? optional config overrides for this load
---@return CodesettingsSettings config settings object, if any local config files were found, empty Settings object otherwise
function M.local_settings(opts)
  opts = opts or {}
  return Settings.load_all(opts)
end

---Load settings from VS Code settings.json file. This mutates the given LSP config.
---@param lsp_name string the name of the LSP, like 'rust-analyzer' or 'tsserver'
---@param config vim.lsp.Config|vim.lsp.ClientConfig the LSP config to merge the vscode settings into
---@param opts CodesettingsConfigOverrides? optional config overrides for this load
---@return table config the merged config
function M.with_local_settings(lsp_name, config, opts)
  opts = opts or {}
  local local_settings = M.local_settings(opts)
  if SpecialCases[lsp_name] ~= nil then
    local_settings = SpecialCases[lsp_name](local_settings)
  else
    local_settings = local_settings:schema(lsp_name)
  end
  return Settings.new(config):merge(local_settings, 'settings', opts):totable()
end

---Start building a new custom configuration for loading local settings.
---You can override any options in `CodesettingsConfigOverrides` through the builder API,
---then load local config files according to that configuration in a one-shot fluent API,
---without modifying the global plugin configuration. This is useful for supporting multi-root
---projects. For example, a hook relying on the LSP configs root directory:
---```lua
---vim.lsp.config('rust_analyzer', {
---  before_init = function(_, config)
---   local c = require('codesettings')
---   config.settings = c.loader()
---     :root_dir(config.root_dir)
---     :merge_lists('prepend')
---     :config_file_paths({ '.vscode/settings.json', '.myprojectsettings.json' })
---     :with_local_settings(config.name, config.settings)
---  end
---})
---```
---@return CodesettingsConfigBuilder
function M.loader()
  return require('codesettings.config.builder').new()
end

---Setup the plugin with the given options.
---@param opts CodesettingsConfigOverrides? optional config overrides for the global plugin configuration
function M.setup(opts)
  vim.treesitter.language.register('markdown', 'codesettings-output')

  opts = opts or {}
  require('codesettings.config').setup(opts)
end

return M
