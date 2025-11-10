local View = require('codesettings.commands.view')

---Smart inspect that truncates extremely large nested structures
---@param value any The value to inspect
---@param client_name string The name of the LSP client
---@return string
local function safe_inspect(value, client_name)
  -- For jsonls, the schema can be extremely large and cause vim.inspect to hang
  -- We'll provide a summary instead of the full structure when expanded schemas are present
  if client_name == 'jsonls' and type(value) == 'table' and value.json and value.json.schemas then
    local schemas = value.json.schemas

    -- Check if any schema is particularly large (likely from our jsonls integration's expand_schema)
    -- A threshold of 50 properties indicates an expanded schema
    local has_large_schema = false
    for _, schema in ipairs(schemas) do
      if schema.schema and type(schema.schema.properties) == 'table' then
        local prop_count = #vim.tbl_keys(schema.schema.properties)
        if prop_count > 50 then
          has_large_schema = true
          break
        end
      end
    end

    -- Only truncate if we detected a large expanded schema
    if has_large_schema then
      local summary = vim.deepcopy(value)

      -- Create a placeholder marker that we'll replace after inspection
      local marker = '__SCHEMAS_TRUNCATED_MARKER__'
      summary.json.schemas = marker

      -- Show metadata about the schemas instead
      local schema_info = {}
      for i, schema in ipairs(schemas) do
        local fileMatch = type(schema.fileMatch) == 'table' and table.concat(schema.fileMatch, ', ') or schema.fileMatch
        table.insert(schema_info, {
          index = i,
          fileMatch = fileMatch,
          schema_keys = schema.schema and vim.tbl_keys(schema.schema) or {},
          schema_size = schema.schema and vim.tbl_count(schema.schema) or 0,
        })
      end
      summary.json.schema_info = schema_info

      local result = vim.inspect(summary)
      -- Replace the marker string with the table-style comment
      result = result:gsub('"' .. marker .. '"', '{ --[[ large schemas truncated for display ]] }')
      return result
    end
  end

  -- For other clients, use default inspection with a reasonable depth limit
  return vim.inspect(value, { depth = 10, newline = '\n', indent = '  ' })
end

return function()
  local text = ''
  vim.iter(vim.lsp.get_clients()):each(function(client)
    text = ('%s# %s\n\n```lua\n%s\n```\n\n'):format(text, client.name, safe_inspect(client.settings, client.name))
  end)
  if text == '' then
    text = '# No active LSP clients found'
  end
  View.show(text)
end
