# ⚙️ codesettings.nvim

Easily read your project's local settings files and merge them into your Neovim 0.11+ native LSP configuration.

This plugin makes it easy to reuse settings your team already committed to version control for VS Code by
providing an API to merge the relevant settings from VS Code's settings schema into the LSP `settings` table you pass
to `vim.lsp.config()` (or any way you configure LSP).

## Requirements

- Neovim 0.11+ (uses the new `vim.lsp.config()` API)
- A JSON(C) file in your project root with LSP settings (optional; if missing, your config is returned unchanged).
  Paths are configurable, but by default, the plugin looks for any of:
  - `.vscode/settings.json`
  - `codesettings.json`
  - `lspsettings.json`

## Features

- Minimal API: one function you call per server setup, or with a global hook (see example below)
- `jsonls` integration for schema-based completion of LSP settings in JSON(C) configuration files
- `jsonc` filetype for local config files
- Supports custom config file names/locations
- See [./schemas/](https://github.com/mrjones2014/codesettings.nvim/tree/master/schemas) for the list of supported LSPs
- Supports mixed nested and dotted key paths, for example, this project's `codesettings.json` looks like:

```jsonc
{
  "Lua": {
    "runtime.version": "LuaJIT",
    "workspace": {
      "library": ["${3rd}/luassert/library", "${addons}/busted/library"],
      "checkThirdParty": false,
    },
    "diagnostics.globals": ["vim", "setup", "teardown"],
  },
}
```

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
    ---Choose the default merge behavior
    default_merge_opts = {
      --- How to merge lists; 'replace' (default), 'append', or 'prepend'
      list_behavior = 'append',
    },
  },
  -- I recommend loading on these filetype so that the
  -- jsonls integration and jsonc filetype setup works
  ft = { 'json', 'jsonc' },
}
```

## Quick start

**Recommended setup:** If you don't use `before_init` for anything else, you can use it as a global hook
to look for local config files for all LSPs:

```lua
vim.lsp.config('*', {
  before_init = function(_, config)
    local codesettings = require('codesettings')
    config = codesettings.with_local_settings(config.name, config)
  end,
})
```

**Alternatively,** you can configure it on a per-server basis.

```lua
-- you can also still use `before_init` here
-- if you want codesettings to be `require`d
-- lazily
local codesettings = require('codesettings')
vim.lsp.config(
  'yamlls',
  codesettings.with_local_settings('yamlls', {
    settings = {
      yaml = {
        validate = true,
        schemaStore = { enable = true },
      },
    },
  }, {
    -- you can also pass custom merge opts on a per-server basis
    list_behavior = 'replace',
  })
)

-- or from a config file under `/lsp/rust-analyzer.lua` in your config directory.
-- if you use rustaceanvim to configure rust-analyzer, see the `rustaceanvim` section below
return codesettings.with_local_settings('rust-analyzer', {
  settings = {
    -- ...
  },
})
```

### Rustaceanvim

The `before_init` global hook does not work if you use [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)
to configure `rust-analyzer`, however you can still use `codesettings.nvim` to merge local settings.

`rustaceanvim` loads VS Code settings by default, but your global settings override the local ones; `codesettings.nvim`
does the opposite. Here's how I configure `rustaceanvim` in my own setup:

```lua
return {
  'mrcjkb/rustaceanvim',
  ft = 'rust',
  version = '^6',
  dependencies = { 'mrjones2014/codesettings.nvim' },
  init = function()
    vim.g.rustaceanvim = {
      -- the rest of your settings go here...

      -- I want VS Code settings to override my settings,
      -- not the other way around, so use codesettings.nvim
      -- instead of rustaceanvim's built-in vscode settings loader
      load_vscode_settings = false,
      -- the global hook doesn't work when configuring rust-analyzer with rustaceanvim
      settings = function(params, config)
        return params, require('codesettings').with_local_settings('rust-analyzer', config)
      end,
      default_settings = {
        ['rust-analyzer'] = {
          -- your global LSP settings go here
        },
      },
    }
  end,
}
```

## Commands

- `:Codesettings show` - show the resolved LSP config for each active LSP client; note that this only shows _active_ clients
- `:Codesettings local` - show the resolved local config found in local config files in your project
- `:Codesettings files` - show the config files found in your project
- `:Codesettings edit` - edit or create a local config file based on your configured config file paths
- `:Codesettings health` - check plugin health (alias for `:checkhealth codesettings`)

## API

- `require('codesettings').setup(opts?: CodesettingsConfig)`
  - Initialize the plugin. You only need to call this for `jsonls_integration` and `jsonc_filetype` to work, or to customize the local filepaths to look for. It is _not_ required for your local configs to take effect, unless you wish to use non-default plugin configuration.

- `require('codesettings').with_local_settings(lsp_name: string, config: table): table`
  - Loads settings from the configured files, extracts relevant settings for the given LSP based on its schema, and deep-merges into `config.settings`. Returns the merged config.

- `require('codesettings').local_settings(lsp_name: string|nil): Settings`
  - Loads and parses the settings file(s) for the current project. Returns a `Settings` object.
  - If `lsp_name` is specified, filters down to only the relevant properties according to the LSP's schema.
  - `Settings` object provides some methods like:
    - `Settings:schema(lsp_name)` - Filter the settings down to only the keys that match the relevant schema e.g. `settings:schema('eslint')`
    - `Settings:merge(settings, key, merge_opts)` - merge another `Settings` object into this one, optionally specify a sub-key to merge, and control merge behavior with the 2nd and 3rd parameter, respectively
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
- List/array values are appended by default; you can change this behavior in configuration or through the API
- Your provided `config` is the base; values from the settings file override or extend it within `config.settings`

## Comparison with neoconf.nvim

|                                            | `codesettings.nvim`                                      | `neoconf.nvim`                           |
| ------------------------------------------ | -------------------------------------------------------- | ---------------------------------------- |
| Minimum Neovim version                     | Neovim >= 0.11.0                                         | Neovim >= 0.7.2                          |
| Depends on `nvim-lspconfig`                | No (but will still work with it if you choose to use it) | Yes                                      |
| Supports mixed nested and dotted key paths | Yes                                                      | No                                       |
| Customizable list value merging behavior   | Yes                                                      | No                                       |
| `jsonls` integration                       | Yes                                                      | Yes                                      |
| `jsonc` filetype support                   | Yes                                                      | Yes                                      |
| `setup()` required                         | Only for some editor integration features                | Yes                                      |
| Loading settings                           | API call                                                 | Automatic through `nvim-lspconfig` hooks |

The tl;dr: is if you wish to use `nvim-lspconfig`, then `neoconf.nvim` is more automatic, but if you want to get rid of `nvim-lspconfig`
and just use `vim.lsp.config()` APIs, then `codesettings.nvim` provides an API to load local project settings for you.

## Acknowledgements

This project would not exist without the hard work of some other open source projects!

- Some parts of this plugin are based on [folke's neoconf.nvim plugin](https://github.com/folke/neoconf.nvim)
- This plugin bundles [json.lua](https://github.com/actboy168/json.lua), a pure-Lua JSON library for parsing `jsonc` files
