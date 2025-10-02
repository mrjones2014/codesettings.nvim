---@class CodesettingsConfig
---@field config_file_paths string[]
---@field setup fun(opts: table|nil)

-- Internal defaults table (not exposed directly)
local options = {
  ---Look for these config files
  config_file_paths = { '.vscode/settings.json', 'codesettings.json', 'lspsettings.json' },
}

-- Public config object (contains only the options + setup)
local Config = {}

---Merge user-supplied options into the defaults.
---@param opts table|nil
function Config.setup(opts)
  if not opts or vim.tbl_isempty(opts) then
    return
  end
  options = vim.tbl_deep_extend('force', {}, options, opts)
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
