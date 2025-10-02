# codesettings.nvim

Read your project's .vscode/settings.json and merge it into your Neovim 0.11+ native LSP configuration.

This plugin makes it easy to reuse editor settings that your team already committed for VS Code (including
JSON with comments) by transparently merging the relevant settings from VS Code's settings schema into the
LSP `settings` table you pass to `vim.lsp.config()` (or any way you configure LSP).

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

Call `with_vscode_settings(lsp_name, config)` when you set up an LSP server. The function will:

- Locate the project root (by .vscode or .git)
- Load .vscode/settings.json (JSONC supported)
- Pick the values relevant according to the LSP's schema
- Deep-merge them into `config.settings`
- Return the resulting config table

```lua
local codesettings = require('codesettings')

-- global hook
vim.lsp.config('*', {
  before_init = function(_, config)
    config = codesettings.with_vscode_settings(config.name, config)
  end,
})

-- or per-server
vim.lsp.config(
  'yamlls',
  codesettings.with_vscode_settings('yamlls', {
    settings = {
      yaml = {
        validate = true,
        schemaStore = { enable = true },
      },
    },
  })
)

-- or from a config file under `/lsp/rust-analyzer.lua` in your config directory
return codesettings.with_vscode_settings('rust-analyzer', {
  settings = {
    -- ...
  },
})
```

## API

- `require('codesettings').with_vscode_settings(lsp_name: string, config: table): table`

  - Loads .vscode/settings.json from the project root, extracts the relevant settings based on the LSP's specific schema, and deep-merges it into `config.settings`. Returns the merged config.

- `require('codesettings').load(lsp_name: string|nil): Settings`
  - Loads and parses .vscode/settings.json for the current project. Returns a `Settings` object.
  - if `lsp_name` is specified, filters down to only the relevant properties according to the LSP's schema
  - You can use this if you need fine-grained control beyond `with_vscode_settings`.
  - `Settings` object provides methods:
    - `Settings:get(key)` - returns the value at the specified key, supports dot-separated key paths like `Settings:get('some.sub.property')` to get deeply nested properties
    - `Settings:clear()` - remove all values
    - `Settings:set(key, value)` - again supports dot-separated key paths like `some.sub.property`

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

## How merging works

- The plugin deep-merges plain tables (non-list tables)
- Lists/arrays are replaced, not concatenated
- Your provided `config` is the base; values from VS Code's `settings.json` override or extend it within `config.settings`

In short, VS Code settings take effect while preserving your base config, unless you explicitly override them.

## Acknowledgements

- Some parts of this plugin are heavily based on [folke's neoconf.nvim plugin](https://github.com/folke/neoconf.nvim)
- This plugin bundles [json.lua](https://github.com/actboy168/json.lua), a pure-Lua JSON library for parsing `jsonc` files
