local Config = require('codesettings.config')
local ConfigSchema = require('codesettings.config.schema')

local M = {}

---@class CodesettingsConfigBuilder
local ConfigBuilder = {}

local builder_mt = {
  __index = function(_, key)
    -- First check if it's a known ConfigBuilder method
    -- (e.g., build, local_settings, with_local_settings, not a config property setter)
    if ConfigBuilder[key] then
      return ConfigBuilder[key]
    end

    -- Check if this key exists in schema properties and is overridable
    local prop = ConfigSchema.properties[key]
    if prop and prop.overridable then
      -- Return a dynamically generated setter function for this property
      return function(self, value)
        -- Build validation types, filtering out function type tables
        local validation_types = {}

        -- Helper to build validation types from schema type (handles unions, functions, null)
        local function build_validation_types(schema_type)
          local val_types = {}
          local types = type(schema_type) == 'table' and schema_type or { schema_type }

          for _, t in ipairs(types) do
            if ConfigSchema.is_function_type(t) then
              table.insert(val_types, 'function')
            elseif t == 'null' then
              table.insert(val_types, 'nil')
            else
              table.insert(val_types, t)
            end
          end

          return val_types
        end

        -- Enum validation (if specified)
        if prop.enum then
          vim.validate(key, value, function(v)
            for _, allowed in ipairs(prop.enum) do
              if v == allowed then
                return true
              end
            end
            return false
          end, 'one of: ' .. table.concat(prop.enum, ', '))
        end

        -- Basic type validation
        if prop.type == 'array' then
          vim.validate(key, value, function(v)
            if not vim.islist(v) then
              return false
            end
            -- Validate array item types if schema specifies them
            if prop.items and prop.items.type then
              local item_validation_types = build_validation_types(prop.items.type)
              if #item_validation_types > 0 then
                for _, item in ipairs(v) do
                  -- Use vim.validate to check if item matches any of the allowed types
                  local ok = pcall(vim.validate, 'item', item, item_validation_types)
                  if not ok then
                    return false
                  end
                end
              end
            end
            return true
          end, 'array')
        elseif prop.type == 'string' or prop.type == 'boolean' then
          vim.validate(key, value, prop.type)
        elseif type(prop.type) == 'table' then
          -- Handle union types (e.g., { 'string', { args = {}, ret = 'string' }, 'null' })
          validation_types = build_validation_types(prop.type)
          if #validation_types > 0 then
            vim.validate(key, value, validation_types)
          end
        end

        if prop.type == 'object' and type(value) == 'table' then
          self._config[key] = vim.tbl_deep_extend('force', self._config[key] or {}, value)
        else
          self._config[key] = value
        end
        return self
      end
    end

    error(string.format("ConfigBuilder has no method or property '%s'", key))
  end,
}

---Create a new ConfigBuilder, initialized with the default global config
---@return CodesettingsConfigBuilder
function M.new()
  -- Dynamically build opts from schema properties that are overridable
  local opts = {}
  for key, prop in pairs(ConfigSchema.properties) do
    if prop.overridable then
      opts[key] = Config[key]
    end
  end

  local instance = {
    _config = opts --[[@as CodesettingsOverridableConfig]],
  }
  return setmetatable(instance, builder_mt)
end

---Return the resulting configuration table
---@return CodesettingsConfigOverrides
function ConfigBuilder:build()
  -- self._config is of type CodesettingsOverridableConfig,
  -- CodesettingsConfigOverrides is just a `@class (partial)` of that type
  return self._config --[[@as CodesettingsConfigOverrides]]
end

---Load the local settings, using the configuration built by this builder (i.e. you may
---have overridden some options like `root_dir` or `config_file_paths`).
---@return CodesettingsSettings
function ConfigBuilder:local_settings()
  return require('codesettings').local_settings(self:build())
end

---Load the local settings and merge them into the given LSP config,
---using the configuration built by this builder (i.e. you may
---have overridden some options like `root_dir` or `config_file_paths`).
---@param lsp_name string the name of the LSP, like 'rust-analyzer' or 'tsserver'
---@param config table the LSP config to merge the vscode settings into
---@return table config the merged config
function ConfigBuilder:with_local_settings(lsp_name, config)
  return require('codesettings').with_local_settings(lsp_name, config, self:build())
end

return M
