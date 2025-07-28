local function previewLocation(params)
  ---@type grug.far.Context
  local context = params.context

  if not context.state.previewEnabled then
    return
  end

  local resultsList = require('grug-far.render.resultsList')
  local previewUtils = require('grug-far.actions.previewLocationUtils')

  local grugfar_buf = params.buf
  local grugfar_win = vim.fn.bufwinid(grugfar_buf)

  local cursor_row = vim.api.nvim_win_get_cursor(grugfar_win)[1]
  local location = resultsList.getResultLocation(cursor_row - 1, grugfar_buf, context)

  if location == nil then
    return
  end

  if context.state.previewWin and vim.api.nvim_win_is_valid(context.state.previewWin) then
    previewUtils.setupPreviewBuffer({
      context = context,
      location = location,
      grugfar_buf = grugfar_buf,
    })
    return
  end

  local width = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)
  local previewWinConfig = vim.tbl_extend('force', {
    relative = 'win',
    width = width,
    height = math.floor(height / 3),
    focusable = true,
    win = grugfar_win,
    border = 'rounded',
    style = 'minimal',
  }, context.options.previewWindow)

  -- Using 0 or grugfar_buf as the starting buffer for previewWin will trigger the BufLeave event in farBuffer.lua
  -- Since we will replace that buffer with the preview buffer
  local scratch_buf = vim.api.nvim_create_buf(false, true)
  context.state.previewWin = vim.api.nvim_open_win(scratch_buf, false, previewWinConfig)

  previewUtils.setupPreviewBuffer({
    context = context,
    location = location,
    grugfar_buf = grugfar_buf,
  })
end

return previewLocation
