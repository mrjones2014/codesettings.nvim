local Settings = require('codesettings.settings')
local Util = require('codesettings.util')
local Methods = vim.lsp.protocol.Methods

local M = {}

---@type table<string, uv_fs_event_t>
local watchers = {}

---@type number|nil
local augroup = nil

---Reload settings for all active LSP clients
---@param filepath string the config file that changed
local function reload_settings(filepath)
  local settings = Settings.new():load(filepath)
  if not settings then
    return
  end

  local clients = vim.lsp.get_clients()
  local updated_clients = {}

  for _, client in ipairs(clients) do
    local client_settings = settings:schema(client.name)
    if client_settings and vim.tbl_count(client_settings:totable()) > 0 then
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings or {}, client_settings:totable())

      if client:supports_method(Methods.workspace_didChangeConfiguration) then
        client:notify(Methods.workspace_didChangeConfiguration, {
          settings = client.config.settings,
        })
        table.insert(updated_clients, client.name)
      else
        Util.restart_lsp(client.name)
        table.insert(updated_clients, client.name .. ' (restarted)')
      end
    end
  end

  if #updated_clients > 0 then
    Util.info('reloaded settings for: %s', table.concat(updated_clients, ', '))
  else
    Util.info('settings file changed but no settings found for running LSP servers')
  end
end

---Watch a file for changes
---@param path string
---@return boolean success
local function watch_file(path)
  if not Util.exists(path) then
    return false
  end

  if watchers[path] then
    watchers[path]:stop()
    watchers[path]:close()
  end

  local watcher = vim.uv.new_fs_event()
  if not watcher then
    return false
  end

  local debounce_timer = nil
  local debounce_ms = 150

  local function handle_change(err, filepath, events)
    if err then
      vim.schedule(function()
        Util.error('watcher error for %s: %s', vim.fn.fnamemodify(filepath, ':t'), err)
      end)
      return
    end

    -- editors like nvim use safe-write (write to temp, then rename)
    -- which triggers both change and rename events; we only care if the file still exists
    if events.change or events.rename then
      if debounce_timer then
        debounce_timer:stop()
        debounce_timer:close()
      end

      debounce_timer = vim.defer_fn(function()
        -- small delay to ensure file operations complete
        -- before checking existence (async fs operations)
        vim.defer_fn(function()
          vim.schedule(function()
            if Util.exists(filepath) then
              reload_settings(filepath)
            else
              -- file was deleted, stop watching
              Util.warn('file deleted: %s', vim.fn.fnamemodify(filepath, ':t'))
              if watchers[filepath] then
                watchers[filepath]:stop()
                watchers[filepath]:close()
                watchers[filepath] = nil
              end
            end
          end)
        end, 50)
        debounce_timer = nil
      end, debounce_ms)
    end
  end

  local ok = watcher:start(path, {}, handle_change)

  if ok ~= 0 then
    watcher:close()
    return false
  end

  watchers[path] = watcher
  return true
end

---Stop all watchers
local function unwatch_all()
  for _, watcher in pairs(watchers) do
    if not watcher:is_closing() then
      watcher:stop()
      watcher:close()
    end
  end
  watchers = {}
end

---Watch all config files in the current project
local function watch_config_files()
  unwatch_all()

  local config_files = Util.get_local_configs({ only_exists = true })

  for _, filepath in ipairs(config_files) do
    if not watch_file(filepath) then
      Util.error('failed to watch %s', filepath)
    end
  end
end

function M.setup()
  if augroup then
    return
  end

  augroup = vim.api.nvim_create_augroup('CodesettingsLiveReload', { clear = true })

  vim.api.nvim_create_autocmd({ 'DirChanged', 'VimEnter' }, {
    group = augroup,
    callback = watch_config_files,
  })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = augroup,
    callback = M.teardown,
  })

  watch_config_files()
end

---Get the number of active watchers
---@return number
function M.count()
  return vim.tbl_count(watchers)
end

---Teardown live reload and stop all watchers
function M.teardown()
  if augroup then
    vim.api.nvim_del_augroup_by_id(augroup)
    augroup = nil
  end
  unwatch_all()
end

return M
