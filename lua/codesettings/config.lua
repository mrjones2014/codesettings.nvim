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

---@type CodesettingsConfig
local Config = {} ---@diagnostic disable-line: missing-fields

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
    -- lazy loading; go through currently open buffers and explicitly set filetype
    -- if they are already open
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local name = vim.api.nvim_buf_get_name(buf)
      if filetypes[name] then
        vim.bo[buf].filetype = 'jsonc'
      end
    end
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

return Config
