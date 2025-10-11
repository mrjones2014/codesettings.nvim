---@class CodesettingsView
local M = {}

---Show given string in a centered floating window, with q and esc bound to close
---@param str string|string[]
function M.show(str)
  local buf = vim.api.nvim_create_buf(false, false)
  local vpad = 6
  local hpad = 20

  local lines = {}
  if type(str) == 'table' then
    lines = str
  else
    for s in str:gmatch('([^\n]*)\n?') do
      table.insert(lines, s)
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)

  local opts = {
    relative = 'editor',
    width = math.min(vim.o.columns - hpad * 2, 150),
    height = math.min(vim.o.lines - vpad * 2, 50),
    style = 'minimal',
    border = 'single',
  }

  opts.row = (vim.o.lines - opts.height) / 2
  opts.col = (vim.o.columns - opts.width) / 2

  local win = vim.api.nvim_open_win(buf, true, opts)

  local buf_scope = { buf = buf }
  vim.api.nvim_set_option_value('filetype', 'markdown', buf_scope)
  vim.api.nvim_set_option_value('buftype', 'nofile', buf_scope)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', buf_scope)
  vim.api.nvim_set_option_value('modifiable', false, buf_scope)

  local win_scope = { win = win }
  vim.api.nvim_set_option_value('conceallevel', 3, win_scope)
  vim.api.nvim_set_option_value('spell', false, win_scope)
  vim.api.nvim_set_option_value('wrap', true, win_scope)

  local function close()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set('n', '<ESC>', close, { buffer = buf, nowait = true })
  vim.keymap.set('n', 'q', close, { buffer = buf, nowait = true })
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufLeave', 'BufHidden' }, {
    once = true,
    buffer = buf,
    callback = close,
  })
end

return M
