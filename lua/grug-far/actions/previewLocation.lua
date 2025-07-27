local resultsList = require('grug-far.render.resultsList')
local utils = require('grug-far.utils')

local function previewLocation(params)
  local grugfar_buf = params.buf
  local grugfar_win = vim.fn.bufwinid(grugfar_buf)

  local cursor_row = vim.api.nvim_win_get_cursor(grugfar_win)[1]
  local context = params.context
  local location = resultsList.getResultLocation(cursor_row - 1, grugfar_buf, context)

  if location == nil then
    return
  end

  local width = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)
  local previewWinConfig = vim.tbl_extend('force', {
    relative = 'win',
    width = width,
    height = math.floor(height / 3),
    bufpos = { vim.fn.line('.') - 1, vim.fn.col('.') },
    focusable = true,
    win = grugfar_win,
    border = 'rounded',
    style = 'minimal',
  }, context.options.previewWindow)

  local preview_win = vim.api.nvim_open_win(0, true, previewWinConfig)
  local file_buf = vim.fn.bufnr(location.filename)

  if file_buf == -1 then
    vim.fn.win_execute(preview_win, 'e ' .. utils.escape_path_for_cmd(location.filename), true)
  else
    vim.api.nvim_win_set_buf(preview_win, file_buf)
  end

  vim.api.nvim_win_set_cursor(preview_win, { location.lnum, location.col - 1 })

  local preview_buf = vim.fn.winbufnr(preview_win)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = preview_buf })
end

return previewLocation
