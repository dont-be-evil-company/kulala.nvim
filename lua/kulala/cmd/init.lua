---@diagnostic disable: inject-field
local Api = require("kulala.api")
local CONFIG = require("kulala.config")
local DB = require("kulala.db")
local DOCUMENT_PARSER = require("kulala.parser.document")
local ENV_PARSER = require("kulala.parser.env")
local EXT_PROCESSING = require("kulala.external_processing")
local FS = require("kulala.utils.fs")
local GLOBALS = require("kulala.globals")
local INLAY = require("kulala.inlay")
local INT_PROCESSING = require("kulala.internal_processing")
local Json = require("kulala.utils.json")
local KULALA_CORE = require("kulala.cmd.kulala_core_bridge")
local Logger = require("kulala.logger")
local Markdown = require("kulala.ui.markdown")
local SCRIPT_CONSOLE_NOTIFY = require("kulala.script_console_notify")
local UI_utils = require("kulala.ui.utils")

local M = {}

local queue = {
  reset = function(self)
    self.status = "idle" -- "idle"|"running"|"paused"
    self.tasks = {}
    self.previous_task = nil
    self.total = 0 -- total number of tasks added to the queue
    self.done = 0 -- number of tasks done

    return self
  end,
  pause = function(self)
    self.status = "paused"
  end,
  resume = function(self)
    self.status = "idle"
    table.insert(self.tasks, 1, self.previous_task)
    self:run_next()
  end,
  ---Drop the last queued task (newest pending first).
  ---@return boolean cancelled
  cancel_last_pending = function(self)
    if #self.tasks == 0 then return false end
    table.remove(self.tasks)
    self.total = math.max(self.done, self.total - 1)
    return true
  end,
  ---Kill the in-flight kulala-core subprocess for the currently running task.
  ---@return boolean interrupted
  interrupt_running = function(self)
    if self.status ~= "running" then return false end
    KULALA_CORE.interrupt_active()
    return true
  end,
  ---One Ctrl+C step: cancel the newest still-pending request, or stop the active one.
  ---Order for requests 1..N: pending N, N-1, … then the running request (1 if nothing else left).
  ---@return boolean acted
  interrupt_progressive = function(self)
    if self:cancel_last_pending() then return true end
    return self:interrupt_running()
  end,
}

M.queue = queue:reset()

local process_request

---Add task to the queue
---@param self table
---@param data? any additional data to be passed to the task function
---@param fn function task function
---@param pos? number position in the queue (default: end of the queue)
---@param callback? function callback function to be called after the task is done
function queue.add(self, data, fn, pos, callback)
  pos = pos or #self.tasks + 1
  self.total = self.total + 1
  table.insert(self.tasks, pos, { fn = fn, callback = callback, data = data })
end

function queue.run_next(self)
  if #self.tasks == 0 or self.status == "paused" then return end

  local task = table.remove(self.tasks, 1)

  self.previous_task = task
  self.status = "running"

  vim.schedule(function()
    local status, errors = xpcall(task.fn, debug.traceback)

    local cb_status, cb_errors = true, ""
    if task.callback then
      cb_status, cb_errors = xpcall(task.callback, debug.traceback)
    end

    if not (status and cb_status) then
      self:reset()
      Logger.error(("Errors running a scheduled task: %s %s"):format(errors or "", cb_errors), 1, { report = true })
    end

    self.done = self.done + 1
  end)
end

local function initialize()
  FS.delete_cached_files(true)
end

---Fields set only after a run; must not be reused on replay.
local REPLAY_RUNTIME_FIELDS = {
  "_kulala_sent_url",
  "_kulala_final_url",
  "_kulala_script_console",
  "_kulala_limit_line",
  "_kulala_replay_run_opts",
  "_kulala_batch_targets",
  "body_computed",
}

---@param request DocumentRequest
local function strip_replay_runtime_fields(request)
  for _, key in ipairs(REPLAY_RUNTIME_FIELDS) do
    request[key] = nil
  end
end

---Persist last request for `require("kulala").replay()` (kulala-core path skips request.lua parse).
---@param request DocumentRequest|nil
local function save_replay_snapshot(request)
  if type(request) ~= "table" then return end
  if not request._kulala_core then return end
  local snapshot = vim.deepcopy(request)
  strip_replay_runtime_fields(snapshot)
  snapshot.show_icon_line_number = request.show_icon_line_number or request.start_line
  DB.global_update().replay = snapshot
end

---@class KulalaCoreRunOpts
---@field content? string document text (defaults to current buffer)
---@field cwd? string working directory for kulala-core
---@field filepath? string absolute path for kulala-core (imports, external scripts)
---@field limit? table[] kulala-core run limit (cursorPosition or name)

---Line for kulala-core `cursorPosition` must fall inside the parsed block (`findBlockAtCursor`).
---Prefer `_kulala_limit_line` when the parser was scoped to a line; else the real cursor when this
---window is the HTTP buffer and `line(".")` is in `[start_line, end_line]`.
---Otherwise fall back to `show_icon_line_number` (the `###` delimiter line): replay, run-all, or
---another window may have no meaningful cursor on this file, but that line still lies in the block.
---@param parsed_request DocumentRequest
---@return number
local function kulala_core_cursor_line(parsed_request)
  local ln = parsed_request._kulala_limit_line
  parsed_request._kulala_limit_line = nil
  local lo = parsed_request.start_line or 1
  local hi = parsed_request.end_line or 2147483647

  if type(ln) == "number" and ln > 0 and ln >= lo and ln <= hi then return ln end

  if vim.api.nvim_get_current_buf() == DB.get_current_buffer() then
    local cur = vim.fn.line(".")
    if cur >= lo and cur <= hi then return cur end
  end

  return parsed_request.show_icon_line_number or 1
end

---@param parsed_request DocumentRequest
---@param run_opts KulalaCoreRunOpts|nil
---@return table payload
---@return string|nil cwd
local function build_kulala_core_run_payload(parsed_request, run_opts)
  run_opts = run_opts or {}
  local buf = DB.get_current_buffer()
  local content = run_opts.content
  if type(content) ~= "string" then content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") end

  local http_filepath, resolved_cwd = KULALA_CORE.resolve_document_paths(buf, parsed_request.file)
  local cwd = run_opts.cwd or resolved_cwd

  local limit = run_opts.limit
  if not limit then
    limit = {
      {
        filter = "cursorPosition",
        line = kulala_core_cursor_line(parsed_request),
        column = math.max(1, vim.fn.col(".")),
      },
    }
  end

  local response_format = CONFIG.get().response_format or {}
  local run_payload = {
    content = content,
    env = ENV_PARSER.get_current_env() or "default",
    limit = limit,
    responseFormat = {
      indent = response_format.indent,
      expand_tabs = response_format.expand_tabs,
      sort_keys = response_format.sort_keys,
    },
  }
  local filepath = run_opts.filepath or http_filepath
  if filepath then run_payload.filepath = filepath end

  return run_payload, cwd
end

---@param file string|nil
---@return number|nil buf
local function ensure_http_buffer(file)
  if type(file) ~= "string" or file == "" then return nil end
  local buf = vim.fn.bufnr(file)
  if buf >= 0 then return buf end
  if vim.fn.filereadable(file) ~= 1 then return nil end
  buf = vim.fn.bufadd(file)
  if buf >= 0 then vim.fn.bufload(buf) end
  return buf >= 0 and buf or nil
end

---Build run context to replay a stored request from its source .http file.
---@param request DocumentRequest
---@return KulalaCoreRunOpts|nil
function M.replay_run_opts(request)
  if type(request) ~= "table" then return nil end
  request._kulala_core = request._kulala_core ~= false
  strip_replay_runtime_fields(request)

  local file = request.file
  local buf = ensure_http_buffer(file)
  if buf then DB.set_current_buffer(buf) end

  local content
  local filepath
  if buf then
    content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    local bufname = vim.api.nvim_buf_get_name(buf)
    if type(bufname) == "string" and bufname ~= "" then filepath = vim.fn.fnamemodify(bufname, ":p") end
  elseif type(file) == "string" and file ~= "" and vim.fn.filereadable(file) == 1 then
    content = table.concat(vim.fn.readfile(file), "\n")
    filepath = vim.fn.fnamemodify(file, ":p")
  end
  if not content or content == "" then return nil end

  local cwd = filepath and vim.fn.fnamemodify(filepath, ":h") or nil

  local limit
  if type(request._kulala_block_name) == "string" and request._kulala_block_name ~= "" then
    limit = { { filter = "name", name = request._kulala_block_name } }
  else
    local line = request.show_icon_line_number or request.start_line or 1
    limit = { { filter = "cursorPosition", line = line, column = 1 } }
  end

  return { content = content, cwd = cwd, filepath = filepath, limit = limit }
end

local function process_metadata(request, response)
  local int_meta_processors = {
    ["env-json-key"] = "env_json_key",
    ["env-header-key"] = "env_header_key",
  }

  local ext_meta_processors = {
    ["stdin-cmd"] = "stdin_cmd",
    ["env-stdin-cmd"] = "env_stdin_cmd",
    ["jq"] = "jq",
  }

  local processor
  for _, metadata in ipairs(request.metadata) do
    processor = int_meta_processors[metadata.name]
    if processor then INT_PROCESSING[processor](metadata.value, response) end

    processor = ext_meta_processors[metadata.name]
    if processor then EXT_PROCESSING[processor](metadata.value, response) end
  end
end

local function process_internal(result)
  INT_PROCESSING.redirect_response_body_to_file(result.redirect_response_body_to_files)
end

---@param item table|nil
---@return table|nil
local function kulala_core_script_console(item)
  if type(item) ~= "table" then return nil end
  return item.scriptConsole or item.script_console
end

---@param request_status table|nil
---@param request DocumentRequest|nil
---@param response Response
local function apply_script_console_to_response(request_status, request, response)
  local lines = (request_status and request_status._kulala_script_console)
    or (request and request._kulala_script_console)
  if type(lines) ~= "table" then
    response.script_console = nil
    response.script_pre_output = ""
    response.script_post_output = ""
    return
  end
  response.script_console = lines
  SCRIPT_CONSOLE_NOTIFY.emit(lines)
  local request_file = (response.file and response.file ~= "") and response.file
    or (response.buf_name and response.buf_name ~= "") and response.buf_name
    or nil
  response.script_pre_output, response.script_post_output = Markdown.split_script_console(lines, request_file)
  if request_status then request_status._kulala_script_console = nil end
  if request then request._kulala_script_console = nil end
end

local function process_external(request_status, request, response)
  apply_script_console_to_response(request_status, request, response)
  response.assert_output = {}

  local replay = request.environment and request.environment["__replay_request"] == "true"
  if request.environment then request.environment["__replay_request"] = nil end

  return replay and "replay"
end

local function process_api()
  Api.trigger("after_next_request")
  Api.trigger("after_request")
end

local function add_content_type_header(response, content_type)
  response.headers = response.headers .. "Content-Type: " .. content_type .. "\n\n"
  response.headers_tbl = INT_PROCESSING.get_headers()
end

local function modify_grpc_response(response)
  if response.method ~= "GRPC" then return response end

  local content_type = response.errors == "" and "application/json" or "kulala/grpc_error"
  add_content_type_header(response, content_type)
  return response
end

local function set_request_stats(response)
  response.stats = Json.parse(tostring(response.stats)) or {}
  response.response_code = tonumber(response.stats.response_code) or response.code
  -- kulala-core already applies # @kulala-expect-status-code; do not re-fail 4xx/5xx here.
  response.status = response.code == 0
  response.assert_status = response.status and response.assert_status

  return response
end

local function inject_payload(errors, request)
  local lines = vim.split(errors, "\n")
  local lnum

  for i, line in ipairs(lines) do
    if line:find("^>") and not lines[i + 1]:find("^>") then
      lnum = i
      break
    end
  end

  lnum = lnum or #lines

  local body = FS.read_file(request.body_temp_file) or ""
  body = #body > 1000 and request.body or body

  if #vim.trim(body) > 0 then table.insert(lines, lnum + 1, "> Payload:\n\n" .. body .. "\n") end

  return table.concat(lines, "\n")
end

---Stable id for a request/response pair (must match between save_response and live WebSocket state).
---@param buf number
---@param request DocumentRequest
---@return string
local function request_response_id(buf, request)
  local line = request.show_icon_line_number or 0
  local id = buf .. ":" .. line
  if type(request._kulala_block_name) == "string" and request._kulala_block_name ~= "" then
    id = id .. ":" .. request._kulala_block_name
  end
  return id
end

local function truncate_body(response)
  if response._kulala_body_type == "binary" then
    if type(response._kulala_binary) == "table" and type(response._kulala_binary.note) == "string" then
      local note = response._kulala_binary.note
      if response._kulala_image_path then note = note .. "\nPath: " .. response._kulala_image_path end
      return note
    end
    return response.body_raw ~= "" and response.body_raw or "Binary response body"
  end

  local max_size = CONFIG.get().ui.max_response_size

  if vim.fn.getfsize(GLOBALS.BODY_FILE) > max_size then
    add_content_type_header(response, "text/plain")
    return "The size of response is > " .. max_size / 1024 .. "Kb.\nPath to response: " .. GLOBALS.BODY_FILE
  else
    return FS.read_file(GLOBALS.BODY_FILE) or ""
  end
end

local function save_response(request_status, parsed_request)
  local buf = DB.get_current_buffer()
  local line = parsed_request.show_icon_line_number or 0
  local id = request_response_id(buf, parsed_request)
  local body_from_snapshot = type(request_status._kulala_body_snapshot) == "string"
  local raw_from_snapshot = type(request_status._kulala_raw_body_snapshot) == "string"
  local headers_from_snapshot = type(request_status._kulala_headers_snapshot) == "string"

  local responses = DB.global_update().responses
  for i = #responses, 1, -1 do
    if responses[i].id == id and responses[i]._kulala_http_stream then
      table.remove(responses, i)
      break
    end
  end
  if #responses > 0 and responses[#responses].id == id and responses[#responses].code == -1 then
    -- Drop unfinished chunked response for the same request id.
    table.remove(responses)
  end

  local method_upper = (parsed_request.method or ""):upper()
  if method_upper == "WS" or method_upper == "WSS" or method_upper == "WEBSOCKET" then
    local ws_response = require("kulala.cmd.websocket").response
    if ws_response and ws_response.id == id then
      local existing = ws_response
      for i = #responses, 1, -1 do
        if responses[i].id == id then
          existing = responses[i]
          break
        end
      end
      existing.code = request_status.code or -1
      existing.duration = request_status.duration or existing.duration
      existing.errors = request_status.errors or existing.errors
      existing.stats = request_status.stdout or existing.stats
      if ws_response.body_raw ~= "" then
        existing.body_raw = ws_response.body_raw
      elseif existing.body_raw == "" then
        existing.body_raw = FS.read_file(GLOBALS.BODY_FILE) or ""
      end
      if ws_response.body ~= "" then
        existing.body = ws_response.body
      else
        existing.body = truncate_body(existing)
      end
      existing.json = Json.parse(existing.body) or {}
      existing = set_request_stats(existing)
      existing.status = existing.code == 0
      if existing == ws_response then
        local in_list = false
        for _, r in ipairs(responses) do
          if r == ws_response then
            in_list = true
            break
          end
        end
        if not in_list then table.insert(responses, ws_response) end
      end
      return existing
    end
  end

  local sent_url = parsed_request._kulala_sent_url
  local display_url = parsed_request._kulala_final_url or sent_url or parsed_request.url or ""

  ---@type Response
  local response = {
    id = id,
    name = parsed_request.name or "",
    url = display_url,
    method = parsed_request.method or "",
    request = {
      url = sent_url or parsed_request.url or "",
      headers_tbl = parsed_request.headers,
      body = parsed_request.body,
    },
    code = request_status.code or -1,
    response_code = 0,
    status = false,
    time = vim.fn.localtime(),
    duration = request_status.duration or 0,
    body_raw = raw_from_snapshot and request_status._kulala_raw_body_snapshot
      or (body_from_snapshot and request_status._kulala_body_snapshot or (FS.read_file(GLOBALS.BODY_FILE) or "")),
    body = "",
    json = {},
    filter = type(request_status._kulala_jq_filter) == "string" and request_status._kulala_jq_filter or nil,
    headers = headers_from_snapshot and request_status._kulala_headers_snapshot
      or (FS.read_file(GLOBALS.HEADERS_FILE) or ""),
    headers_tbl = INT_PROCESSING.get_headers(headers_from_snapshot and request_status._kulala_headers_snapshot or nil)
      or {},
    cookies = INT_PROCESSING.get_cookies() or {},
    errors = request_status.errors or "",
    stats = request_status.stdout or "",
    script_pre_output = "",
    script_post_output = "",
    assert_output = {},
    assert_status = true,
    file = parsed_request.file or "",
    buf_name = vim.fn.bufname(buf),
    line = line,
    buf = buf,
    _kulala_core = parsed_request._kulala_core == true,
    _kulala_redirect_chain = parsed_request._kulala_redirect_chain,
    _kulala_verbose_trace = parsed_request._kulala_verbose_trace,
    _kulala_body_type = request_status._kulala_body_type,
    _kulala_media_type = request_status._kulala_media_type,
    _kulala_binary = request_status._kulala_binary,
    _kulala_image_path = request_status._kulala_image_path,
  }

  parsed_request._kulala_redirect_chain = nil
  parsed_request._kulala_verbose_trace = nil

  response = modify_grpc_response(response)
  response = set_request_stats(response)

  response.body = truncate_body(response)
  response.json = Json.parse(response.body) or {}
  response.errors = inject_payload(response.errors, parsed_request)

  if response._kulala_body_type ~= "binary" then
    if #response.body == 0 and response.method ~= "GRPC" then response.headers = "Content-Type: text/plain" end
    if #response.body == 0 then response.body = "No response body (check Verbose output)" end
  end

  table.insert(responses, response)

  return response
end

local function process_response(request_status, parsed_request, callback)
  local response = save_response(request_status, parsed_request)
  request_status._kulala_response_id = response.id

  process_metadata(parsed_request, response)
  process_internal(parsed_request)

  if process_external(request_status, parsed_request, response) == "replay" then
    local run_opts = M.replay_run_opts(parsed_request)
    M.queue:add({ request = parsed_request }, function()
      if not run_opts then
        Logger.error("Cannot replay: missing HTTP file content for " .. (parsed_request.file or "unknown"))
        return M.queue:run_next()
      end
      process_request(parsed_request, callback, run_opts)
    end, 1)
  end

  process_api()

  return response.status
end

local function process_errors(request, request_status, processing_errors)
  if request_status.code == 124 then
    local t = CONFIG.get().kulala_core.timeout or 60000
    request_status.errors = ("%s\nRequest timed out (%s ms)"):format(request_status.errors or "", tostring(t))
  end

  request_status.errors = processing_errors and request_status.errors .. "\n" .. processing_errors
    or request_status.errors

  local response = save_response(request_status, request)
  request_status._kulala_response_id = response.id
  apply_script_console_to_response(request_status, request, response)

  local skip_logger = request_status._kulala_aborted == true and SCRIPT_CONSOLE_NOTIFY.enabled()
  if not skip_logger then
    local message = ("Errors in request %s at line: %s\n%s"):format(
      request.url,
      request.show_icon_line_number or "-",
      request_status.errors or ""
    )
    Logger.error(message, 2)
    if processing_errors then Logger.error(processing_errors, 2, { report = true }) end
  end
end

---@param advance_queue? boolean when false, do not advance the request queue (multi-response batch)
---@param invoke_ui_callback? boolean when false, skip the outer run_parser callback (multi-response batch)
local function handle_response_impl(request_status, parsed_request, callback, advance_queue, invoke_ui_callback)
  local config = CONFIG.get()
  local code = request_status.code == 0
  local success

  local processing_status, processing_errors = xpcall(function()
    success = code and process_response(request_status, parsed_request, callback)
  end, debug.traceback)

  if not (code and processing_status) then process_errors(parsed_request, request_status, processing_errors) end
  if advance_queue ~= false then
    if not success and config.halt_on_error then
      M.queue:reset()
    else
      M.queue:run_next()
    end
  end

  if invoke_ui_callback ~= false then
    local response_id = request_status._kulala_response_id
    local method_upper = (parsed_request.method or ""):upper()
    if not response_id and (method_upper == "WS" or method_upper == "WSS" or method_upper == "WEBSOCKET") then
      response_id = request_response_id(DB.get_current_buffer() or 0, parsed_request)
    end
    callback(success, request_status.duration, INLAY.icon_line_for_request(parsed_request), response_id)
  end
end

local handle_response = vim.schedule_wrap(handle_response_impl)

---@param request DocumentRequest
---@return DocumentRequest|"empty"|"skipped"|nil
local function parse_request(request)
  if not request._kulala_core then
    Logger.error("Request is not configured for kulala-core", 1)
    return "skipped"
  end

  return request
end

---Apply kulala-core `request` snapshot (resolved URL/headers/body) for UI display.
---@param item table kulala-core result entry
---@param target DocumentRequest
local function kulala_core_apply_sent_request(item, target)
  local sent = item.request
  if type(sent) ~= "table" and type(item.url) ~= "string" then return end

  if type(sent) == "table" then
    if type(sent.method) == "string" and sent.method ~= "" then target.method = sent.method end
    if type(sent.url) == "string" and vim.trim(sent.url) ~= "" then target._kulala_sent_url = sent.url end
    if type(sent.headers) == "table" then target.headers = sent.headers end
    if type(sent.body) == "string" then target.body = sent.body end
  end
  if type(item.url) == "string" and vim.trim(item.url) ~= "" then
    target._kulala_final_url = item.url
    target.url = item.url
  end
end

local function format_byte_size(bytes)
  bytes = tonumber(bytes) or 0
  if bytes < 1024 then return ("%d B"):format(bytes) end
  if bytes < 1024 * 1024 then return ("%.1f KB"):format(bytes / 1024) end
  return ("%.1f MB"):format(bytes / (1024 * 1024))
end

local function media_type_extension(media_type)
  local mt = (media_type or ""):lower()
  if mt == "image/png" then return ".png" end
  if mt == "image/jpeg" or mt == "image/jpg" then return ".jpg" end
  if mt == "image/gif" then return ".gif" end
  if mt == "image/webp" then return ".webp" end
  if mt == "image/bmp" then return ".bmp" end
  if mt == "image/svg+xml" then return ".svg" end
  if mt:find("^image/") then return ".img" end
  return ".bin"
end

---@param body table
---@return string
local function binary_body_note(body)
  local media_type = body.mediaType or "application/octet-stream"
  local size = format_byte_size(body.byteLength)
  if type(media_type) == "string" and media_type:lower():find("^image/", 1, false) then
    return ("Image response (%s, %s)"):format(media_type, size)
  end
  return ("Binary response body (%s, %s)"):format(media_type, size)
end

---@param body table|string|nil
---@return string
local function kulala_core_body_text(body)
  if type(body) == "table" and body.type == "json" then
    if type(body.formatted) == "string" then return body.formatted end
    local encoded = vim.json.encode(body.content)
    return encoded or vim.inspect(body.content)
  end
  if type(body) == "table" and body.type == "text" then return body.content or "" end
  if type(body) == "table" and body.type == "binary" then return binary_body_note(body) end
  if type(body) == "string" then return body end
  return ""
end

---Prefer jq-filtered body when kulala-core returned `filteredBody`.
---@param item table|nil
---@return string text
---@return table|nil body_obj
local function kulala_core_display_body(item)
  if type(item) ~= "table" then return "", nil end
  if type(item.filteredBody) == "table" then return kulala_core_body_text(item.filteredBody), item.filteredBody end
  if type(item.body) == "table" then return kulala_core_body_text(item.body), item.body end
  return kulala_core_body_text(item.body), nil
end

---@param body_obj table
---@return string|nil path
local function write_binary_temp_file(body_obj)
  if type(body_obj) ~= "table" or body_obj.type ~= "binary" or body_obj.encoding ~= "base64" then return nil end
  if type(body_obj.content) ~= "string" or body_obj.content == "" then return nil end
  local ok, decoded = pcall(vim.base64.decode, body_obj.content)
  if not ok or type(decoded) ~= "string" then return nil end
  local path = vim.fn.tempname() .. media_type_extension(body_obj.mediaType)
  if not FS.write_file(path, decoded, false, true) then return nil end
  return path
end

local function kulala_core_headers_text(headers)
  local lines = {}
  for k, v in pairs(headers or {}) do
    table.insert(lines, ("%s: %s"):format(k, tostring(v)))
  end
  table.sort(lines)
  return table.concat(lines, "\n") .. "\n\n"
end

---@param result table
---@return table|nil binary_meta `{ content, encoding, byteLength, mediaType?, path? }`
local function write_kulala_core_response_files(result)
  local display_text, body_obj = kulala_core_display_body(result)
  local binary_meta = nil

  if type(body_obj) == "table" and body_obj.type == "binary" and body_obj.encoding == "base64" then
    local ok, decoded = pcall(vim.base64.decode, body_obj.content)
    if ok and type(decoded) == "string" then
      FS.write_file(GLOBALS.BODY_FILE, decoded, false, true)
    else
      FS.write_file(GLOBALS.BODY_FILE, display_text)
    end
    local path = write_binary_temp_file(body_obj)
    binary_meta = {
      content = body_obj.content,
      encoding = body_obj.encoding,
      byteLength = body_obj.byteLength,
      mediaType = body_obj.mediaType,
      path = path,
      note = display_text,
    }
  else
    FS.write_file(GLOBALS.BODY_FILE, display_text)
  end

  FS.write_file(GLOBALS.HEADERS_FILE, kulala_core_headers_text(result.headers))
  return binary_meta
end

---@param binary_meta table|nil
---@return table|nil
---@return string|nil
local function binary_fields_from_meta(binary_meta)
  if type(binary_meta) ~= "table" then return nil, nil end
  return binary_meta, binary_meta.path
end

local function kulala_core_stats_stdout(result)
  local t = result.timings or {}
  local timings = {
    { name = "namelookup", duration = (t.dns or 0) / 1000 },
    { name = "connect", duration = (t.tcp or 0) / 1000 },
    { name = "appconnect", duration = (t.tls or 0) / 1000 },
    { name = "pretransfer", duration = (t.startTransfer or 0) / 1000 },
    { name = "starttransfer", duration = (t.firstByte or 0) / 1000 },
    { name = "redirect", duration = (t.redirect or 0) / 1000 },
  }
  return vim.json.encode { response_code = result.status, timings = timings }
end

---Matches kulala-core KulalaPromptResponse (`prompt` or oauth/custom identifiers).
---@param item table|nil
---@return boolean
local function kulala_core_result_is_prompt(item)
  if type(item) ~= "table" then return false end
  if item.prompt == true then return true end
  if
    type(item.promptId) == "string"
    and item.promptId ~= ""
    and type(item.promptType) == "string"
    and item.promptType ~= ""
  then
    return true
  end
  return false
end

---@param data table[]
---@return table|nil
local function kulala_core_find_first_prompt(data)
  for _, item in ipairs(data) do
    if kulala_core_result_is_prompt(item) then return item end
  end
  return nil
end

---@param data table[]
---@return table[]
local function kulala_core_completed_before_prompt(data)
  for i, item in ipairs(data) do
    if kulala_core_result_is_prompt(item) then
      if i <= 1 then return {} end
      local out = {}
      for j = 1, i - 1 do
        out[j] = data[j]
      end
      return out
    end
  end
  return {}
end

---@param item table
---@return string|nil
local function kulala_core_prompt_block_name(item)
  if type(item.blockName) == "string" and vim.trim(item.blockName) ~= "" then return vim.trim(item.blockName) end
  return nil
end

---Queue tasks run inside `vim.schedule`; calling `input()` there often returns immediately without a prompt.
---Defer twice so cmdline input runs on the main loop (same pattern as needing a tick after schedule).
---@param fn fun(): string
---@return string|nil
local function kulala_core_sync_input(fn)
  local done = false
  local result --- @type string|nil
  vim.schedule(function()
    vim.schedule(function()
      local ok, r = pcall(fn)
      result = ok and r or nil
      done = true
    end)
  end)
  local waited = vim.wait(600000, function()
    return done
  end, 20)
  if not waited then
    Logger.warn("kulala-core prompt input timed out")
    return nil
  end
  return result
end

---kulala-core OAuth2 / @kulala-prompt: collect stdin for `action: continue`.
---@param prompt { inputs?: { id: string, label?: string, type?: string, required?: boolean }[], message?: string }
---@return { id: string, value: string }[]|nil
local function kulala_core_collect_prompt_inputs(prompt)
  local inputs_spec = prompt.inputs
  if not inputs_spec or #inputs_spec == 0 then
    Logger.warn("kulala-core prompt has no inputs")
    return nil
  end
  local out = {}
  for _, inp in ipairs(inputs_spec) do
    local id = inp.id
    if not id or id == "" then return nil end
    local label = inp.label or id
    local kind = inp.type or "text"
    local value
    if kind == "password" then
      value = kulala_core_sync_input(function()
        return vim.fn.inputsecret(vim.trim(label) .. ": ")
      end)
    else
      value = kulala_core_sync_input(function()
        return vim.fn.input(vim.trim(label) .. ": ")
      end)
    end
    if value == nil then return nil end
    value = tostring(value)
    if inp.required and vim.trim(value) == "" then
      Logger.warn("Required input missing: " .. id)
      return nil
    end
    table.insert(out, { id = id, value = value })
  end
  return out
end

---@param requests DocumentRequest[]
---@return table[]|nil limit kulala-core run limit (name filters), or nil when empty
local function kulala_core_batch_limit(requests)
  local limit = {}
  for _, req in ipairs(requests) do
    local name = req._kulala_block_name
    if type(name) == "string" and name ~= "" then table.insert(limit, { filter = "name", name = name }) end
  end
  if #limit == 0 then return nil end
  return limit
end

---@param parsed_request DocumentRequest
---@return DocumentRequest[]
local function kulala_core_run_targets(parsed_request)
  if type(parsed_request._kulala_batch_targets) == "table" and #parsed_request._kulala_batch_targets > 0 then
    return parsed_request._kulala_batch_targets
  end
  if parsed_request._kulala_run_expander and parsed_request.nested_requests and #parsed_request.nested_requests > 0 then
    return parsed_request.nested_requests
  end
  return { parsed_request }
end

---@param console table|nil kulala-core scriptConsole
---@return string
local function kulala_core_script_console_messages(console)
  if type(console) ~= "table" then return "" end
  local lines = {}
  for _, entry in ipairs(console) do
    if type(entry) == "table" then
      local msg = entry.message or entry["message"]
      if type(msg) == "string" and msg ~= "" then
        table.insert(lines, msg)
      elseif msg ~= nil then
        table.insert(lines, tostring(msg))
      end
    end
  end
  return table.concat(lines, "\n")
end

---Body text for skip/abort: prefer core body, else join script logs + footer.
---@param item table
---@param console table|nil
---@param footer string
---@return string
local function kulala_core_control_flow_body(item, console, footer)
  local display = kulala_core_display_body(item)
  if display ~= "" then return display end
  local logs = kulala_core_script_console_messages(console)
  if logs ~= "" and footer ~= "" then return logs .. "\n\n" .. footer end
  if logs ~= "" then return logs end
  return footer
end

---@param item table kulala-core result entry
---@param targets DocumentRequest[]
---@param index number 1-based index in the batch
---@return DocumentRequest
local function kulala_core_target_for_item(item, targets, index)
  if type(item.blockName) == "string" and item.blockName ~= "" then
    for _, target in ipairs(targets) do
      if target._kulala_block_name == item.blockName then return target end
    end
  end
  return targets[index] or targets[1]
end

---@param item table
---@param target DocumentRequest
---@param duration_wall number
---@param callback function
---@param advance_queue boolean
local function kulala_core_deliver_result(item, target, duration_wall, callback, advance_queue, invoke_ui_callback)
  save_replay_snapshot(target)

  if item.success == true and item.skipped == true then
    local console = kulala_core_script_console(item)
    target._kulala_script_console = console
    local footer = (type(item.message) == "string" and item.message ~= "") and item.message
      or "Request skipped by script"
    local body = kulala_core_control_flow_body(item, console, footer)
    handle_response_impl({
      code = 0,
      stdout = "",
      errors = "",
      duration = duration_wall,
      _kulala_body_type = "text",
      _kulala_media_type = "text/plain",
      _kulala_body_snapshot = body,
      _kulala_headers_snapshot = "Content-Type: text/plain\n\n",
      _kulala_script_console = console,
    }, target, callback, advance_queue, invoke_ui_callback)
    return
  end

  if item.success == true and item.openapiUi == true and type(item.openapi) == "table" then
    local OPENAPI_PANEL = require("kulala.ui.openapi_panel")
    OPENAPI_PANEL.open(item.openapi, target, DB.get_current_buffer())
    if advance_queue ~= false then M.queue:run_next() end
    if invoke_ui_callback ~= false then callback(true, duration_wall, INLAY.icon_line_for_request(target), nil) end
    return
  end

  if item.success ~= true then
    local console = kulala_core_script_console(item)
    target._kulala_script_console = console
    if item.httpCompleted == true and type(item.status) == "number" then
      kulala_core_apply_sent_request(item, target)
      local binary_meta = write_kulala_core_response_files(item)
      local binary, image_path = binary_fields_from_meta(binary_meta)
      local duration_ns = math.floor((item.timings and item.timings.total or 0) * 1e6)
      handle_response_impl({
        code = 1,
        errors = item.error or "response handler script failed",
        stdout = kulala_core_stats_stdout(item),
        duration = duration_ns,
        _kulala_body_type = type(item.body) == "table" and item.body.type or nil,
        _kulala_media_type = type(item.body) == "table" and item.body.mediaType or nil,
        _kulala_body_snapshot = kulala_core_display_body(item),
        _kulala_raw_body_snapshot = type(item.rawBody) == "string" and item.rawBody or nil,
        _kulala_headers_snapshot = kulala_core_headers_text(item.headers),
        _kulala_script_console = console,
        _kulala_binary = binary,
        _kulala_image_path = image_path,
      }, target, callback, advance_queue, invoke_ui_callback)
      return
    end
    if type(item.request) == "table" then kulala_core_apply_sent_request(item, target) end
    if type(item.verboseTrace) == "string" and item.verboseTrace ~= "" then
      target._kulala_verbose_trace = item.verboseTrace
    end
    local err = item.error or "request failed"
    local body = kulala_core_control_flow_body(item, console, err)
    handle_response_impl({
      code = 1,
      errors = body,
      stdout = "",
      duration = duration_wall,
      _kulala_body_type = "text",
      _kulala_media_type = "text/plain",
      _kulala_body_snapshot = body,
      _kulala_headers_snapshot = "Content-Type: text/plain\n\n",
      _kulala_script_console = console,
      _kulala_aborted = item.aborted == true,
    }, target, callback, advance_queue, invoke_ui_callback)
    return
  end

  kulala_core_apply_sent_request(item, target)

  if item.protocol == "websocket" then
    local WEBSOCKET = require("kulala.cmd.websocket")
    FS.write_file(GLOBALS.HEADERS_FILE, "Content-Type: text/plain\n\n")
    local response = {
      id = request_response_id(DB.get_current_buffer() or 0, target),
      name = target.name or "",
      url = target._kulala_final_url or target._kulala_sent_url or target.url or "",
      method = target.method or "WS",
      request = { headers_tbl = target.headers, body = target.body },
      code = 0,
      response_code = 0,
      status = true,
      time = vim.fn.localtime(),
      duration = 0,
      body_raw = "",
      body = "",
      json = {},
      _ws_messages = {},
      filter = type(item.jqFilter) == "string" and item.jqFilter ~= "" and item.jqFilter or nil,
      headers = "",
      headers_tbl = {},
      cookies = {},
      errors = "",
      stats = "",
      script_pre_output = "",
      script_post_output = "",
      assert_output = {},
      assert_status = true,
      file = target.file or "",
      buf_name = vim.api.nvim_buf_get_name(DB.get_current_buffer() or 0),
      line = target.show_icon_line_number or 0,
      buf = DB.get_current_buffer(),
      _kulala_core = true,
      _kulala_media_type = "application/json",
    }
    if type(item.messages) == "table" then
      target._ws_script_messages = item.messages
      if type(item.timeoutMs) == "number" then target._ws_timeout_ms = item.timeoutMs end
      target.body_computed = type(item.initialMessage) == "string" and item.initialMessage or nil
    else
      target.body_computed = item.initialMessage or target.body
    end
    WEBSOCKET.connect(target, response, function(success, duration)
      handle_response({
        code = success and 0 or 1,
        stdout = "",
        errors = response.errors or "",
        duration = duration or 0,
      }, target, callback, advance_queue, invoke_ui_callback)
    end)
    return
  end

  local binary_meta = write_kulala_core_response_files(item)
  local binary, image_path = binary_fields_from_meta(binary_meta)
  local duration_ns = math.floor((item.timings and item.timings.total or 0) * 1e6)

  local console = kulala_core_script_console(item)
  target._kulala_script_console = console
  local chain = item.redirectChain
  target._kulala_redirect_chain = (vim.islist(chain) and #chain > 0) and chain or nil
  target._kulala_verbose_trace = type(item.verboseTrace) == "string" and item.verboseTrace or nil

  handle_response_impl({
    code = 0,
    stdout = kulala_core_stats_stdout(item),
    errors = "",
    duration = duration_ns,
    _kulala_body_type = (function()
      local _, body_obj = kulala_core_display_body(item)
      return body_obj and body_obj.type or (type(item.body) == "table" and item.body.type or nil)
    end)(),
    _kulala_media_type = (function()
      local _, body_obj = kulala_core_display_body(item)
      return body_obj and body_obj.mediaType or (type(item.body) == "table" and item.body.mediaType or nil)
    end)(),
    _kulala_body_snapshot = kulala_core_display_body(item),
    _kulala_raw_body_snapshot = type(item.rawBody) == "string" and item.rawBody or nil,
    _kulala_jq_filter = type(item.jqFilter) == "string" and item.jqFilter ~= "" and item.jqFilter or nil,
    _kulala_headers_snapshot = kulala_core_headers_text(item.headers),
    _kulala_script_console = console,
    _kulala_binary = binary,
    _kulala_image_path = image_path,
  }, target, callback, advance_queue, invoke_ui_callback)
end

---@param wrapper table
---@param parsed_request DocumentRequest
---@param duration_wall number
---@param callback function
local function kulala_core_deliver_run_results(wrapper, parsed_request, duration_wall, callback)
  local data = wrapper.data or {}
  local targets = kulala_core_run_targets(parsed_request)
  local multi_target = #targets > 1
  for i, item in ipairs(data) do
    local advance_queue = i == #data
    local invoke_ui_callback = multi_target or advance_queue
    local target = kulala_core_target_for_item(item, targets, i)
    kulala_core_deliver_result(item, target, duration_wall, callback, advance_queue, invoke_ui_callback)
  end
end

local process_request_kulala_core

---@param wrapper table|nil
---@param parsed_request DocumentRequest
---@param callback function
---@param retry_depth number
---@param start_time number
---@param core_cwd string|nil
---@param run_opts KulalaCoreRunOpts|nil
local function finish_kulala_core_wrapper(
  wrapper,
  parsed_request,
  callback,
  retry_depth,
  start_time,
  core_cwd,
  run_opts
)
  local duration_wall = vim.uv.hrtime() - start_time

  if not wrapper or type(wrapper) ~= "table" then
    handle_response({
      code = 1,
      errors = "invalid kulala-core run output",
      stdout = "",
      duration = duration_wall,
    }, parsed_request, callback)
    return
  end

  if wrapper.type == "error" then
    local msg = "kulala-core error"
    if wrapper.data and wrapper.data[1] and wrapper.data[1].error then msg = wrapper.data[1].error end
    handle_response({
      code = 1,
      errors = msg,
      stdout = "",
      duration = duration_wall,
    }, parsed_request, callback)
    return
  end

  local data = wrapper.data or {}
  if #data == 0 then
    handle_response({
      code = 1,
      errors = "kulala-core returned no result",
      stdout = "",
      duration = duration_wall,
    }, parsed_request, callback)
    return
  end

  local prompt_item = kulala_core_find_first_prompt(data)
  if prompt_item then
    local completed_before = kulala_core_completed_before_prompt(data)
    if #completed_before > 0 then
      kulala_core_deliver_run_results(
        { type = "responses", data = completed_before },
        parsed_request,
        duration_wall,
        callback
      )
    end

    local inputs = kulala_core_collect_prompt_inputs(prompt_item)
    if not inputs then
      handle_response({
        code = 1,
        errors = "Prompt cancelled or incomplete",
        stdout = "",
        duration = duration_wall,
      }, parsed_request, callback)
      return
    end
    if not prompt_item.promptId or prompt_item.promptId == "" then
      handle_response({
        code = 1,
        errors = "kulala-core prompt missing promptId",
        stdout = "",
        duration = duration_wall,
      }, parsed_request, callback)
      return
    end

    KULALA_CORE.continue_async(
      {
        promptId = prompt_item.promptId,
        inputs = inputs,
      },
      core_cwd,
      function(cont_wrapper, cont_err)
        vim.schedule(function()
          local cont_wall = vim.uv.hrtime() - start_time
          if cont_err then
            handle_response({
              code = 1,
              errors = cont_err,
              stdout = "",
              duration = cont_wall,
            }, parsed_request, callback)
            return
          end
          local cont_first = cont_wrapper and (cont_wrapper.data or {})[1]
          if not cont_first or cont_first.success ~= true then
            handle_response({
              code = 1,
              errors = (cont_first and cont_first.error) or "continue did not succeed",
              stdout = "",
              duration = cont_wall,
            }, parsed_request, callback)
            return
          end

          local retry_run_opts = vim.deepcopy(run_opts or parsed_request._kulala_replay_run_opts or {})
          local block_name = kulala_core_prompt_block_name(prompt_item)
          if #completed_before > 0 and block_name then
            retry_run_opts.limit = { { filter = "name", name = block_name } }
          end
          process_request_kulala_core(parsed_request, callback, retry_depth + 1, retry_run_opts)
        end)
      end
    )
    return
  end

  kulala_core_deliver_run_results(wrapper, parsed_request, duration_wall, callback)
end

---@param parsed_request DocumentRequest
---@param callback function
---@param retry_depth? number
---@param run_opts? KulalaCoreRunOpts
process_request_kulala_core = function(parsed_request, callback, retry_depth, run_opts)
  retry_depth = retry_depth or 0
  if run_opts then parsed_request._kulala_replay_run_opts = run_opts end
  run_opts = run_opts or parsed_request._kulala_replay_run_opts

  if retry_depth > 6 then
    handle_response({
      code = 1,
      errors = "kulala-core: exceeded prompt / retry limit",
      stdout = "",
      duration = 0,
    }, parsed_request, callback)
    return
  end

  local start_time = vim.uv.hrtime()
  local run_payload, core_cwd = build_kulala_core_run_payload(parsed_request, run_opts)
  local HTTP_STREAM = require("kulala.cmd.http_stream")
  HTTP_STREAM.reset()

  KULALA_CORE.run_async(run_payload, core_cwd, function(wrapper, err)
    vim.schedule(function()
      HTTP_STREAM.reset()
      if err then
        handle_response({
          code = 1,
          errors = err,
          stdout = "",
          duration = vim.uv.hrtime() - start_time,
        }, parsed_request, callback)
        return
      end
      finish_kulala_core_wrapper(wrapper, parsed_request, callback, retry_depth, start_time, core_cwd, run_opts)
    end)
  end, {
    on_http_stream = function(event)
      local targets = kulala_core_run_targets(parsed_request)
      local target = parsed_request
      if type(event.blockName) == "string" and event.blockName ~= "" then
        for _, candidate in ipairs(targets) do
          if candidate._kulala_block_name == event.blockName then
            target = candidate
            break
          end
        end
      end
      HTTP_STREAM.on_event(event, target, callback)
    end,
  })
end

---Executes DocumentRequest
---@param request DocumentRequest
---@param callback function
---@param run_opts? KulalaCoreRunOpts
function process_request(request, callback, run_opts)
  local config = CONFIG.get()

  local parsed_request = parse_request(request)

  if parsed_request == "empty" or parsed_request == "skipped" then return M.queue:run_next() end
  if type(parsed_request) ~= "table" then
    callback(false, 0, request.start_line)
    return config.halt_on_error and M.queue:reset() or M.queue:run_next()
  end

  if M.queue.status == "paused" then return end

  return process_request_kulala_core(parsed_request, callback, 0, run_opts)
end

---@param request DocumentRequest
---@return boolean
local function execute_before_request(request)
  local before_request = CONFIG.get().before_request
  if not before_request then return true end

  if type(before_request) == "function" then
    return before_request(request)
  else
    UI_utils.highlight_request(request)
    return true
  end
end

---Parses and executes DocumentRequest/s:
---if requests is nil then it parses the current document
---if line_nr is nil then runs the first request in the list (used for replaying last request)
---if line_nr > 0 then runs the request from current buffer around the line number
---if line_nr is 0 then runs all or visually selected requests
---@param requests? DocumentRequest[]|nil
---@param line_nr? number|nil
---@param callback function
---@param run_opts? KulalaCoreRunOpts
M.run_parser = function(requests, line_nr, callback, run_opts)
  M.queue:reset()

  if not KULALA_CORE.enabled() then
    local msg = "kulala-core not found. "
      .. "Either let kulala.nvim auto-download and install kulala-core or set `kulala_core.path` in setup."
    local configured = CONFIG.get().kulala_core.path
    if type(configured) == "string" and vim.trim(configured) ~= "" then
      msg = ("kulala_core.path is not executable: %s"):format(vim.trim(configured))
    end
    return Logger.error(msg, 1, { report = true })
  end

  if not requests then requests = DOCUMENT_PARSER.get_document() end
  if not requests then return Logger.error("No requests found in the document") end

  requests = DOCUMENT_PARSER.get_request_at(requests, line_nr)
  if #requests == 0 then return Logger.error("No request found at current line") end

  local limit_line = (type(line_nr) == "number" and line_nr > 0) and line_nr or nil

  -- One kulala-core run keeps JetBrains execution-flow state (e.g. client.global.headers).
  if #requests > 1 then
    local anchor = requests[1]
    if anchor._kulala_core and limit_line then anchor._kulala_limit_line = limit_line end
    anchor._kulala_batch_targets = requests

    for _, request in ipairs(requests) do
      INLAY.show(DB.current_buffer, "loading", INLAY.icon_line_for_request(request))
    end

    local batch_run_opts = vim.tbl_extend("force", run_opts or {}, {})
    local batch_limit = kulala_core_batch_limit(requests)
    if batch_limit then batch_run_opts.limit = batch_limit end

    M.queue:add({ request = anchor, batch_index = 1, batch_size = 1 }, function()
      if execute_before_request(anchor) then
        initialize()
        process_request(anchor, callback, batch_run_opts)
      end
    end)
  else
    for batch_index, request in ipairs(requests) do
      if request._kulala_core and limit_line then request._kulala_limit_line = limit_line end

      INLAY.show(DB.current_buffer, "loading", INLAY.icon_line_for_request(request))

      M.queue:add({ request = request, batch_index = batch_index, batch_size = #requests }, function()
        if execute_before_request(request) then
          initialize()
          process_request(request, callback, run_opts)
        end
      end)
    end
  end

  M.queue:run_next()
end

---Deliver a single kulala-core result item (e.g. OpenAPI operation run) into the response UI.
---@param item table
---@param target DocumentRequest
---@param callback? function
function M.deliver_core_result(item, target, callback)
  callback = callback or function() end
  kulala_core_deliver_result(item, target, 0, callback, false, true)
end

return M
