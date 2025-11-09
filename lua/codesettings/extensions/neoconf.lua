local Control = require('codesettings.extensions').Control

---@class CodesettingsNeoconfExtension: CodesettingsLoaderExtension
local M = {}

---Check if we're at the root level
---@param ctx CodesettingsLoaderExtensionContext
---@return boolean
local function is_root_level(ctx)
  return #ctx.path == 0
end

---Transform neoconf configuration shape into codesettings shape.
---
---Neoconf uses:
---  - `neoconf.plugins.lua_ls.enabled` -> `codesettings.lua_ls_integration`
---  - `neoconf.plugins.jsonls.enabled` -> `codesettings.jsonls_integration`
---  - `neoconf.filetype_jsonc` -> `codesettings.jsonc_filetype`
---  - `lspconfig.*` -> flattened to root level
---
---This function modifies the node in place and returns it, allowing other
---extensions to continue processing the transformed structure.
---
---@param node table
---@return table
local function transform_neoconf_to_codesettings(node)
  -- Initialize codesettings config if neoconf config exists
  if node.neoconf then
    node.codesettings = node.codesettings or {}

    -- Map filetype_jsonc
    local filetype_jsonc = vim.tbl_get(node, 'neoconf', 'filetype_jsonc')
    if filetype_jsonc ~= nil then
      node.codesettings.jsonc_filetype = filetype_jsonc
    end

    -- Map lua_ls integration
    local lua_ls_enabled = vim.tbl_get(node, 'neoconf', 'plugins', 'lua_ls', 'enabled')
    local lua_ls_neovim = vim.tbl_get(node, 'neoconf', 'plugins', 'lua_ls', 'enabled_for_neovim_config')
    if lua_ls_enabled ~= nil then
      node.codesettings.lua_ls_integration = lua_ls_enabled
    elseif lua_ls_neovim ~= nil then
      node.codesettings.lua_ls_integration = lua_ls_neovim
    end

    -- Map jsonls integration
    local jsonls_enabled = vim.tbl_get(node, 'neoconf', 'plugins', 'jsonls', 'enabled')
    if jsonls_enabled ~= nil then
      node.codesettings.jsonls_integration = jsonls_enabled
    end

    -- Remove neoconf key after transformation
    node.neoconf = nil
  end

  -- Flatten lspconfig settings into root
  if node.lspconfig and type(node.lspconfig) == 'table' then
    for _, server_settings in pairs(node.lspconfig) do
      if type(server_settings) == 'table' then
        -- Merge server settings directly into root
        for key, value in pairs(server_settings) do
          node[key] = value
        end
      end
    end

    -- Remove lspconfig key after flattening
    node.lspconfig = nil
  end

  -- Remove other neoconf-specific keys that we don't use
  node.neodev = nil

  return node
end

---@param node any
---@param ctx CodesettingsLoaderExtensionContext
---@return CodesettingsLoaderExtensionControl, any?
function M.object(node, ctx)
  -- Only process at the root level
  if not is_root_level(ctx) then
    return Control.CONTINUE
  end

  if type(node) ~= 'table' then
    return Control.CONTINUE
  end

  -- Check if this looks like a neoconf config
  local has_neoconf_keys = node.neoconf ~= nil or node.lspconfig ~= nil or node.neodev ~= nil

  if not has_neoconf_keys then
    return Control.CONTINUE
  end

  -- Transform in place and continue traversal so other extensions can process children
  transform_neoconf_to_codesettings(node)
  return Control.CONTINUE
end

return M
