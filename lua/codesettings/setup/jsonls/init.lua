local Transformer = require('codesettings.setup.jsonls.transformer')
local Util = require('codesettings.util')

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

  _cache = json_schemas
  return _cache
end

function M.setup()
  local config_update = {
    settings = {
      json = {
        schemas = M.get_json_schemas(),
        validate = { enable = true },
      },
    },
  }

  Util.ensure_lsp_settings('jsonls', config_update)
end

return M
