---@diagnostic disable: unused-local, unused-function

---@class grug.far.SetupPreviewBufferParams
---@field context grug.far.Context
---@field location grug.far.ResultLocation
---@field grugfar_buf integer

---@class grug.far.PreviewLocationUtils
local M = {}

---@param filename string
local function getPreviewBuffer(filename)
  local utils = require('grug-far.utils')
  local buf_name = 'grug-far-preview:///' .. filename
  local bufnr = vim.fn.bufnr(buf_name)

  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, buf_name)

    local lines = utils.readFileLinesSync(filename)

    if lines then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
      local ft = utils.getFileType(filename)
      if ft then
        local lang = vim.treesitter.language.get_lang(ft)
        if not pcall(vim.treesitter.start, bufnr, lang) then
          vim.bo[bufnr].syntax = ft
        end
      end

      vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = bufnr })
      vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })
    end
  end

  return bufnr
end

---@param params grug.far.SetupPreviewBufferParams
---@param preview_buf integer
local function addMatchHighlighting(params, preview_buf)
  -- Clear any existing highlights first
  vim.api.nvim_buf_clear_namespace(preview_buf, 0, 0, -1)

  if params.location.lnum then
    -- If we have match column information, highlight the specific match
    if params.location.col and params.location.text then
      local search_inputs = require('grug-far.inputs').getValues(params.context, params.grugfar_buf)
      local search_pattern = search_inputs.search

      if search_pattern and #search_pattern > 0 then
        -- Try to find the match in the text to determine its length
        local line_text = params.location.text or ''
        local match_start, match_end = string.find(line_text, search_pattern, 1, true)

        if match_start then
          -- Highlight the specific match with a more prominent color
          vim.api.nvim_buf_add_highlight(
            preview_buf,
            0,
            'GrugFarPreview',
            params.location.lnum - 1,
            match_start - 1,
            match_end
          )
        else
          -- Fallback: try regex search if literal search failed
          local ok, match_start_regex, match_end_regex =
            pcall(string.find, line_text, search_pattern)
          if ok and match_start_regex then
            vim.api.nvim_buf_add_highlight(
              preview_buf,
              0,
              'GrugFarPreview',
              params.location.lnum - 1,
              match_start_regex - 1,
              match_end_regex
            )
          end
        end
      end
    end
  end
end

---@param params grug.far.SetupPreviewBufferParams
---@param preview_buf integer
local function setupKeymaps(params, preview_buf)
  local utils = require('grug-far.utils')
  local keymaps = params.context.options.keymaps

  local function focusGrugfarWin()
    local grugfar_win = vim.fn.bufwinid(params.grugfar_buf)
    if grugfar_win ~= -1 then
      vim.api.nvim_set_current_win(grugfar_win)
    end
    return grugfar_win
  end

  utils.setBufKeymap(preview_buf, 'Close preview window', { n = 'q' }, function()
    focusGrugfarWin()

    M.closePreviewWindow(params.context)
  end)

  utils.setBufKeymap(preview_buf, 'Close preview and open location', { n = '<CR>' }, function()
    local grugfar_win = focusGrugfarWin()

    M.closePreviewWindow(params.context)

    require('grug-far.actions.gotoLocation')({
      buf = params.grugfar_buf,
      context = params.context,
    })
  end)

  local toggle_keymap = keymaps.smartToggleFocus
  if toggle_keymap then
    utils.setBufKeymap(
      preview_buf,
      'Toggle focus back to grug-far window',
      toggle_keymap,
      function()
        require('grug-far').get_instance(params.grugfar_buf):toggle_preview_focus()
      end
    )
  end
end

---@param context grug.far.Context
function M.closePreviewWindow(context)
  if context.state.previewWin and vim.api.nvim_win_is_valid(context.state.previewWin) then
    vim.api.nvim_win_close(context.state.previewWin, true)
  end
  context.state.previewWin = nil
end

---@param params grug.far.SetupPreviewBufferParams
function M.setupPreviewBuffer(params)
  local preview_win = params.context.state.previewWin
  local grugfar_win = vim.fn.bufwinid(params.grugfar_buf)
  local preview_buf = getPreviewBuffer(params.location.filename)

  vim.api.nvim_win_set_buf(preview_win, preview_buf)
  vim.api.nvim_win_set_cursor(preview_win, { params.location.lnum, params.location.col - 1 })

  addMatchHighlighting(params, preview_buf)
  setupKeymaps(params, preview_buf)
end

return M
