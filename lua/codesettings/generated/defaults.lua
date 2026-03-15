-- stylua: ignore start
---@type CodesettingsConfig
return {
  config_file_paths = { ".vscode/settings.json", "codesettings.json", "lspsettings.json" },
  jsonc_filetype = true,
  jsonls_integration = true,
  live_reload = false,
  loader_extensions = { "codesettings.extensions.vscode" },
  lua_ls_integration = true,
  merge_lists = "append",
  nls = true,
  root_dir = nil,
}
