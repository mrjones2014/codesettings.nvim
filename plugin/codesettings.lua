local subcommands = {
  ---show the resolved LSP config for each active LSP client; note that this only shows _active_ clients
  show = true,
  ---show the resolved local config found in local config files in your project
  ['local'] = true,
  ---show the config files found in your project
  files = true,
  ---edit or create a local config file based on your configured config file paths
  edit = true,
  ---check plugin health (alias for `:checkhealth codesettings`)
  health = true,
}

vim.api.nvim_create_user_command('Codesettings', function(args)
  local cmd = vim.trim(args.args or '')
  if cmd == '' then
    cmd = 'files'
  end
  if subcommands[cmd] then
    -- work around the fact that nvim treats all health.lua files as healthchecks
    cmd = cmd == 'health' and 'healthcheck' or cmd
    require('codesettings.commands.' .. cmd)()
  else
    require('codesettings.util').error('Unknown subcommand: %s', cmd)
  end
end, {
  nargs = '?',
  desc = 'Manage project local settings with Codesettings',
  complete = function(_, line, _)
    if line:match('^%s*Codesettings %w+ ') then
      return {}
    end
    local prefix = line:match('^%s*Codesettings (%w*)')
    return vim.tbl_filter(function(key)
      return key:find(prefix) == 1
    end, vim.tbl_keys(subcommands))
  end,
})
