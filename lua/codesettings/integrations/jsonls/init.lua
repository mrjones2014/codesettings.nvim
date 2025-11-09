local Util = require('codesettings.util')
local Transformer = require('codesettings.integrations.jsonls.transformer')

local M = {}

local _cache = nil

---Clear the cached JSON schemas.
---They will be reloaded on the next call to `get_json_schemas()`.
function M.clear_cache()
  _cache = nil
end

---Retrieve JSON schemas as tables and merge them with already configured jsonls schemas.
---You can use this if the automatic configuration doesn't work.
---```lua
---vim.lsp.config('jsonls', {
---  settings = {
---    json = {
---      schemas = require('codesettings.jsonls').get_json_schemas(),
---      validate = { enable = true },
---    },
---  },
---})
---```
---@return table[] list of JSON schema objects suitable for jsonls config
function M.get_json_schemas()
  if _cache then
    return _cache
  end

  local configs = Util.get_local_configs()

  -- Merge all schemas into one before expanding (much faster)
  local Settings = require('codesettings.settings')
  local merged = Settings.new()

  vim.iter(pairs(require('codesettings.build.schemas').get_schemas())):each(function(_, schema)
    local ok, json = pcall(Util.read_file, schema.settings_file)
    if not ok then
      error('Failed to read JSON schema file: ' .. schema.settings_file)
    end
    merged:merge(Util.json_decode(json))
  end)

  merged:merge(require('codesettings.config').jsonschema():totable())

  -- Single expansion pass on the merged schema
  local expanded_schema = Transformer.expand_schema(merged:totable())
  -- also allow trailing commas
  expanded_schema.allowTrailingCommas = true

  local json_schemas = {
    {
      fileMatch = configs,
      schema = expanded_schema,
    },
  }

  -- make sure we don't clobber any already configured schemas
  local configured_schemas = vim.tbl_get(vim.lsp.config, 'jsonls', 'settings', 'json', 'schemas') or {}

  _cache = vim.list_extend(vim.deepcopy(configured_schemas), json_schemas)
  return _cache
end

function M.setup()
  vim.lsp.config('jsonls', {
    settings = {
      json = {
        schemas = M.get_json_schemas(),
        validate = { enable = true },
      },
    },
  })

  -- lazy loading; if jsonls is already active, restart it
  Util.restart_lsp('jsonls')
end

return M
