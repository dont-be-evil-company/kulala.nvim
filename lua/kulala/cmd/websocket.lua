local Ext_processing = require("kulala.external_processing")
local FS = require("kulala.utils.fs")
local GLOBALS = require("kulala.globals")
local KULALA_CORE = require("kulala.cmd.kulala_core_bridge")
local Keymaps = require("kulala.config.keymaps")
local Logger = require("kulala.logger")

local M = {}

M.connection = nil
M.response = nil

local function parse_ws_line(data)
  if not data or data == "" then return nil end
  local ok, msg = pcall(vim.json.decode, data)
  if ok and type(msg) == "table" then return msg end
  return nil
end

---@class WsStreamMessage
---@field direction "in"|"out"
---@field data string

---@param messages WsStreamMessage[]
local function build_ws_jq_source(messages)
  local items = {}
  for _, msg in ipairs(messages) do
    local raw = msg.data
    local ok, parsed = pcall(vim.json.decode, raw)
    if ok and parsed ~= nil then
      table.insert(items, parsed)
    else
      table.insert(items, raw)
    end
  end
  return #items > 0 and vim.json.encode(items) or ""
end

---JSON objects only (skip plain-text server greetings) for jq input.
---@param messages WsStreamMessage[]
---@param initial_message? string sent on connect, used until JSON messages arrive
---@return string jq_input
---@return boolean has_objects
local function build_ws_jq_object_source(messages, initial_message)
  local objects = {}
  for _, msg in ipairs(messages) do
    local raw = msg.data
    local ok, parsed = pcall(vim.json.decode, raw)
    if ok and type(parsed) == "table" and not vim.islist(parsed) then table.insert(objects, parsed) end
  end
  if #objects == 0 and type(initial_message) == "string" and initial_message ~= "" then
    local ok, parsed = pcall(vim.json.decode, initial_message)
    if ok and type(parsed) == "table" and not vim.islist(parsed) then return vim.json.encode(parsed), true end
  end
  if #objects == 0 then return "", false end
  if #objects == 1 then return vim.json.encode(objects[1]), true end
  return vim.json.encode(objects), true
end

---WebSocket jq input is a JSON array of messages (strings + objects). Adapt filters accordingly.
---@param filter string
---@param body_raw string
---@return string
local function adapt_ws_jq_filter(filter, body_raw)
  if type(filter) ~= "string" or filter == "" then return filter end
  if type(body_raw) ~= "string" or vim.trim(body_raw):sub(1, 1) ~= "[" then return filter end

  local objects = '([.[] | select(type == "object")]'

  local idx, rest = filter:match("^(%.%[%-?%d+%])(.*)$")
  if idx then
    local base = idx == ".[-1]" and (objects .. " | last)") or (objects .. " | " .. idx .. ")")
    if rest ~= "" then return base .. rest end
    return base
  end

  if filter:match("^%.%.") or filter:match("^%.%s*%[") then return filter end
  if filter == "." or filter:match("^%.[%a_]") then return string.format("%s | %s)", objects, filter) end
  return filter
end

---@param filter string
---@param jq_input string
---@return string
local function normalize_ws_filter_for_input(filter, jq_input)
  if vim.trim(jq_input):sub(1, 1) ~= "[" then
    local rest = filter:match("^%.%[%-?%d+%](.+)$")
    if rest then return rest end
    if filter:match("^%.%[%-?%d+%]$") then return "." end
  end
  return adapt_ws_jq_filter(filter, jq_input)
end

---@param text string
---@return boolean
local function is_empty_jq_display(text)
  local trimmed = vim.trim(text or "")
  return trimmed == "" or trimmed == "null"
end

---@param messages WsStreamMessage[]
local function build_ws_display_stream(messages)
  if #messages == 0 then return "" end
  local lines = vim.tbl_map(function(msg)
    local prefix = msg.direction == "out" and "-->" or "<--"
    return prefix .. " " .. msg.data
  end, messages)
  return table.concat(lines, "\n")
end

---@param target Response
---@param direction "in"|"out"
---@param data string
local function append_ws_message(target, direction, data)
  target._ws_messages = target._ws_messages or {}
  table.insert(target._ws_messages, { direction = direction, data = data })
end

---@param target? Response when omitted, uses the active `M.response`
function M.refresh_display(target)
  target = target or M.response
  if not target then return end
  local prefix = target._ws_welcome or ""
  if type(target._ws_status) == "string" and target._ws_status ~= "" then
    prefix = prefix .. target._ws_status .. "\n"
  end
  local messages = target._ws_messages or {}
  local stream = build_ws_display_stream(messages)
  target.body_raw = build_ws_jq_source(messages)
  local filter = target.filter
  if type(filter) == "string" and filter ~= "" then
    local jq_input, has_objects = build_ws_jq_object_source(messages, target._ws_initial_message)
    if has_objects and jq_input ~= "" then
      local cwd = target.file and vim.fn.fnamemodify(target.file, ":h") or nil
      filter = normalize_ws_filter_for_input(filter, jq_input)
      local snapshot = {
        body_raw = jq_input,
        json = {},
        _kulala_media_type = target._kulala_media_type or "application/json",
      }
      if Ext_processing.jq(filter, snapshot, cwd, { silent = true }) and not is_empty_jq_display(snapshot.body) then
        target.body = prefix .. snapshot.body
        target.json = snapshot.json
        target._kulala_body_type = snapshot._kulala_body_type
        return
      end
    end
  end
  target.body = prefix .. stream
end

---Persist live WebSocket body so `save_response` and the UI read the current stream.
local function persist_response_body()
  if not M.response then return end
  FS.write_file(GLOBALS.BODY_FILE, M.response.body or "")
end

---@param callback function
---@param success boolean
---@param opts? { refresh_only?: boolean }
local function notify_ui(callback, success, opts)
  opts = opts or {}
  persist_response_body()
  if opts.refresh_only then
    vim.schedule(function()
      require("kulala.ui").refresh_ws_body_if_visible()
    end)
    return
  end
  callback(success, 0, M.response and M.response.line or 0)
end

M.on_stdout = function(_, data, callback)
  if not data or #data == 0 then return end

  for line in data:gmatch("[^\n]+") do
    local msg = parse_ws_line(line)
    if msg and msg.type == "message" and msg.data then
      append_ws_message(M.response, "in", msg.data)
      M.refresh_display()
      notify_ui(callback, true, { refresh_only = true })
    elseif msg and msg.type == "sent" and msg.data then
      append_ws_message(M.response, "out", msg.data)
      M.refresh_display()
      notify_ui(callback, true, { refresh_only = true })
    elseif msg and msg.type == "closed" then
      M.response.status = false
      M.response.code = -1
      if not M.response._ws_welcome then
        -- Handshake failed; the preceding error event already set body/errors.
        notify_ui(callback, false)
        return
      end
      M.response.body = (M.response._ws_welcome or "") .. "Connection closed\n"
      notify_ui(callback, false)
    elseif msg and msg.type == "error" then
      local err = msg.error or "WebSocket error"
      if M.response._ws_welcome then
        M.response._ws_status = err
        M.response.errors = vim.trim((M.response.errors or "") .. "\n" .. err)
        M.refresh_display()
        notify_ui(callback, true, { refresh_only = true })
      else
        Logger.error("Error connecting to WS: " .. err)
        M.response.errors = vim.trim((M.response.errors or "") .. "\n" .. err)
        M.response.body = (M.response._ws_welcome or "") .. "WebSocket error: " .. err .. "\n"
        notify_ui(callback, false)
      end
    elseif msg and msg.type == "waiting" then
      local remaining = tonumber(msg.remaining) or 0
      M.response._ws_status = string.format("Waiting for %d server message(s)...", remaining)
      M.refresh_display()
      notify_ui(callback, true, { refresh_only = true })
    elseif msg and msg.type == "script-done" then
      M.response._ws_status = "Script finished. Compose a message to send more."
      M.refresh_display()
      notify_ui(callback, true, { refresh_only = true })
    end
  end
end

M.on_stderr = function(_, data, callback)
  if not data or #data == 0 then return end
  Logger.error("Error connecting to WS: " .. data)

  M.response.code = -1
  M.response.status = false

  M.response.body = M.response.body:gsub("^.-\n.-\n", "Connection closed\n")
  M.response.errors = M.response.errors .. "\n" .. data

  notify_ui(callback, false)
end

M.on_exit = function(system, _, callback)
  M.response.code = system.code == 0 and -1 or system.code
  M.response.status = false

  M.response.body = M.response.body:gsub("^.-\n.-\n", "Connection closed\n")

  notify_ui(callback, false)
end

local function set_welcome_message()
  local WS_INPUT = require("kulala.ui.ws_input")
  local send_key, _ = WS_INPUT.format_welcome_keys()
  local interrupt = (Keymaps.get_kulala_keymaps() or {})["Interrupt requests"]
  local close_conn_key = interrupt and interrupt[1] or "<C-c>"

  M.response._ws_welcome = (
    "Connected... Waiting for data."
    .. "\nScripted === messages are sent automatically."
    .. "\nPress %s in the body view to compose a message."
    .. "\nPress %s to close the connection.\n\n"
  ):format(send_key, close_conn_key)
  M.refresh_display()
end

function M.connect(request, response, callback, opts)
  opts = opts or {}
  response.body = ""
  response.body_raw = ""
  response._ws_messages = {}
  local script_messages = request._ws_script_messages
  local initial_source = script_messages and (request.body_computed or "")
    or (request.body_computed or request.body or "")
  local initial = vim.trim(initial_source)
  response._ws_initial_message = initial ~= "" and initial or nil

  if M.connection then M.close() end

  M.response = response

  local _, core_cwd = KULALA_CORE.resolve_document_paths(0, request.file)

  ---kulala-core resolves URL/headers/body; nvim must not substitute locally.
  local connect_url = request._kulala_final_url or request._kulala_sent_url or request.url or ""
  local connect_headers = request.headers or {}

  local function handler(event)
    return function(system, data)
      vim.schedule(function()
        if event == "on_stdout" and data then
          for line in data:gmatch("[^\n]+") do
            local msg = parse_ws_line(line)
            if msg and msg.type == "ready" then
              set_welcome_message()
              notify_ui(callback, true)
            end
          end
        end
        local call = opts[event] or M[event]
        call(system, data, callback)
      end)
    end
  end

  local status, result = xpcall(function()
    return KULALA_CORE.websocket_start({
      url = connect_url,
      body = script_messages and nil or (request.body_computed or request.body),
      headers = connect_headers,
      messages = script_messages,
      timeoutMs = request._ws_timeout_ms,
    }, {
      on_stdout = handler("on_stdout"),
      on_stderr = handler("on_stderr"),
      on_exit = handler("on_exit"),
    }, core_cwd)
  end, debug.traceback)

  if not status then return Logger.error("Failed to connect to websocket:\n" .. result, 2) end
  if not result then return Logger.error("kulala-core WebSocket failed to start", 2) end

  M.connection = result

  return result.pid
end

local function get_selection()
  local mode = vim.api.nvim_get_mode().mode
  local lines

  if mode == "V" or mode == "v" then
    vim.api.nvim_input("<Esc>")
    local v_start, v_end = vim.fn.getpos("."), vim.fn.getpos("v")
    lines = vim.fn.getregion(v_start, v_end, { type = mode })
  else
    lines = { vim.fn.getline(".") }
  end

  return lines
end

function M.send(data)
  local conn = M.connection
  if not conn or conn:is_closing() then
    Logger.error("WebSocket is not connected", 1)
    return false
  end

  data = data and data:gsub("\n$", "")
  data = data and { data } or get_selection()

  local sent = false
  vim.iter(data):each(function(line)
    if vim.trim(line) == "" then return end
    local ok, err = pcall(function()
      conn:write(vim.json.encode { op = "send", data = line } .. "\n")
    end)
    if not ok then
      Logger.error("Failed to send WebSocket message: " .. tostring(err), 1)
      return
    end
    sent = true
  end)

  return sent
end

function M.close()
  local conn = M.connection
  if not conn then return false end

  if not conn:is_closing() then
    conn:write(vim.json.encode { op = "close" } .. "\n")
    vim.wait(500, function()
      return conn:is_closing()
    end)
    if not conn:is_closing() then conn:kill(15) end
  end
  M.connection = nil

  return true
end

function M.is_active()
  local conn = M.connection
  return conn and not conn:is_closing()
end

return M
