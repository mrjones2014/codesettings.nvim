---@type table<string, string>
---A mapping of LSP names to the subtable that should be passed to the vim.lsp.config() schema.
---In a few cases this varies slightly from the VS Code extension schema, e.g. for `eslint`,
---the VS Code properties all start with `eslint.*` but the LSP expects to be passed only the subtable.
return {
  -- see https://github.com/mrjones2014/codesettings.nvim/issues/7
  eslint = 'eslint',
}
