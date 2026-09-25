local AsciiUtils = require("kulala.utils.ascii")
local CMD = require("kulala.cmd")
local CONFIG = require("kulala.config")
local DB = require("kulala.db")
local DOC_PARSER = require("kulala.parser.document")
local Ext_processing = require("kulala.external_processing")
local FS = require("kulala.utils.fs")
local Float = require("kulala.ui.float")
local GLOBALS = require("kulala.globals")
local INLAY = require("kulala.inlay")
local KEYMAPS = require("kulala.config.keymaps")
local Logger = require("kulala.logger")
local REPORT = require("kulala.ui.report")
local UI_utils = require("kulala.ui.utils")
local WINBAR = require("kulala.ui.winbar")
local WS_INPUT = require("kulala.ui.ws_input")

local M = {}

local is_initialized = function()
  return CONFIG.get().initialized
end

local function get_kulala_buffer()
  local buf = vim.fn.bufnr(GLOBALS.UI_ID)
  return buf > 0 and buf
end

local function get_kulala_window()
  local win = vim.fn.win_findbuf(get_kulala_buffer() or -1)[1]
  return win and win
end

---Get the current line number, 1-indexed
local function get_current_line()
  return vim.fn.line(".")
end

local function get_current_response_pos()
  local responses = DB.global_update().responses
  return DB.global_update().current_response_pos or #responses
end

---@return Response
local function get_current_response()
  local responses = DB.global_update().responses
  return responses[get_current_response_pos()]
    or setmetatable({}, {
      __index = function()
        return ""
      end,
    })
end

local function set_current_response(response_pos)
  DB.global_update().current_response_pos = response_pos
end

---Keep the UI on an existing response (e.g. live WebSocket stream) instead of using stale `previous_response_pos`.
---@param db table
---@param response_id? string
---@return boolean positioned when true
local function set_current_response_by_id(db, response_id)
  if not response_id then return false end
  for i = #db.responses, 1, -1 do
    if db.responses[i].id == response_id then
      set_current_response(i)
      return true
    end
  end
  return false
end

---Show the response for a completed request (by id, or the newest entry after `previous_response_pos`).
---@param response_id? string
---@param previous_response_pos? number
M.advance_to_response = function(response_id, previous_response_pos)
  local db = DB.global_update()
  if set_current_response_by_id(db, response_id) then return end
  local prev = previous_response_pos or db.previous_response_pos or 0
  local first_new = math.max(1, prev + 1)
  set_current_response(math.min(first_new, #db.responses))
end

M.close_kulala_buffer = function()
  WS_INPUT.close()
  local buf = get_kulala_buffer()
  if buf then
    pcall(require("kulala.ui.image").clear, buf)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

-- Create an autocmd to delete the buffer when the window is closed
local function set_maps_autocommands(buf)
  CONFIG.get().kulala_keymaps = KEYMAPS.setup_kulala_keymaps(buf)

  vim.api.nvim_create_autocmd("WinClosed", {
    group = vim.api.nvim_create_augroup("kulala_window_closed", { clear = true }),
    buffer = buf,
    callback = function()
      pcall(require("kulala.ui.image").clear, buf)
      if vim.fn.bufexists(buf) > 0 then vim.api.nvim_buf_delete(buf, { force = true }) end
    end,
  })
end

local open_kulala_buffer = function(filetype)
  local config = CONFIG.get()
  local buf = get_kulala_buffer()

  if not buf then
    buf = vim.api.nvim_create_buf(false, true)
    set_maps_autocommands(buf)

    local bo = vim.tbl_extend("keep", config.ui.win_opts.bo or {}, {
      filetype = "kulala_ui",
      buftype = "nofile",
      syntax = filetype,
    })

    vim.iter(bo):each(function(key, value)
      local status, error = pcall(vim.api.nvim_set_option_value, key, value, { buf = buf })
      if not status then Logger.error("Failed to set buffer option `" .. key .. "`: " .. (error or "")) end
    end)

    vim.api.nvim_buf_set_name(buf, GLOBALS.UI_ID)
  end

  local win = get_kulala_window()
  if win then vim.api.nvim_win_set_buf(win, buf) end

  return buf
end

local function is_ws_method(method)
  method = (method or ""):upper()
  return method == "WS" or method == "WSS" or method == "WEBSOCKET"
end

local function ws_prompt_active()
  local WEBSOCKET = require("kulala.cmd.websocket")
  return WEBSOCKET.is_active() and is_ws_method(get_current_response().method)
end

local function restore_readonly_buffer(buf)
  WS_INPUT.close()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false
end

local function lock_buffer_readonly(buf)
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
end

local function set_buffer_contents(buf, contents, filetype)
  local lines = vim.split(contents, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "kulala_ui"
  vim.bo[buf].syntax = filetype
  -- wrap in pcall to avoid errors when treesitter doesn't support the filetype
  pcall(vim.treesitter.start, buf, filetype)
end

---Body view: keep ft as `kulala_ui`, but parse only the response body as json/xml/html
---so treesitter features (e.g. incremental selection) work despite the request summary.
---@param buf integer
---@param lang string
local function apply_body_treesitter(buf, lang)
  if type(lang) ~= "string" or lang == "" or lang == "text" then return end

  -- Make get_parser(buf) resolve to the body language while ft stays kulala_ui.
  vim.treesitter.language.register(lang, "kulala_ui")
  pcall(vim.treesitter.stop, buf)
  pcall(vim.treesitter.start, buf, lang)

  if not CONFIG.get().ui.show_request_summary then return end

  local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok or not parser then return end

  local start_row = 4 -- request summary is always 4 lines when enabled
  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count <= start_row then return end

  -- Range4: { start_row, start_col, end_row, end_col } (end exclusive by row when col is 0)
  pcall(function()
    ---@diagnostic disable-next-line: invisible
    parser:set_included_regions { { { start_row, 0, line_count, 0 } } }
    parser:parse(true)
  end)
end

---Restore default kulala_ui → markdown mapping after body view overrode it.
---@param buf integer
---@param filetype string
local function restore_ui_treesitter(buf, filetype)
  vim.treesitter.language.register("markdown", "kulala_ui")
  pcall(vim.treesitter.stop, buf)
  pcall(vim.treesitter.start, buf, filetype)
end

local function open_kulala_window(buf)
  local config = CONFIG.get()
  local win_config

  local win = get_kulala_window()
  if win then return win end

  local OPENAPI_PANEL = require("kulala.ui.openapi_panel")
  local explorer_win = OPENAPI_PANEL.get_window()
  local request_win = explorer_win and vim.api.nvim_win_is_valid(explorer_win) and explorer_win
    or vim.fn.win_findbuf(DB.get_current_buffer())[1]
    or vim.api.nvim_get_current_win()

  local win_opts = vim.deepcopy(config.ui.win_opts or {})
  local wo = win_opts.wo or {}

  win_opts.bo = nil
  win_opts.wo = nil

  if config.display_mode == "float" then
    local width = math.max(vim.o.columns - 10, 1)
    local height = math.max(vim.o.lines - 10, 1)

    win_config = {
      title = "Kulala",
      title_pos = "center",
      relative = "editor",
      border = "single",
      width = width,
      height = height,
      row = math.floor(((vim.o.lines - height) / 2) - 1),
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal",
      zindex = 50,
    }
  else
    -- INFO:
    -- Legacy options support for split direction
    -- as "vertical" and "horizontal" were previously usued to
    -- indicate split direction.
    -- We map them to the new "split" option values for backward compatibility
    local split = config.split_direction == "vertical" and "right"
      or config.split_direction == "horizontal" and "below"
      or config.split_direction
    win_config = { split = type(split) == "function" and split() or split, win = request_win }
  end

  win_config = vim.tbl_extend("force", win_config, win_opts)
  win = vim.api.nvim_open_win(buf, false, win_config)

  wo = vim.tbl_extend("keep", wo, {
    signcolumn = "yes:1",
    number = false,
    relativenumber = false,
    foldmethod = "indent",
  })

  vim.iter(wo):each(function(key, value)
    local status, error = pcall(vim.api.nvim_set_option_value, key, value, { win = win, scope = "local" })
    if not status then Logger.error("Failed to set window option `" .. key .. "`: " .. (error or "")) end
  end)

  if config.display_mode == "float" then vim.api.nvim_set_current_win(win) end

  return win
end

local function hide_progress()
  local footer = vim.fn.bufnr("kulala://requests_progress")
  if footer > 0 then vim.api.nvim_buf_delete(footer, { force = true }) end
end

local function show_progress()
  if #CMD.queue.tasks == 0 then return hide_progress() end

  local row_offset = vim.fn.bufwinnr("kulala://news_footer") > 0 and 3 or 2
  local message = ("Running.. %s/%s"):format(CMD.queue.done, CMD.queue.total)
  message = message .. " - <C-c> cancels requests (newest first)  "

  Float.create_window_footer(message, {
    buf = get_kulala_buffer(),
    win = get_kulala_window(),
    name = "kulala://requests_progress",
    row_offset = row_offset,
    auto_close = true,
  })
end

local MARKDOWN_VIEWS = {
  verbose = true,
  headers = true,
  headers_body = true,
  script_output = true,
  report = true,
}

local function show(contents, filetype, mode)
  -- Markdown views use plain `markdown` so TS/highlight plugins apply.
  local buf_ft = MARKDOWN_VIEWS[mode] and "markdown" or filetype
  if MARKDOWN_VIEWS[mode] then contents = require("kulala.ui.markdown").normalize_headings(contents) end
  local buf = open_kulala_buffer(buf_ft)

  local Image = require("kulala.ui.image")
  Image.clear(buf)

  restore_readonly_buffer(buf)
  set_buffer_contents(buf, contents, buf_ft)
  if mode ~= "report" then REPORT.set_response_summary(buf) end
  if mode == "body" then
    apply_body_treesitter(buf, buf_ft)
  else
    -- Body view may have remapped kulala_ui → json/xml/html; put markdown back.
    restore_ui_treesitter(buf, buf_ft)
  end
  lock_buffer_readonly(buf)

  local win = open_kulala_window(buf)
  local lnum = mode == "report" and vim.api.nvim_buf_line_count(buf) or 4

  vim.fn.win_execute(win, "normal! " .. lnum .. "G")

  WINBAR.toggle_winbar_tab(buf, win, mode)
  CONFIG.options.default_view = mode

  if mode == "body" and CONFIG.get().ui.show_images ~= false then
    local response = get_current_response()
    local media = response and response._kulala_media_type
    local path = response and response._kulala_image_path
    if
      response
      and response._kulala_body_type == "binary"
      and type(media) == "string"
      and media:lower():find("^image/", 1, false)
      and type(path) == "string"
      and path ~= ""
    then
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(buf) then return end
        -- Blank anchor line below the note so fallback (WezTerm) does not cover the path text.
        restore_readonly_buffer(buf)
        local last = vim.api.nvim_buf_line_count(buf)
        vim.api.nvim_buf_set_lines(buf, last, last, false, { "" })
        lock_buffer_readonly(buf)
        Image.show(buf, path, {
          binary = response._kulala_binary,
          pos = { vim.api.nvim_buf_line_count(buf), 0 },
        })
      end)
    end
  end

  show_progress()
end

---Prefer kulala-core `body.type` / `mediaType` for response body language.
---@param r Response
---@return string ft type to determine syntax highlighting
local function get_ft_from_kulala_core(r)
  return require("kulala.ui.markdown").get_body_ft(r._kulala_media_type, r._kulala_body_type)
end

---Resolve body text and syntax filetype (formatting is done in kulala-core).
---@return string body text to display
---@return string filetype for syntax highlighting
local function format_body()
  local r = get_current_response()
  return r.body, get_ft_from_kulala_core(r)
end

local function ws_live_body_and_ft()
  local WEBSOCKET = require("kulala.cmd.websocket")
  if not WEBSOCKET.response then return "", "text" end
  WEBSOCKET.refresh_display()
  return WEBSOCKET.response.body or "", get_ft_from_kulala_core(WEBSOCKET.response)
end

---Update the live keep-alive HTTP body in place (no full view re-open).
M.refresh_http_stream_body_if_visible = function()
  local HTTP_STREAM = require("kulala.cmd.http_stream")
  local response = HTTP_STREAM.response
  if not response then return end
  if CONFIG.get().default_view ~= "body" then return end
  local current = get_current_response()
  if current.id ~= response.id then return end
  local buf = get_kulala_buffer()
  if not buf then return end
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false
  set_buffer_contents(buf, response.body or "", "text")
  REPORT.set_response_summary(buf)
  lock_buffer_readonly(buf)
  local win = get_kulala_window()
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_set_cursor, win, { vim.api.nvim_buf_line_count(buf), 0 })
  end
end

---Update the live WebSocket body in place (no full view re-open).
M.refresh_ws_body_if_visible = function()
  if not ws_prompt_active() then return end
  local buf = get_kulala_buffer()
  if not buf then return end
  local body, ft = ws_live_body_and_ft()
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false
  set_buffer_contents(buf, body, ft)
  lock_buffer_readonly(buf)
end

---Resolve the WebSocket response table that owns `_ws_messages` / jq source.
---@param response Response
---@return Response|nil
local function ws_filter_response(response)
  if not is_ws_method(response.method) then return nil end
  local WEBSOCKET = require("kulala.cmd.websocket")
  if WEBSOCKET.response and WEBSOCKET.response.id == response.id then return WEBSOCKET.response end
  if type(response._ws_messages) == "table" then return response end
  return nil
end

M.toggle_filter = function()
  local response = get_current_response()
  local cwd = response.file and vim.fn.fnamemodify(response.file, ":h") or nil

  vim.ui.input({ prompt = "JQ Filter: ", default = response.filter or "" }, function(filter)
    if filter == nil then return end

    filter = vim.trim(filter)
    local ws = ws_filter_response(response)
    if ws then
      ws.filter = filter ~= "" and filter or nil
      if response ~= ws then response.filter = ws.filter end
      require("kulala.cmd.websocket").refresh_display(ws)
      if ws_prompt_active() then
        M.refresh_ws_body_if_visible()
      else
        M.show_body()
      end
      return
    end

    if filter == "" then
      response.filter = nil
      if type(response.body_raw) == "string" and response.body_raw ~= "" then
        local KULALA_CORE = require("kulala.cmd.kulala_core_bridge")
        local restored, _ = KULALA_CORE.apply_jq_filter({
          rawBody = response.body_raw,
          filter = ".",
          contentType = response._kulala_media_type or "application/json",
        }, cwd)
        if restored then
          response.body = restored.text
          response.json = vim.json.decode(restored.text) or {}
          if restored.body_type then response._kulala_body_type = restored.body_type end
          if restored.media_type then response._kulala_media_type = restored.media_type end
        else
          response.body = response.body_raw
        end
      end
      M.show_body()
      return
    end

    if Ext_processing.jq(filter, response, cwd) then M.show_body() end
  end)
end

local function parse_report_line(line)
  return tonumber(line:match("^## Line (%d+)") or line:match("^%s*|%s*(%d+)%s*|") or line:match("^%s*(%d+)"))
end

M.jump_to_response = function()
  local WEBSOCKET = require("kulala.cmd.websocket")
  local response = get_current_response()
  local responses = DB.global_update().responses
  local win = vim.fn.bufwinid(get_current_response().buf)

  if CONFIG.get().default_view == "report" then
    local lnum = parse_report_line(vim.api.nvim_get_current_line())
    if not lnum then return end

    local current_name = get_current_response().name
    for i = #responses, 1, -1 do
      if
        responses[i].line == lnum and (not current_name or current_name == "" or responses[i].name == current_name)
      then
        set_current_response(i)
        break
      end
    end

    M.show_body()
  elseif win > 0 then
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, { get_current_response().line, 0 })

    local kulala_win = get_kulala_window()
    if kulala_win and vim.api.nvim_win_is_valid(kulala_win) then
      if WEBSOCKET.is_active() and is_ws_method(response.method) then return end
      if vim.api.nvim_win_get_config(kulala_win).relative == "editor" then vim.api.nvim_win_close(kulala_win, true) end
    end
  end
end

M.show_headers = function()
  local Markdown = require("kulala.ui.markdown")
  show(Markdown.format_headers_view(get_current_response()), "markdown", "headers")
end

M.show_body = function()
  local body, ft
  if ws_prompt_active() then
    body, ft = ws_live_body_and_ft()
  else
    body, ft = format_body()
  end
  show(body, ft, "body")
end

M.show_headers_body = function()
  local Markdown = require("kulala.ui.markdown")
  local r = get_current_response()
  local body, _ = format_body()
  show(Markdown.format_headers_body_view(r, body), "markdown", "headers_body")
end

M.show_verbose = function()
  local r = get_current_response()
  local Verbose = require("kulala.ui.verbose")
  show(Verbose.format(r), "markdown", "verbose")
end

M.show_stats = function()
  local stats = get_current_response().stats
  local diagram

  if stats.timings then
    local diagram_lines = AsciiUtils.get_waterfall_timings(stats.timings)
    diagram = table.concat(diagram_lines, "\n")
  end

  show(diagram or "", "text", "stats")
end

M.show_script_output = function()
  local Markdown = require("kulala.ui.markdown")
  show(Markdown.format_script_output(get_current_response()), "markdown", "script_output")
end

M.show_report = function()
  show(REPORT.generate_requests_report(), "markdown", "report")
end

---Get the panes configured for the winbar and the index of the currently active pane based on the default view.
---@return table panes A list of pane names, current_index number index of the currently active pane
---@return number current_index of the currently active pane
local get_winbar_panes_and_current_index = function()
  local config = CONFIG.get()
  local panes = config.ui.default_winbar_panes
  local current_view = config.default_view
  local current_index
  for idx, pane in ipairs(panes) do
    if pane == current_view then current_index = idx end
  end

  return panes, current_index
end

M.show_previous_tab = function()
  local panes, current_index = get_winbar_panes_and_current_index()
  local previous_index = current_index > 1 and (current_index - 1) or #panes
  local previous_view = panes[previous_index]

  if previous_view then
    M["show_" .. previous_view]()
    CONFIG.options.default_view = previous_view
  end
end

M.show_next_tab = function()
  local panes, current_index = get_winbar_panes_and_current_index()
  local next_index = #panes > current_index and (current_index + 1) or 1
  local next_view = panes[next_index]

  if next_view then
    M["show_" .. next_view]()
    CONFIG.options.default_view = next_view
  end
end

M.show_next = function()
  local responses = DB.global_update().responses
  local current_pos = get_current_response_pos()
  local next = current_pos == #responses and current_pos or current_pos + 1

  set_current_response(next)
  M.open_default_view()
end

M.show_previous = function()
  local current_pos = get_current_response_pos()
  local previous = current_pos <= 1 and current_pos or current_pos - 1

  set_current_response(previous)
  M.open_default_view()
end

M.clear_responses_history = function()
  DB.global_update().responses = {}
  DB.global_update().current_response_pos = 0
  M.open_default_view()
end

M.toggle_headers = function()
  local config = CONFIG.get()
  local default_view = config.default_view

  if default_view == "headers" then
    default_view = "body"
  else
    default_view = "headers"
  end

  config.default_view = default_view
  M.open_default_view()
end

M.toggle_display_mode = function()
  local config = CONFIG.get()
  local display_mode = config.display_mode

  if display_mode == "float" then
    display_mode = "split"
  else
    display_mode = "float"
  end

  config.display_mode = display_mode
  M.close_kulala_buffer()
  M.open_default_view()
end

M.show_help = function()
  local keymaps = CONFIG.get().kulala_keymaps
  local help = vim.split(
    [[
  Kulala Help
  ===========
    ]],
    "\n"
  )

  vim.iter(keymaps):each(function(keymap, value)
    if value then table.insert(help, ("  - %s: `%s`"):format(keymap, value[1])) end
  end)

  Float.create(help, {
    name = "kulala_help",
    ft = "markdown",
    relative = "cursor",
    border = "rounded",
    focusable = true,
    auto_size = true,
    auto_close = true,
    close_keymaps = { "q", "<esc>", "?" },
  })
end

M.show_news = function()
  local news = FS.get_plugin_root_dir() .. "/../../NEWS.md"
  local contents = FS.read_file(news) or "No news found"
  vim.cmd("lcd " .. vim.fs.dirname(news) .. "/docs/docs")

  show(contents, "markdown", "body")
  REPORT.hide_response_summary()

  local footer = vim.fn.bufnr("kulala://news_footer")
  if footer > -1 then vim.api.nvim_buf_delete(footer, { force = true }) end
end

M.scratchpad = function()
  vim.cmd("e " .. GLOBALS.SCRATCHPAD_ID)
  vim.cmd("setlocal filetype=http")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, CONFIG.get().scratchpad_default_contents)
end

M.open_default_view = function()
  local default_view = CONFIG.get().default_view
  local open_view = type(default_view) == "function" and default_view or M["show_" .. default_view]

  local status, errors = xpcall(function()
    if open_view then open_view(get_current_response()) end
  end, debug.traceback)

  if not status then Logger.error("Errors displaying response: " .. (errors or ""), 1) end
end

M.open = function()
  M:open_all(vim.api.nvim_get_mode().mode == "V" and 0 or get_current_line())
end

M.open_all = function(_, line_nr)
  if not is_initialized() then return Logger.error("Kulala setup is not initialized. Check the config.") end

  line_nr = line_nr or 0
  local db = DB.global_update()
  local status, elapsed_ms

  local buf = DB.set_current_buffer()
  db.previous_response_pos = #db.responses
  INLAY.clear()

  CMD.run_parser(nil, line_nr, function(success, duration, icon_linenr, response_id)
    if success then
      elapsed_ms = UI_utils.pretty_ms(duration)
      status = "done"
    else
      status = success == nil and "loading" or "error"
    end

    if not set_current_response_by_id(db, response_id) then
      local first_new = math.max(1, (db.previous_response_pos or 0) + 1)
      set_current_response(math.min(first_new, #db.responses))
    end

    INLAY.show(buf, status, icon_linenr, elapsed_ms)
    M.open_default_view()

    return true
  end)
end

M.jump_next = function()
  local reqs = DOC_PARSER.get_document()
  local next = DOC_PARSER.get_next_request(reqs)
  if next then vim.api.nvim_win_set_cursor(0, { next.start_line, 0 }) end
end

M.jump_prev = function()
  local reqs = DOC_PARSER.get_document()
  local prev = DOC_PARSER.get_previous_request(reqs)
  if prev then vim.api.nvim_win_set_cursor(0, { prev.start_line, 0 }) end
end

M.keymap_enter = function()
  M.jump_to_response()
end

M.interrupt_requests = function()
  local current = get_current_response()
  if current and current.method == "WS" then return require("kulala.cmd.websocket").close() end

  local acted = CMD.queue:interrupt_progressive()
  if not acted then return end

  INLAY.clear("kulala.loading")
  if #CMD.queue.tasks == 0 and CMD.queue.status ~= "running" then hide_progress() end
end

M.replay = function()
  local last_request = DB.global_find_unique("replay")
  if not last_request then return Logger.warn("No request to replay") end

  local run_opts = CMD.replay_run_opts(last_request)
  if not run_opts then
    return Logger.error("Cannot replay: missing HTTP file content for " .. (last_request.file or "unknown"))
  end

  local db = DB.global_update()
  local line = last_request.show_icon_line_number or last_request.start_line
  local buf = DB.get_current_buffer()
  local status, elapsed_ms

  db.previous_response_pos = #db.responses
  INLAY.clear()

  -- Re-parse the HTTP buffer and send full document content to kulala-core (all scripts, vars, KULALA_SHARED).
  CMD.run_parser(nil, line, function(success, duration, icon_linenr, response_id)
    if success then
      elapsed_ms = UI_utils.pretty_ms(duration)
      status = "done"
    else
      status = success == nil and "loading" or "error"
    end

    if not set_current_response_by_id(db, response_id) then set_current_response(#db.responses) end

    INLAY.show(buf, status, icon_linenr or INLAY.icon_line_for_request(last_request), elapsed_ms)
    M.open_default_view()

    return true
  end, run_opts)
end

M.close = function()
  M.close_kulala_buffer()

  local ext = vim.fn.expand("%:e")
  if ext == "http" or ext == "rest" then vim.api.nvim_buf_delete(vim.fn.bufnr(), {}) end
end

M.copy = function()
  local Bridge = require("kulala.cmd.kulala_core_bridge")

  if not Bridge.enabled() then return Logger.error("kulala-core is not available") end

  local curl, err = Bridge.to_curl_at_cursor(nil, GLOBALS.NAME .. "/" .. GLOBALS.VERSION)
  if not curl then
    if err and Bridge.is_preview_unsupported_err(err) then return Logger.warn(err) end
    return Logger.error(err or "Failed to copy request as curl")
  end

  vim.fn.setreg("+", curl)
  Logger.info("Copied to clipboard")
end

M.from_curl = function()
  local clipboard = vim.fn.getreg("+")
  local Bridge = require("kulala.cmd.kulala_core_bridge")
  local lines, err = Bridge.from_curl(clipboard)
  if not lines then return Logger.error(err or "kulala-core from_curl failed") end
  vim.api.nvim_put(lines, "l", false, false)
end

M.inspect = function()
  local Bridge = require("kulala.cmd.kulala_core_bridge")
  local content, err = Bridge.inspect_request_at_cursor()
  if not content then
    if err and Bridge.is_preview_unsupported_err(err) then return Logger.warn(err) end
    return Logger.error(err or "kulala-core inspect_request failed")
  end

  if not content or #content == 0 then return end

  Float.create(content, {
    name = "kulala://inspect",
    ft = "http",
    relative = "cursor",
    focusable = true,
    border = "rounded",
    auto_size = true,
    close_keymaps = { "q", "<esc>" },
  })
end

M.get_kulala_buffer = get_kulala_buffer
M.get_kulala_window = get_kulala_window
M.get_current_response = get_current_response
M.get_current_response_pos = get_current_response_pos
M.open_ws_message = WS_INPUT.on_send_keymap

return M
