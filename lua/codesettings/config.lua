---@class CodesettingsConfig
---@field config_file_paths string[]
---@field jsonls_integration boolean
---@field setup fun(opts: table|nil)

-- Internal defaults table (not exposed directly)
local options = {
  ---Look for these config files
  config_file_paths = { '.vscode/settings.json', 'codesettings.json', 'lspsettings.json' },
  ---Integrate with jsonls to provide LSP completion for LSP settings based on schemas
  jsonls_integration = true,
  ---Set filetype to jsonc when opening a file specified by `config_file_paths`,
  ---make sure you have the jsonc tree-sitter parser installed for highlighting
  jsonc_filetype = true,
}

-- Public config object (contains only the options + setup)
local Config = {}

---Merge user-supplied options into the defaults.
---@param opts table|nil
function Config.setup(opts)
  opts = opts or {}

  options = vim.tbl_deep_extend('force', {}, options, opts)

  if options.jsonls_integration then
    require('codesettings.jsonls').setup()
  end

  if options.jsonc_filetype then
    -- NB: inline require to avoid circular dependency between config and util modules
    local configs = require('codesettings.util').get_local_configs()
    local filetypes = {}
    vim.iter(configs):each(function(f)
      filetypes[f] = 'jsonc'
    end)
    vim.filetype.add({
      filename = filetypes,
    })
  end
end

setmetatable(Config, {
  -- Expose option fields transparently
  __index = function(_, k)
    return options[k]
  end,
  -- Allow direct assignment (config.some_option = value)
  __newindex = function(_, k, v)
    options[k] = v
  end,
  -- Make pairs(config) iterate over current options
  __pairs = function()
    return next, options, nil
  end,
  -- Optional: length operator (#config) returns number of option keys
  __len = function()
    return vim.tbl_count(options)
  end,
})

return Config
