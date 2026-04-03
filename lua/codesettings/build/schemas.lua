local BuildUtil = require('codesettings.build.util')
local Util = require('codesettings.util')

local M = {}

M.index = {
  als = 'https://raw.githubusercontent.com/AdaCore/ada_language_server/master/integration/vscode/ada/package.json',
  angularls = 'https://raw.githubusercontent.com/angular/vscode-ng-language-service/refs/heads/main/package.json',
  astro = 'https://raw.githubusercontent.com/withastro/language-tools/main/packages/vscode/package.json',
  awkls = 'https://raw.githubusercontent.com/Beaglefoot/awk-language-server/master/client/package.json',
  basedpyright = 'https://raw.githubusercontent.com/DetachHead/basedpyright/main/packages/vscode-pyright/package.json',
  bashls = 'https://raw.githubusercontent.com/bash-lsp/bash-language-server/master/vscode-client/package.json',
  clangd = 'https://raw.githubusercontent.com/clangd/vscode-clangd/master/package.json',
  cssls = {
    schema = 'https://raw.githubusercontent.com/microsoft/vscode/main/extensions/css-language-features/package.json',
    nls = 'https://raw.githubusercontent.com/microsoft/vscode/main/extensions/css-language-features/package.nls.json',
  },
  dartls = 'https://raw.githubusercontent.com/Dart-Code/Dart-Code/master/package.json',
  denols = 'https://raw.githubusercontent.com/denoland/vscode_deno/main/package.json',
  elixirls = 'https://raw.githubusercontent.com/elixir-lsp/vscode-elixir-ls/master/package.json',
  elmls = 'https://raw.githubusercontent.com/elm-tooling/elm-language-client-vscode/master/package.json',
  emmylua_ls = 'https://raw.githubusercontent.com/EmmyLuaLs/emmylua-analyzer-rust/86ae47efba57c2d70a5af18faa6e8418b0129b22/crates/emmylua_code_analysis/resources/schema.json',
  eslint = 'https://raw.githubusercontent.com/microsoft/vscode-eslint/main/package.json',
  flow = 'https://raw.githubusercontent.com/flowtype/flow-for-vscode/master/package.json',
  fsautocomplete = 'https://raw.githubusercontent.com/ionide/ionide-vscode-fsharp/main/release/package.json',
  gopls = 'https://raw.githubusercontent.com/golang/vscode-go/master/extension/package.json',
  grammarly = 'https://raw.githubusercontent.com/znck/grammarly/main/extension/package.json',
  graphql = 'https://raw.githubusercontent.com/graphql/graphiql/refs/heads/main/packages/vscode-graphql/package.json',
  haxe_language_server = 'https://raw.githubusercontent.com/vshaxe/vshaxe/master/package.json',
  hhvm = 'https://raw.githubusercontent.com/slackhq/vscode-hack/master/package.json',
  hie = 'https://raw.githubusercontent.com/alanz/vscode-hie-server/master/package.json',
  hls = 'https://raw.githubusercontent.com/haskell/vscode-haskell/refs/heads/master/package.json',
  html = {
    schema = 'https://raw.githubusercontent.com/microsoft/vscode/main/extensions/html-language-features/package.json',
    nls = 'https://raw.githubusercontent.com/microsoft/vscode/main/extensions/html-language-features/package.nls.json',
  },
  intelephense = 'https://raw.githubusercontent.com/bmewburn/vscode-intelephense/master/package.json',
  java_language_server = 'https://raw.githubusercontent.com/georgewfraser/java-language-server/master/package.json',
  jdtls = 'https://raw.githubusercontent.com/redhat-developer/vscode-java/master/package.json',
  jsonls = {
    schema = 'https://raw.githubusercontent.com/microsoft/vscode/master/extensions/json-language-features/package.json',
    nls = 'https://raw.githubusercontent.com/microsoft/vscode/master/extensions/json-language-features/package.nls.json',
  },
  julials = 'https://raw.githubusercontent.com/julia-vscode/julia-vscode/master/package.json',
  kotlin_language_server = 'https://raw.githubusercontent.com/fwcd/vscode-kotlin/master/package.json',
  ltex = {
    schema = 'https://raw.githubusercontent.com/valentjn/vscode-ltex/develop/package.json',
    nls = 'https://raw.githubusercontent.com/valentjn/vscode-ltex/develop/package.nls.json',
  },
  lua_ls = {
    schema = 'https://raw.githubusercontent.com/LuaLS/vscode-lua/master/package.json',
    nls = 'https://raw.githubusercontent.com/LuaLS/vscode-lua/master/package.nls.json',
  },
  luau_lsp = 'https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/editors/code/package.json',
  nickel_ls = 'https://raw.githubusercontent.com/tweag/nickel/refs/heads/master/lsp/vscode-extension/package.json',
  nil_ls = 'https://raw.githubusercontent.com/oxalica/nil/refs/heads/main/editors/coc-nil/package.json',
  nixd = 'https://raw.githubusercontent.com/nix-community/nixd/refs/heads/main/nixd/docs/nixd-schema.json',
  omnisharp = {
    schema = 'https://raw.githubusercontent.com/OmniSharp/omnisharp-vscode/master/package.json',
    nls = 'https://raw.githubusercontent.com/OmniSharp/omnisharp-vscode/master/package.nls.json',
  },
  perlls = 'https://raw.githubusercontent.com/richterger/Perl-LanguageServer/master/clients/vscode/perl/package.json',
  perlnavigator = 'https://raw.githubusercontent.com/bscan/PerlNavigator/main/package.json',
  perlpls = 'https://raw.githubusercontent.com/FractalBoy/perl-language-server/master/client/package.json',
  powershell_es = 'https://raw.githubusercontent.com/PowerShell/vscode-powershell/main/package.json',
  psalm = 'https://raw.githubusercontent.com/psalm/psalm-vscode-plugin/master/package.json',
  puppet = 'https://raw.githubusercontent.com/puppetlabs/puppet-vscode/main/package.json',
  purescriptls = 'https://raw.githubusercontent.com/nwolverson/vscode-ide-purescript/master/package.json',
  pylsp = 'https://raw.githubusercontent.com/python-lsp/python-lsp-server/develop/pylsp/config/schema.json',
  pyright = 'https://raw.githubusercontent.com/microsoft/pyright/master/packages/vscode-pyright/package.json',
  r_language_server = 'https://raw.githubusercontent.com/REditorSupport/vscode-r-lsp/master/package.json',
  rescriptls = 'https://raw.githubusercontent.com/rescript-lang/rescript-vscode/master/package.json',
  rls = 'https://raw.githubusercontent.com/rust-lang/vscode-rust/master/package.json',
  rome = 'https://raw.githubusercontent.com/rome/tools/main/editors/vscode/package.json',
  ruff = 'https://raw.githubusercontent.com/astral-sh/ruff-vscode/main/package.json',
  rust_analyzer = 'https://raw.githubusercontent.com/rust-analyzer/rust-analyzer/master/editors/code/package.json',
  solargraph = 'https://raw.githubusercontent.com/castwide/vscode-solargraph/master/package.json',
  solidity_ls = 'https://raw.githubusercontent.com/juanfranblanco/vscode-solidity/master/package.json',
  sorbet = 'https://raw.githubusercontent.com/sorbet/sorbet/master/vscode_extension/package.json',
  sonarlint = 'https://raw.githubusercontent.com/SonarSource/sonarlint-vscode/master/package.json',
  sourcekit = 'https://raw.githubusercontent.com/swift-server/vscode-swift/main/package.json',
  spectral = 'https://raw.githubusercontent.com/stoplightio/vscode-spectral/master/package.json',
  stylelint_lsp = 'https://raw.githubusercontent.com/bmatcuk/coc-stylelintplus/master/package.json',
  svelte = 'https://raw.githubusercontent.com/sveltejs/language-tools/master/packages/svelte-vscode/package.json',
  svlangserver = 'https://raw.githubusercontent.com/eirikpre/VSCode-SystemVerilog/master/package.json',
  tailwindcss = 'https://raw.githubusercontent.com/tailwindlabs/tailwindcss-intellisense/master/packages/vscode-tailwindcss/package.json',
  terraformls = 'https://raw.githubusercontent.com/hashicorp/vscode-terraform/master/package.json',
  tinymist = {
    schema = 'https://raw.githubusercontent.com/Myriad-Dreamin/tinymist/refs/heads/main/editors/vscode/package.json',
    nls = 'https://raw.githubusercontent.com/Myriad-Dreamin/tinymist/main/locales/tinymist-vscode.toml',
  },
  ts_ls = {
    schema = 'https://raw.githubusercontent.com/microsoft/vscode/main/extensions/typescript-language-features/package.json',
    nls = 'https://raw.githubusercontent.com/microsoft/vscode/main/extensions/typescript-language-features/package.nls.json',
  },
  typst_lsp = 'https://raw.githubusercontent.com/nvarner/typst-lsp/refs/heads/master/editors/vscode/package.json',
  volar = {
    schema = 'https://raw.githubusercontent.com/vuejs/language-tools/master/extensions/vscode/package.json',
    nls = 'https://raw.githubusercontent.com/vuejs/language-tools/master/extensions/vscode/package.nls.json',
  },
  vtsls = 'https://raw.githubusercontent.com/yioneko/vtsls/main/packages/service/configuration.schema.json',
  vuels = 'https://raw.githubusercontent.com/vuejs/vetur/master/package.json',
  wgls_analyzer = 'https://raw.githubusercontent.com/wgsl-analyzer/wgsl-analyzer/main/editors/code/package.json',
  yamlls = 'https://raw.githubusercontent.com/redhat-developer/vscode-yaml/master/package.json',
  zeta_note = 'https://raw.githubusercontent.com/artempyanykh/zeta-note-vscode/main/package.json',
  zls = 'https://raw.githubusercontent.com/zigtools/zls-vscode/master/package.json',
}

--- Collect all terminal object property paths from a schema.
--- Terminal objects are properties with type="object" but no "properties" field,
--- meaning their keys are arbitrary user data and should not be dot-expanded.
---@param schema table JSON schema
---@param prefix string? current property path prefix
---@param terminals table<string, boolean> table to collect terminal paths
local function collect_terminal_objects(schema, prefix, terminals)
  if type(schema) ~= 'table' then
    return
  end

  local props = schema.properties
  if type(props) ~= 'table' then
    return
  end

  for name, def in pairs(props) do
    if type(def) == 'table' then
      local full_path = prefix and (prefix .. '.' .. name) or name

      -- Check if this is a terminal object:
      -- - type is "object"
      -- - no "properties" field (free-form dictionary)
      if def.type == 'object' and not def.properties then
        terminals[full_path] = true
      end

      -- Recurse if it has nested properties
      if def.properties then
        collect_terminal_objects(def, full_path, terminals)
      end
    end
  end
end

--- Generate a lookup table of all terminal object paths across all LSP schemas.
--- Returns a table mapping property paths to true for paths that should not have
--- their keys dot-expanded (e.g., "yaml.schemas").
---@return table<string, boolean> terminal object paths
function M.generate_terminal_objects_cache()
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end

  local schemas = BuildUtil.get_schemas()
  local terminals = {}

  for _, schema_meta in pairs(schemas) do
    if Util.exists(schema_meta.schema_path) then
      local ok, data = pcall(vim.fn.readfile, schema_meta.schema_path)
      if ok and type(data) == 'table' then
        local json_str = table.concat(data, '\n')
        local ok2, schema_json = pcall(vim.fn.json_decode, json_str)
        if ok2 and type(schema_json) == 'table' then
          collect_terminal_objects(schema_json, nil, terminals)
        end
      end
    end
  end

  return terminals
end

--- A map of LSP server schemas that require special handling for non-common configuration layouts.
local SpecialCases = {
  nixd = function(json)
    -- nixd should be nested under "nixd"
    return {
      nixd = {
        type = 'object',
        properties = json.properties,
      },
    }
  end,
  gopls = function(json)
    local config = json.contributes.configuration.properties.gopls
    json.description = config.markdownDescription

    local properties = vim.empty_dict()
    for k, v in pairs(config.properties) do
      -- The official gopls documentation generally uses these options without prefixes and recommends doing so.
      -- - https://github.com/golang/tools/blob/master/gopls/doc/editor/vim.md#neovim-config
      -- - https://github.com/golang/tools/blob/master/gopls/doc/settings.md
      local last = k:match('[^%.]+$')
      properties['gopls.' .. last] = v
    end
    return properties
  end,
  emmylua_ls = function(json)
    -- emmylua_ls schema has a flat structure but expects all settings to be nested under "Lua" like lua_ls
    -- when provided via lsp configuration.
    return {
      Lua = { type = 'object', properties = json.properties },
    }
  end,
}

---@param schema CodesettingsSchemaFile
function M.fetch_schema(schema)
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end

  local json = vim.json.decode(BuildUtil.fetch(schema.schema_url)) or {}

  local properties = vim.empty_dict()
  if SpecialCases[schema.name] then
    properties = SpecialCases[schema.name](json)
  else
    local config = json.contributes and json.contributes.configuration or json.properties and json

    if vim.islist(config) then
      for _, c in pairs(config) do
        if c.properties then
          for k, v in pairs(c.properties) do
            properties[k] = v
          end
        end
      end
    elseif config.properties then
      properties = config.properties
    end
  end

  local ret = {
    ['$schema'] = 'http://json-schema.org/draft-07/schema#',
    description = json.description,
    properties = properties,
    definitions = json.definitions,
    ['$defs'] = json['$defs'], -- seems to be an alias for definitions in some schemas
  }

  return ret
end

---THIS WILL CALL `os.exit(1)` IF A SCHEMA CANNOT BE FETCHED.
---This is only meant to be called from a build script!
function M.update_schemas()
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end

  local schemas = BuildUtil.get_schemas()
  local names = vim.tbl_keys(schemas)
  table.sort(names)
  for _, name in ipairs(names) do
    local s = schemas[name]
    print(('Generating schema for %s'):format(name))

    if not Util.exists(s.schema_path) then
      local ok, schema = pcall(M.fetch_schema, s)
      if ok then
        BuildUtil.write_file(s.schema_path, BuildUtil.json_format(schema))
      else
        os.exit(1)
      end
    end
  end
end

---Normalize a raw NLS table to a flat { key = "English string" } map.
---Handles two formats:
---  JSON format: flat { key = "string" }
---  TOML format: dotted keys expanded into nested tables by remarshal,
---    with leaf nodes of the form { en = "string", zh = "..." }
---@param raw table
---@return table<string, string>
local function flatten_dotted_toml(raw)
  local out = {}

  local function is_nls_leaf(node)
    return type(node) == 'table' and (type(node.en) == 'string')
  end

  local function walk(node, path)
    if type(node) ~= 'table' then
      return
    end
    if is_nls_leaf(node) then
      out[path] = node.en
    else
      for k, v in pairs(node) do
        walk(v, path .. '.' .. k)
      end
    end
  end

  for k, v in pairs(raw) do
    local key = k:match('^%%(.+)%%$') or k
    if type(v) == 'string' then
      out[key] = v
    else
      walk(v, key)
    end
  end

  return out
end

---THIS WILL CALL `os.exit(1)` IF AN NLS FILE CANNOT BE FETCHED.
---This is only meant to be called from a build script!
function M.update_nls()
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end

  local schemas = BuildUtil.get_schemas()
  local names = vim.tbl_keys(schemas)
  table.sort(names)
  for _, name in ipairs(names) do
    local s = schemas[name]
    local nls_file = BuildUtil.nls_path(name)
    if s.nls_url and not Util.exists(nls_file) then
      print(('Generating NLS for %s'):format(name))
      local ok, nls_table = pcall(function()
        local content = BuildUtil.fetch(s.nls_url)
        return s.nls_url:match('%.toml$') and flatten_dotted_toml(BuildUtil.toml_to_table(content))
          or vim.json.decode(content)
      end)

      if ok and type(nls_table) == 'table' then
        BuildUtil.write_file(nls_file, BuildUtil.json_format(nls_table))
      else
        print(('Warning: could not fetch/parse NLS for %s: %s'):format(name, tostring(nls_table)))
        os.exit(1)
      end
    end
  end
end

function M.build()
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end
  M.clean()
  M.update_schemas()
  M.update_nls()
end

function M.clean()
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end
  local schema_files = vim.fn.expand(BuildUtil.path('after/codesettings-schemas/*.json'), false, true)
  if type(schema_files) == 'string' then
    schema_files = { schema_files }
  end
  for _, f in pairs(schema_files) do
    Util.delete_file(f)
  end
  print('Deleted ' .. #schema_files .. ' schema files from after/codesettings-schemas/*')

  local nls_files = vim.fn.expand(BuildUtil.path('after/codesettings-nls/*.json'), false, true)
  if type(nls_files) == 'string' then
    nls_files = { nls_files }
  end
  for _, f in pairs(nls_files) do
    Util.delete_file(f)
  end
  print('Deleted ' .. #nls_files .. ' NLS files from after/codesettings-nls/*')
end

return M
