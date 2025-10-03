local Util = require('codesettings.util')
local View = require('codesettings.view')

local subcommands = {
  ---Show the files found in your project
  files = function()
    local configs = vim
      .iter(Util.get_local_configs())
      :map(function(path)
        return '- ' .. vim.fn.fnamemodify(path, ':~:.')
      end)
      :totable()
    View.show(vim.list_extend({ '# Local configuration files found:', '' }, configs))
  end,
  edit = function()
    local configs = Util.get_local_configs({ only_exists = false })
    if #configs == 0 then
      vim.notify('No local configuration files found', vim.log.levels.WARN)
      return
    end
    local function edit_file(path)
      vim.cmd.edit(vim.fn.fnameescape(path))
    end
    if #configs == 1 then
      edit_file(configs[1])
    else
      vim.ui.select(configs, {
        prompt = 'Select a configuration file to edit',
        format_item = function(item)
          local relpath = vim.fn.fnamemodify(item, ':~:.')
          if Util.exists(item) then
            return '  edit ' .. relpath
          else
            return '  create ' .. relpath
          end
        end,
      }, function(choice)
        if choice then
          edit_file(choice)
        end
      end)
    end
  end,
  health = function()
    require('codesettings.health').check()
  end,
}

local M = {}

function M.setup()
  vim.api.nvim_create_user_command('Codesettings', function(args)
    local cmd = vim.trim(args.args or '')
    if subcommands[cmd] then
      subcommands[cmd]()
    else
      subcommands.files()
    end
  end, {
    nargs = '?',
    desc = 'Manage project local settings with Codesettings',
    complete = function(_, line, _)
      if line:match('^%s*Neoconf %w+ ') then
        return {}
      end
      local prefix = line:match('^%s*Codesettings (%w*)')
      return vim.tbl_filter(function(key)
        return key:find(prefix) == 1
      end, vim.tbl_keys(subcommands))
    end,
  })
end

return M
