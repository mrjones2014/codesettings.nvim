---@class CodesettingsConfig
---@field config_file_paths string[] List of config file paths to look for
---@field jsonls_integration boolean Integrate with jsonls for LSP settings completion
---@field jsonc_filetype boolean Set filetype to jsonc for config files
---@field default_merge_opts CodesettingsMergeOpts Default options for merging settings
---@field setup fun(opts: table|nil) Sets up the configuration with user options

local options = {
  config_file_paths = { '.vscode/settings.json', 'codesettings.json', 'lspsettings.json' },
  jsonls_integration = true,
  jsonc_filetype = true,
  default_merge_opts = {
    list_behavior = 'append',
  },
}

local Config = {}

---Merge user-supplied options into the defaults.
---@param opts table|nil
function Config.setup(opts)
  opts = opts or {}

  options = vim.tbl_deep_extend('force', {}, options, opts)

  if options.jsonls_integration then
    require('codesettings.integrations.jsonls').setup()
  end

  if options.jsonc_filetype then
    require('codesettings.integrations.jsonc-filetype').setup()
  end
end

setmetatable(Config, {
  __index = function(_, k)
    return options[k]
  end,
  __newindex = function(_, k, v)
    options[k] = v
  end,
  __pairs = function()
    return next, options, nil
  end,
})

-- it implements the type through the metatable above,
-- set the type information so that consuming modules get
-- the right info through the LSP
---@cast Config CodesettingsConfig
return Config
