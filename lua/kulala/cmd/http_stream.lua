local DB = require("kulala.db")
local FS = require("kulala.utils.fs")
local GLOBALS = require("kulala.globals")

local M = {}

---@type Response|nil
M.response = nil

local opened = false

function M.reset()
  M.response = nil
  opened = false
end

---@param buf number
---@param request table
---@return string
local function response_id(buf, request)
  local line = request.show_icon_line_number or 0
  local id = buf .. ":" .. line
  if type(request._kulala_block_name) == "string" and request._kulala_block_name ~= "" then
    id = id .. ":" .. request._kulala_block_name
  end
  return id
end

---@param headers table|nil
---@return string
local function headers_text(headers)
  local lines = {}
  for k, v in pairs(headers or {}) do
    table.insert(lines, ("%s: %s"):format(k, tostring(v)))
  end
  table.sort(lines)
  if #lines == 0 then return "" end
  return table.concat(lines, "\n") .. "\n\n"
end

---@param request table
---@param event table
---@return Response
local function ensure_response(request, event)
  if M.response then return M.response end

  local buf = DB.get_current_buffer() or 0
  local status = tonumber(event.status) or 0
  local headers = type(event.headers) == "table" and event.headers or {}
  local content_type = headers["content-type"]

  ---@type Response
  local response = {
    id = response_id(buf, request),
    name = request.name or "",
    url = event.url or request.url or "",
    method = request.method or "GET",
    request = {
      headers_tbl = request.headers,
      body = request.body,
    },
    code = 0,
    response_code = status,
    status = status == 0 or (status >= 200 and status < 400),
    time = vim.fn.localtime(),
    duration = 0,
    body_raw = "",
    body = "",
    json = {},
    headers = headers_text(headers),
    headers_tbl = headers,
    cookies = {},
    errors = "",
    stats = "",
    script_pre_output = "",
    script_post_output = "",
    assert_output = {},
    assert_status = true,
    file = request.file or "",
    buf_name = vim.fn.bufname(buf),
    line = request.show_icon_line_number or 0,
    buf = buf,
    _kulala_core = true,
    _kulala_http_stream = true,
    _kulala_body_type = "text",
    _kulala_media_type = type(content_type) == "string" and content_type or "text/plain",
  }

  local responses = DB.global_update().responses
  table.insert(responses, response)
  DB.global_update().current_response_pos = #responses
  M.response = response
  FS.write_file(GLOBALS.HEADERS_FILE, response.headers)
  FS.write_file(GLOBALS.BODY_FILE, "")
  return response
end

local function persist_body()
  if not M.response then return end
  FS.write_file(GLOBALS.BODY_FILE, M.response.body or "")
end

---@param event table
---@param request table
---@param ui_callback function
function M.on_event(event, request, ui_callback)
  if type(event) ~= "table" then return end

  if event.event == "headers" or event.event == "chunk" or event.event == "error" then
    ensure_response(request, event)
  end
  if not M.response then return end

  if event.event == "headers" then
    local status = tonumber(event.status) or M.response.response_code or 0
    M.response.response_code = status
    M.response.status = status == 0 or (status >= 200 and status < 400)
    if type(event.url) == "string" and event.url ~= "" then M.response.url = event.url end
    if type(event.headers) == "table" then
      M.response.headers_tbl = event.headers
      M.response.headers = headers_text(event.headers)
      FS.write_file(GLOBALS.HEADERS_FILE, M.response.headers)
      local content_type = event.headers["content-type"]
      if type(content_type) == "string" and content_type ~= "" then M.response._kulala_media_type = content_type end
    end
    if not opened then
      opened = true
      ui_callback(nil, 0, request.show_icon_line_number or 0, M.response.id)
    end
    return
  end

  if event.event == "chunk" then
    local data = type(event.data) == "string" and event.data or ""
    if data == "" then return end
    M.response.body = (M.response.body or "") .. data
    M.response.body_raw = M.response.body
    persist_body()
    if not opened then
      opened = true
      ui_callback(nil, 0, request.show_icon_line_number or 0, M.response.id)
    else
      require("kulala.ui").refresh_http_stream_body_if_visible()
    end
    return
  end

  if event.event == "error" then
    local err = type(event.error) == "string" and event.error or "stream failed"
    M.response.errors = vim.trim((M.response.errors or "") .. "\n" .. err)
    M.response.body = (M.response.body or "") .. "\n" .. err .. "\n"
    M.response.body_raw = M.response.body
    M.response.status = false
    persist_body()
    if opened then require("kulala.ui").refresh_http_stream_body_if_visible() end
  end
end

return M
