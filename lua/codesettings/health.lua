local Config = require('codesettings.config')
local Util = require('codesettings.util')

local health_start = vim.health.start or vim.health.report_start
local health_ok = vim.health.ok or vim.health.report_ok
local health_warn = vim.health.warn or vim.health.report_warn
local health_info = vim.health.info or vim.health.report_info

local function info(msg, ...)
  health_info(msg:format(...))
end

local function ok(msg, ...)
  health_ok(msg:format(...))
end

local function warn(msg, ...)
  health_warn(msg:format(...))
end

local function error(msg, ...)
  health_warn(msg:format(...))
end

local M = {}

function M.check()
  health_start('codesettings.nvim')

  if vim.fn.has('nvim-0.11.0') == 0 then
    error('Neovim 0.11.0 or higher is required for jsonls integration, it uses `vim.lsp.config()`')
    return
  else
    ok('Neovim version is %s', vim.version().major .. '.' .. vim.version().minor .. '.' .. vim.version().patch)
  end

  local configs = Util.get_local_configs()
  if #configs == 0 then
    info('No local configuration files found in the current project')
  else
    ok(
      'Found local configuration file(s) in the current project: %s',
      vim.inspect(vim
        .iter(configs)
        :map(function(path)
          return vim.fn.fnamemodify(path, ':~:.')
        end)
        :totable())
    )
  end

  if pcall(vim.treesitter.get_string_parser, '', 'json') then
    ok('`json` parser for tree-sitter is installed')
  else
    warn('`json` parser for tree-sitter is not installed. Json highlighting might be broken')
  end

  if Config.live_reload then
    ok(('Live reload is enabled for paths: %s'):format(vim.inspect(Config.config_file_paths)))
  else
    info(
      'Live reload is disabled. Enable with `live_reload = true` to automatically reload settings when config files change'
    )
  end

  -- check LSP integration settings
  if Config.jsonls_integration then
    ok('`jsonls` integration is enabled')
  else
    info('`jsonls` integration is disabled')
  end

  if Config.lua_ls_integration then
    ok('`lua_ls` integration is enabled')
  else
    info('`lua_ls` integration is disabled')
  end

  -- check loader extensions
  if Config.loader_extensions and #Config.loader_extensions > 0 then
    ok('Loader extensions configured: %d', #Config.loader_extensions)
  end
end

return M
