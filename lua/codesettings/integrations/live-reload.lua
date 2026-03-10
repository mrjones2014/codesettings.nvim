local Util = require('codesettings.util')

local M = {}

M.augroup_name = 'CodesettingsLiveReload'

---@type number|nil
local augroup = nil

---@type {[string]: uv.uv_timer_t}
local debounce_timers = {}

---Reload settings for all active LSP clients
---@param filepath string the config file that changed
local function reload_settings(filepath)
  local Settings = require('codesettings.settings')

  local settings = Settings.new():load(filepath)
  if not settings then
    return
  end

  local clients = vim.lsp.get_clients()

  if #clients == 0 then
    Util.info('settings file changed but no LSP clients are running')
    return
  end
  local updated_clients = false

  for _, client in ipairs(clients) do
    local client_settings = settings:schema(client.name)
    if client_settings and vim.tbl_count(client_settings:totable()) > 0 then
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings or {}, client_settings:totable())
      Util.did_change_configuration(client, client.config)
      updated_clients = true
    end
  end

  if not updated_clients then
    Util.info('settings file changed but no settings found for running LSP servers')
  end
end

function M.setup()
  if augroup then
    return
  end

  local config_files = Util.get_local_configs({ only_exists = false })
  if #config_files == 0 then
    -- if there are no config files,
    -- skip setting up the autocmd,
    -- otherwise the empty table `{}`
    -- pattern will match _all_ files,
    -- and try to parse any file as a
    -- config file
    return
  end
  augroup = vim.api.nvim_create_augroup(M.augroup_name, { clear = true })
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = augroup,
    pattern = config_files,
    callback = function(args)
      -- cancel existing timer for this file if any
      if debounce_timers[args.file] then
        debounce_timers[args.file]:stop()
        debounce_timers[args.file]:close()
      end

      -- check if the feature is still enabled
      if not require('codesettings.config').live_reload then
        vim.schedule(function()
          vim.api.nvim_del_augroup_by_id(augroup)
        end)
        return
      end

      -- create new timer that will fire after 100ms
      debounce_timers[args.file] = vim.defer_fn(function()
        reload_settings(args.file)
        debounce_timers[args.file] = nil
      end, 500)
    end,
  })
end

---Teardown live reload
function M.teardown()
  if augroup then
    vim.api.nvim_del_augroup_by_id(augroup)
    augroup = nil
  end
end

return M
