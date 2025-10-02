# codesettings.nvim

Read your project's .vscode/settings.json and merge it into your Neovim 0.11+ native LSP configuration.

This plugin makes it easy to reuse editor settings that your team already committed for VS Code (including
JSON with comments) by transparently merging the relevant namespace into the LSP `settings` table you pass to `vim.lsp.config()` (or any way you configure LSP).

- Works with JSONC (JSON with comments, trailing commas)
- Deep-merges into your existing LSP config.settings
- Minimal API: one function you call per server setup
- Root detection based on .vscode or .git markers

## Requirements

- A .vscode/settings.json in your project root (optional; if missing, your config is returned unchanged)

## Installation

Use your favorite plugin manager. Replace `user/repo` with the actual repository slug.

- lazy.nvim

```lua
{
  'mrjones2014/codesettings.nvim',
  -- opts = {}, -- no setup needed
}
```

# Quick start

Call `with_vscode_settings(namespace, config)` when you set up an LSP server. The function will:

- Locate the project root (by .vscode or .git)
- Load .vscode/settings.json (JSONC supported)
- Pick the values under the given namespace
- Deep-merge them into `config.settings`
- Return the resulting config table

If the file or namespace does not exist, your original `config` is returned unchanged.

```lua
local codesettings = require('codesettings')

-- YAML Language Server (VS Code schema namespace: "yaml")
vim.lsp.config(
  'yamlls',
  codesettings.with_vscode_settings('yaml', {
    settings = {
      yaml = {
        validate = true,
        schemaStore = { enable = true },
      },
    },
  })
)

-- rust-analyzer is a bit weird in that it includes the ['rust-analyzer']
-- namespace as the top-level key; you just have to apply it a little different
vim.lsp.config('rust-analyzer', {
  settings = {
    ['rust-analyzer'] = codesettings.with_vscode_settings('rust-analyzer', {
      files = {
        excludeDirs = { '.direnv' },
      },
    }),
  },
})
```

Tip: The namespace is the top-level key used by the corresponding VS Code extension inside settings.json. Common examples:

- yaml: `yaml`
- JSON: `json`
- Lua LS: `Lua`
- Rust Analyzer: `rust-analyzer`
- Go: `gopls`

Check your project's .vscode/settings.json or the VS Code extension documentation to confirm the correct namespace.

## API

- `require('codesettings').with_vscode_settings(namespace: string, config: table): table`
  - Loads .vscode/settings.json from the project root, extracts the `namespace` table, and deep-merges it into `config.settings`. Returns the merged config.

- `require('codesettings').load(): Settings`
  - Loads and parses .vscode/settings.json for the current project. Returns a `Settings` object.
  - You can use this if you need fine-grained control beyond `with_vscode_settings`.
  - `Settings` object provides methods:
    - `Settings:get(key)` - returns the value at the specified key, supportes dot-separated keys like `Settings:get('lua_ls.Lua')` to get the sub-table
    - `Settings:clear()` - remove all values
    - `Settings:set(key, value)` - again supports dot-separated keys like `lua_ls.Lua`

Example using `load()` directly:

```lua
local codesettings = require('codesettings')
local lspconfig = require('lspconfig')

local s = codesettings.load()
local yaml_settings = s:get('yaml') or {}

lspconfig.yamlls.setup({
  settings = {
    yaml = vim.tbl_deep_extend('force', {
      validate = true,
    }, yaml_settings),
  },
})
```

## How it finds your settings

- Root discovery uses `vim.fs.root` with markers: `.vscode` or `.git`
- The plugin looks for `<root>/.vscode/settings.json`
- JSONC is supported, so comments and trailing commas are fine
- If the file or namespace is missing, your config is left as-is

## How merging works

- The plugin deep-merges plain tables (non-list tables)
- Lists/arrays are replaced, not concatenated
- Your provided `config` is the base; values from VS Code `namespace` override or extend it within `config.settings`

In short, VS Code settings take effect while preserving your base config, unless you explicitly override them.

## Troubleshooting

- Nothing changes: Ensure your workspace has `.vscode/settings.json` and the correct namespace keys exist.
- Wrong namespace: Inspect the keys used by your VS Code extension in settings.json or its documentation.
- Multi-root workspaces: The plugin uses file system markers; ensure you open Neovim in the intended project directory.
- `:lua=require('codesettings').load()` to see if it can even load the file
- `:lua=require('codesettings').load():get(some_namespace)` to see if your settings are resolved

## Acknowledgements

- The implementation of `lua/codesettings/settings.lua` is heavily based on folke's neoconf.nvim (Apache 2.0 license): https://github.com/folke/neoconf.nvim
- The bundled JSONC parser comes from this library (MIT license): https://github.com/actboy168/json.lua
