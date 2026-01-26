local Control = require('codesettings.extensions').Control
local Util = require('codesettings.util')

---@class CodesettingsVsCodeVariables
---@field userHome string|nil
---@field workspaceFolder string|nil
---@field workspaceFolderBasename string|nil
---@field cwd string|nil
---@field pathSeparator string
---@field ['/'] string

---@class CodesettingsVsCodeVariableOverrides
---@field root string? Override root dir from which other variables are derived
---@field home string? Override user home directory
---@field cwd string? Override current working directory
---@field path_sep string? Override path separator

--- Get VS Code variables
---@param overrides CodesettingsVsCodeVariableOverrides?
---@return CodesettingsVsCodeVariables
local function get_variables(overrides)
  overrides = overrides or {}
  local root = overrides.root or Util.get_root()
  local path_sep = overrides.path_sep or (vim.fn.has('win32') == 1 and '\\' or '/')
  return {
    userHome = overrides.home or vim.fn.expand('~'),
    workspaceFolder = root,
    workspaceFolderBasename = root and vim.fn.fnamemodify(root, ':t') or nil,
    cwd = overrides.cwd or vim.uv.cwd(),
    pathSeparator = path_sep,
    ['/'] = path_sep,
  }
end

---@class CodesettingsVSCodeExtension: CodesettingsLoaderExtension
---@field variables CodesettingsVsCodeVariables
local VsCodeExtension = {}
VsCodeExtension.__index = VsCodeExtension

function VsCodeExtension:leaf(value, _)
  if type(value) == 'string' then
    local expanded = self:expand_vscode_vars(value)
    if expanded ~= value then
      return Control.REPLACE, expanded
    end
  end
  return Control.CONTINUE
end

---Expand VS Code variable interpolation syntax
---@param str string
---@return string
function VsCodeExtension:expand_vscode_vars(str)
  str = str:gsub('%${([^}]+)}', function(var_name)
    local variable = self.variables[var_name]
    if variable then
      return variable
    end
    -- Return original if variable not supported
    return '${' .. var_name .. '}'
  end)

  return str
end

---Create a new VS Code extension
---@param overrides CodesettingsVsCodeVariableOverrides?
---@return CodesettingsVSCodeExtension
return function(overrides)
  local variables = get_variables(overrides)
  return setmetatable({ variables = variables }, VsCodeExtension)
end
