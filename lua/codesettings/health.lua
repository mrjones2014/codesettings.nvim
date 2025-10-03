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

  if pcall(vim.treesitter.get_string_parser, '', 'jsonc') then
    ok('**jsonc** parser for tree-sitter is installed')
  else
    warn('**jsonc** parser for tree-sitter is not installed. Jsonc highlighting might be broken')
  end
end

return M
