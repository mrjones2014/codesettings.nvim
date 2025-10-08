# codesettings.nvim

Easily read your project's local settings files and merge them into your Neovim 0.11+ native LSP configuration.

## Why

[folke/neoconf.nvim](https://github.com/folke/neoconf.nvim) exists, but it has a hard dependency on
[neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig). With Neovim 0.11+, LSP can be easily configured
with just `vim.lsp.config()` APIs and I did not want to depend on `nvim-lspconfig` in my configuration anymore.

**However**, if you _do_ use `nvim-lspconfig`, this plugin will still work,
since `nvim-lspconfig` now uses `vim.lsp.config()` internally!

This plugin is like `neoconf.nvim`, but simpler, and without a dependency on `nvim-lspconfig`.

## Features

This plugin makes it easy to reuse settings your team already committed to version control for VS Code by
transparently merging the relevant settings from VS Code's settings schema into the LSP `settings` table you pass
to `vim.lsp.config()` (or any way you configure LSP).

- Works with JSONC (JSON with comments, trailing commas)
- Deep-merges into your existing LSP config.settings
- Minimal API: one function you call per server setup, or with a global hook (see example below)
- Optional `jsonls` integration (enabled by default) for schema-based completion of LSP settings
- Supports custom config file names/locations
- See [./schemas/](https://github.com/mrjones2014/codesettings.nvim/tree/master/schemas) for the list of supported LSPs

## Requirements

- Neovim 0.11+ (uses the new `vim.lsp.config()` API)
- A supported settings file in your project root (optional; if missing, your config is returned unchanged).
  By default, the plugin looks for any of:
  - `.vscode/settings.json`
  - `codesettings.json`
  - `lspsettings.json`

## Installation

For some features (namely, `jsonls` integration and `jsonc` filetype handling), you must call `setup()`.

- lazy.nvim (recommended)

```lua
return {
  'mrjones2014/codesettings.nvim',
  -- these are the default settings just set `opts = {}` to use defaults
  opts = {
    ---Look for these config files
    config_file_paths = { '.vscode/settings.json', 'codesettings.json', 'lspsettings.json' },
    ---Integrate with jsonls to provide LSP completion for LSP settings based on schemas
    jsonls_integration = true,
    ---Set filetype to jsonc when opening a file specified by `config_file_paths`,
    ---make sure you have the jsonc tree-sitter parser installed for highlighting
    jsonc_filetype = true,
  },
  -- make sure to load the plugin for `jsonls_integration` and `jsonc_filetype` to work
  event = 'VeryLazy',
}
```

## Quick start

```lua
local codesettings = require('codesettings')

-- global hook
vim.lsp.config('*', {
  before_init = function(_, config)
    config = codesettings.with_local_settings(config.name, config)
  end,
})

-- or per-server
vim.lsp.config(
  'yamlls',
  codesettings.with_local_settings('yamlls', {
    settings = {
      yaml = {
        validate = true,
        schemaStore = { enable = true },
      },
    },
  })
)

-- or from a config file under `/lsp/rust-analyzer.lua` in your config directory
return codesettings.with_local_settings('rust-analyzer', {
  settings = {
    -- ...
  },
})
```

## Commands

- `:Codesettings show` - show the resolved LSP config for each active LSP client; note that this only shows _active_ clients
- `:Codesettings local` - show the resolved local config found in local config files in your project
- `:Codesettings files` - show the config files found in your project
- `:Codesettings edit` - edit or create a local config file based on your configured config file paths
- `:Codesettings health` - check plugin health (alias for `:checkhealth codesettings`)

## API

- `require('codesettings').setup(opts?: CodesettingsConfig)`
  - Initialize the plugin. You only need to call this for `jsonls_integration` and `jsonc_filetype` to work, or to customize the local filepaths to look for. It is _not_ required for your local configs to take effect (unless you customize the local config file paths).

- `require('codesettings').with_local_settings(lsp_name: string, config: table): table`
  - Loads settings from the configured files, extracts relevant settings for the given LSP based on its schema, and deep-merges into `config.settings`. Returns the merged config.

- `require('codesettings').local_settings(lsp_name: string|nil): Settings`
  - Loads and parses the settings file(s) for the current project. Returns a `Settings` object.
  - If `lsp_name` is specified, filters down to only the relevant properties according to the LSP's schema.
  - `Settings` object provides some methods like:
    - `Settings:schema(lsp_name)` - Filter the settings down to only the keys that match the relevant schema e.g. `settings:schema('eslint')`
    - `Settings:merge(settings)` - merge another `Settings` object into this one
    - `Settings:get(key)` - returns the value at the specified key; supports dot-separated key paths like `Settings:get('some.sub.property')`
    - `Settings:get_subtable(key)` - like `Settings:get(key)`, but returns a `Settings` object if the path is a table, otherwise an empty `Settings` object
    - `Settings:clear()` - remove all values
    - `Settings:set(key, value)` - supports dot-separated key paths like `some.sub.property`

Example using `local_settings()` directly:

```lua
local codesettings = require('codesettings')
local eslint_settings = c.local_settings()
  :schema('eslint')
  :merge({
    eslint = {
      codeAction = {
        disableRuleComment = {
          enable = true,
          location = 'sameLine',
        },
      },
    },
  })
  :get('eslint.codeAction') -- get the codeAction subtable
```

## How it finds your settings

- Root discovery uses `vim.fs.root` to search upwards with markers based on your configured config file paths, as well as `.git`
- The plugin checks each path in `config_file_paths` under your project root and uses any that exist

## How merging works

Follows the semantics of `vim.tbl_deep_extend('force', your_config, local_config)`, essentially:

- The plugin deep-merges plain tables (non-list tables)
- Lists/arrays are replaced, not concatenated
- Your provided `config` is the base; values from the settings file override or extend it within `config.settings`

In short, VS Code-style settings take effect while preserving your base config, unless you explicitly override them.

## Acknowledgements

- Some parts of this plugin are heavily based on [folke's neoconf.nvim plugin](https://github.com/folke/neoconf.nvim)
- This plugin bundles [json.lua](https://github.com/actboy168/json.lua), a pure-Lua JSON library for parsing `jsonc` files
