local Util = require('codesettings.util')
local Jsonls = require('codesettings.setup.jsonls')
local Settings = require('codesettings.settings')
local Benchmark = {}

Benchmark.results = {}

---@param name string
---@param fn fun()
---@param iterations integer? default 10000
---@return table
function Benchmark.benchmark(name, fn, iterations)
  iterations = iterations or 10000

  collectgarbage('collect')
  local start = os.clock()
  for _ = 1, iterations do
    fn()
  end
  local elapsed = os.clock() - start

  local result = {
    name = name,
    iterations = iterations,
    total_time = elapsed,
    time_per_op = elapsed / iterations,
    ops_per_sec = iterations / elapsed,
  }

  table.insert(Benchmark.results, result)
  return result
end

function Benchmark.generate_markdown()
  local lines = {
    '# Benchmark Results',
    '',
    string.format('*Generated: %s*', os.date('%Y-%m-%d %H:%M:%S')),
    '',
    '## Summary',
    '',
    '| Benchmark | Iterations | Time/Op | Ops/Sec |',
    '|-----------|------------|---------|---------|',
  }

  for _, result in ipairs(Benchmark.results) do
    local time_unit, time_value
    if result.time_per_op < 1e-6 then
      time_unit = 'ns'
      time_value = result.time_per_op * 1e9
    elseif result.time_per_op < 1e-3 then
      time_unit = 'µs'
      time_value = result.time_per_op * 1e6
    elseif result.time_per_op < 1 then
      time_unit = 'ms'
      time_value = result.time_per_op * 1e3
    else
      time_unit = 's'
      time_value = result.time_per_op
    end

    table.insert(
      lines,
      string.format(
        '| %s | %d | %.2f %s | %.0f |',
        result.name,
        result.iterations,
        time_value,
        time_unit,
        result.ops_per_sec
      )
    )
  end

  return table.concat(lines, '\n')
end

function Benchmark.save_markdown()
  local filename = Util.path('bench/report.md')
  local content = Benchmark.generate_markdown()
  local file = io.open(filename, 'w')
  if file then
    file:write(content)
    file:close()
  else
    error('Failed to write to: ' .. filename)
    os.exit(1)
  end
end

function Benchmark.reset()
  Benchmark.results = {}
end

local vscode_settings_json = [[
{
  // ============================================
  // Editor Defaults
  // ============================================
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": "explicit",
    "source.fixAll": "explicit"
  },
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,

  // ============================================
  // Web Dev Languages (Shared Settings)
  // ============================================
  "[json][jsonc][javascript][typescript][typescriptreact][javascriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.tabSize": 2,
    "editor.codeActionsOnSave": {
      "source.fixAll.eslint": "explicit"
    }
  },

  // ============================================
  // Scripting Languages
  // ============================================
  "[lua][luau][python]": {
    "editor.formatOnSave": true,
    "editor.tabSize": 2
  },

  // ============================================
  // Markup & Data Formats
  // ============================================
  "[markdown][yaml][toml][xml]": {
    "editor.wordWrap": "on",
    "editor.formatOnSave": false,
    "editor.rulers": [80, 100]
  },

  // ============================================
  // C-Family Languages
  // ============================================
  "[c][cpp][cc][h][hpp]": {
    "editor.defaultFormatter": "clangd",
    "editor.tabSize": 4,
    "editor.insertSpaces": true
  },

  // ============================================
  // Individual Language Overrides
  // ============================================
  "[lua]": {
    "editor.defaultFormatter": "JohnnyMorganz.stylua",
    "editor.tabSize": 2
  },

  "[luau]": {
    "editor.defaultFormatter": "JohnnyMorganz.stylua",
    "editor.tabSize": 4
  },

  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter",
    "editor.tabSize": 4,
    "editor.rulers": [88]
  },

  "[rust]": {
    "editor.defaultFormatter": "rust-lang.rust-analyzer",
    "editor.tabSize": 4
  },

  "[markdown]": {
    "editor.wordWrap": "on",
    "editor.quickSuggestions": {
      "comments": "off",
      "strings": "off",
      "other": "off"
    }
  },

  // ============================================
  // Rust Analyzer LSP
  // ============================================
  "rust-analyzer.check.command": "clippy",
  "rust-analyzer.checkOnSave": true,
  "rust-analyzer.cargo.features": "all",
  "rust-analyzer.lens.enable": true,
  "rust-analyzer.lens.references.adt.enable": true,
  "rust-analyzer.lens.references.trait.enable": true,
  "rust-analyzer.inlayHints.chainingHints.enable": true,
  "rust-analyzer.inlayHints.parameterHints.enable": true,
  "rust-analyzer.completion.autoimport.enable": true,
  "rust-analyzer.completion.autoself.enable": true,
  "rust-analyzer.diagnostics.disabled": ["unresolved-proc-macro"],
  "rust-analyzer.rustfmt.extraArgs": ["+nightly"],
  "rust-analyzer.procMacro.enable": true,
  "rust-analyzer.cargo.buildScripts.enable": true,
  "rust-analyzer.assist.importGranularity": "module",
  "rust-analyzer.hover.actions.enable": true,
  "rust-analyzer.hover.actions.references.enable": true,

  // ============================================
  // Lua Language Server
  // ============================================
  "Lua.runtime.version": "LuaJIT",
  "Lua.diagnostics.globals": [
    "vim",
    "describe",
    "it",
    "before_each",
    "after_each",
    "assert",
    "expect"
  ],
  "Lua.diagnostics.disable": ["lowercase-global", "undefined-global"],
  "Lua.workspace.library": [
    "${3rd}/luv/library",
    "${3rd}/busted/library",
    "${3rd}/luassert/library"
  ],
  "Lua.workspace.checkThirdParty": false,
  "Lua.completion.callSnippet": "Replace",
  "Lua.completion.keywordSnippet": "Replace",
  "Lua.hint.enable": true,
  "Lua.hint.paramName": "All",
  "Lua.hint.setType": true,
  "Lua.format.enable": false,
  "Lua.telemetry.enable": false,

  // ============================================
  // TypeScript/JavaScript LSP
  // ============================================
  "typescript.tsserver.log": "off",
  "typescript.suggest.autoImports": true,
  "typescript.updateImportsOnFileMove.enabled": "always",
  "typescript.preferences.importModuleSpecifier": "relative",
  "typescript.preferences.quoteStyle": "single",
  "typescript.inlayHints.parameterNames.enabled": "all",
  "typescript.inlayHints.parameterTypes.enabled": true,
  "typescript.inlayHints.variableTypes.enabled": true,
  "typescript.inlayHints.propertyDeclarationTypes.enabled": true,
  "typescript.inlayHints.functionLikeReturnTypes.enabled": true,
  "javascript.suggest.autoImports": true,
  "javascript.updateImportsOnFileMove.enabled": "always",

  // ============================================
  // ESLint LSP
  // ============================================
  "eslint.enable": true,
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ],
  "eslint.format.enable": true,
  "eslint.lintTask.enable": true,
  "eslint.workingDirectories": [{ "mode": "auto" }],
  "eslint.codeActionsOnSave.mode": "all",

  // ============================================
  // Python LSP (Pylance)
  // ============================================
  "python.languageServer": "Pylance",
  "python.analysis.typeCheckingMode": "basic",
  "python.analysis.diagnosticMode": "workspace",
  "python.analysis.autoImportCompletions": true,
  "python.analysis.completeFunctionParens": true,
  "python.analysis.inlayHints.variableTypes": true,
  "python.analysis.inlayHints.functionReturnTypes": true,
  "python.analysis.inlayHints.callArgumentNames": "partial",
  "python.analysis.autoFormatStrings": true,

  // ============================================
  // Prettier (Formatter)
  // ============================================
  "prettier.singleQuote": true,
  "prettier.trailingComma": "es5",
  "prettier.semi": true,
  "prettier.printWidth": 100,
  "prettier.tabWidth": 2,
  "prettier.arrowParens": "always",

  // ============================================
  // Go LSP (gopls)
  // ============================================
  "go.useLanguageServer": true,
  "gopls": {
    "ui.semanticTokens": true,
    "ui.completion.usePlaceholders": true,
    "analyses": {
      "unusedparams": true,
      "shadow": true
    },
    "staticcheck": true,
    "codelenses": {
      "gc_details": true,
      "generate": true,
      "test": true
    }
  },

  // ============================================
  // JSON Schema Associations
  // ============================================
  "json.schemas": [
    {
      "fileMatch": ["package.json"],
      "url": "https://json.schemastore.org/package.json"
    },
    {
      "fileMatch": ["tsconfig*.json"],
      "url": "https://json.schemastore.org/tsconfig.json"
    },
    {
      "fileMatch": [".luarc.json", ".luarc.jsonc"],
      "url": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json"
    },
    {
      "fileMatch": [".prettierrc.json", ".prettierrc.jsonc"],
      "url": "https://json.schemastore.org/prettierrc.json"
    }
  ],

  // ============================================
  // YAML Language Server
  // ============================================
  "yaml.schemas": {
    "https://json.schemastore.org/github-workflow.json": ".github/workflows/*.yml",
    "https://json.schemastore.org/prettierrc.json": ".prettierrc.{yml,yaml}"
  },
  "yaml.format.enable": true,
  "yaml.validate": true,

  // ============================================
  // C/C++ LSP (clangd)
  // ============================================
  "clangd.arguments": [
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    "--header-insertion=iwyu",
    "--pch-storage=memory"
  ],

  // ============================================
  // Diagnostic Display
  // ============================================
  "problems.showCurrentInStatus": true,
  "problems.sortOrder": "severity",

  // ============================================
  // Trace Server Communication (for debugging)
  // ============================================
  "rust-analyzer.trace.server": "off",
  "typescript.tsserver.trace": "off",
  "Lua.misc.parameters": ["--loglevel=warn"]
}
]]

Benchmark.benchmark('Load and parse VS Code settings.json including bracketed keys', function()
  local _ = Util.json_decode(vscode_settings_json)
end)

local parsed = Util.json_decode(vscode_settings_json)
local settings = Settings.new(parsed)
Benchmark.benchmark('Get a specific LSP schema out of the json', function()
  local _ = settings:schema('rust-analyzer')
end)

Benchmark.benchmark('Parse and expand all JSON schemas for jsonls integration', function()
  Jsonls.get_json_schemas()
  Jsonls.clear_cache()
end, 1000) -- this is the slowest functionality, reduce iterations

Benchmark.save_markdown()
