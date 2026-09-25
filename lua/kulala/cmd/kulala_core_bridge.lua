local Backend = require("kulala.backend")
local CONFIG = require("kulala.config")

local M = {}

---@type vim.SystemObj|nil
M.active_job = nil

---User-configured path from setup (`kulala_core.path`), if any.
---@return string|nil
local function configured_core_path()
  local p = CONFIG.get().kulala_core.path
  if type(p) == "string" and vim.trim(p) ~= "" then return vim.trim(p) end
  return nil
end

---Resolve kulala-core executable: explicit `kulala_core.path` wins;
---otherwise default download location
---from `Backend.get_bin_path()`, if executable.
---Returns nil if not found or not executable.
---@return string|nil
function M.executable_path()
  local configured = configured_core_path()
  if configured then
    if vim.fn.executable(configured) == 1 then return vim.fn.exepath(configured) end
    return nil
  end
  if vim.fn.executable(Backend.get_bin_path()) == 1 then return vim.fn.exepath(Backend.get_bin_path()) end
  return nil
end

function M.enabled()
  return M.executable_path() ~= nil
end

function M.require_enabled()
  local exe = M.executable_path()
  if exe then return exe end

  local configured = configured_core_path()
  if configured then error(("kulala_core.path is not executable: %s"):format(configured), 0) end
  error(
    "kulala-core not found. "
      .. "Either let kulala.nvim auto-download and install kulala-core or set `kulala_core.path` in setup.",
    0
  )
end

---Matches `packages/core/src/lib/runner/external-tools/paths.ts` (`getKulalaCoreDataDir`).
---@return string
local function default_kulala_core_data_dir()
  local explicit = vim.fn.getenv("KULALA_CORE_DATA_DIR")
  if type(explicit) == "string" and explicit ~= "" then return explicit end

  local sysname = (vim.uv.os_uname() or {}).sysname or ""
  if sysname == "Windows_NT" or vim.fn.has("win32") == 1 then
    local la = vim.fn.getenv("LOCALAPPDATA")
    if type(la) == "string" and la ~= "" then return la:gsub("\\", "/") .. "/kulala-core" end
    return vim.fn.expand("~/kulala-core")
  end

  if sysname == "Darwin" then return vim.fn.expand("~/Library/Application Support/kulala-core") end

  local xdg = vim.fn.getenv("XDG_DATA_HOME")
  if type(xdg) == "string" and xdg ~= "" then return xdg .. "/kulala-core" end

  return vim.fn.expand("~/.local/share/kulala-core")
end

---@return string
function M.effective_data_dir()
  local dir = CONFIG.get().kulala_core.data_dir
  if type(dir) == "string" and dir ~= "" then return dir end
  return default_kulala_core_data_dir()
end

local function env_with_data_dir()
  local env = vim.fn.environ()
  env.KULALA_CORE_DATA_DIR = M.effective_data_dir()
  return env
end

---Subprocess timeout (ms). Uses `kulala_core.timeout`, else 1 minute.
---@return number|nil 0 disables vim.system timeout (not recommended)
local function invoke_timeout_ms()
  local t = CONFIG.get().kulala_core.timeout
  if t == nil then return 60000 end
  if t == 0 then return nil end
  if type(t) == "number" and t > 0 then return t end
  return nil
end

---@param bufnr integer
---@param explicit_path string|nil
---@return string|nil filepath
---@return string cwd
---@return string display_path
function M.resolve_document_paths(bufnr, explicit_path)
  bufnr = bufnr or 0
  local candidates = {}

  local function push(p)
    if type(p) ~= "string" or p == "" then return end
    local abs = vim.fn.fnamemodify(p, ":p")
    if abs == "" then return end
    for _, c in ipairs(candidates) do
      if c == abs then return end
    end
    table.insert(candidates, abs)
  end

  push(explicit_path)
  push(vim.api.nvim_buf_get_name(bufnr))

  local filepath_core = nil
  for _, abs in ipairs(candidates) do
    if vim.fn.filereadable(abs) == 1 then
      local norm = (vim.fs and vim.fs.normalize(abs)) or abs
      filepath_core = (vim.loop.fs_realpath(norm)) or norm
      break
    end
  end

  local cwd = nil
  if filepath_core then
    local d = vim.fn.fnamemodify(filepath_core, ":h")
    if vim.fn.isdirectory(d) == 1 then cwd = d end
  end
  if not cwd and #candidates > 0 then
    local d = vim.fn.fnamemodify(candidates[1], ":h")
    if vim.fn.isdirectory(d) == 1 then cwd = d end
  end
  if not cwd then
    local n = vim.api.nvim_buf_get_name(bufnr)
    if type(n) == "string" and n ~= "" then
      local d = vim.fn.fnamemodify(n, ":p:h")
      if vim.fn.isdirectory(d) == 1 then cwd = d end
    end
  end
  if not cwd then cwd = vim.loop.cwd() end

  local display = filepath_core or candidates[1] or ""
  return filepath_core, cwd, display
end

---@param raw string|nil
---@return table|nil doc
local function decode_document_json(raw)
  if type(raw) ~= "string" then return nil end
  local trimmed = vim.trim(raw)
  if trimmed == "" then return nil end
  local ok, doc = pcall(vim.json.decode, trimmed)
  if ok and type(doc) == "table" and type(doc.blocks) == "table" then return doc end
  return nil
end

---@param stdout string|nil
---@return table|nil
function M.try_decode_wrapper(stdout)
  local raw = vim.trim(stdout or "")
  if raw == "" then return nil end
  local ok, w = pcall(vim.json.decode, raw)
  if ok and type(w) == "table" and w.type then return w end
  return nil
end

---@param payload table|nil
---@return boolean
local function payload_keep_alive(payload)
  return type(payload) == "table"
    and type(payload.content) == "string"
    and payload.content:find("@kulala-keep-alive-stream", 1, true) ~= nil
end

---One stdout line from a keep-alive run, or nil when it belongs to the final JSON document.
---@param line string
---@return table|nil
function M.parse_http_stream_line(line)
  local trimmed = vim.trim(line or "")
  if trimmed:sub(1, 1) ~= "{" then return nil end
  local ok, value = pcall(vim.json.decode, trimmed)
  if not ok or type(value) ~= "table" or value.type ~= "http-stream" then return nil end
  return value
end

---Stop the in-flight kulala-core subprocess (e.g. Ctrl+C interrupt).
---@return boolean stopped
function M.interrupt_active()
  local job = M.active_job
  if not job then return false end
  M.active_job = nil
  pcall(function()
    job:kill("sigterm")
  end)
  return true
end

---@param payload table
---@param cwd string|nil
---@param on_done fun(job: vim.SystemCompleted)
---@param hooks? { on_http_stream?: fun(event: table) }
function M.invoke_async(payload, cwd, on_done, hooks)
  local exe = M.require_enabled()
  hooks = hooks or {}
  local keep_alive = payload_keep_alive(payload)
  local opts = {
    stdin = vim.json.encode(payload) .. "\n",
    text = true,
    env = env_with_data_dir(),
  }
  if not keep_alive then
    local timeout_ms = invoke_timeout_ms()
    if timeout_ms then opts.timeout = timeout_ms end
  end
  if type(cwd) == "string" and cwd ~= "" and vim.fn.isdirectory(cwd) == 1 then opts.cwd = cwd end

  if not keep_alive then
    M.active_job = vim.system({ exe }, opts, function(job)
      if M.active_job == job then M.active_job = nil end
      on_done(job)
    end)
    return
  end

  local acc = {}
  local line_buf = ""
  local flushed = false

  local function take_line(line)
    local event = M.parse_http_stream_line(line)
    if event then
      if hooks.on_http_stream then vim.schedule(function()
        hooks.on_http_stream(event)
      end) end
      return
    end
    acc[#acc + 1] = line
    acc[#acc + 1] = "\n"
  end

  local function consume(data)
    if data == nil then
      if flushed then return end
      flushed = true
      if line_buf ~= "" then
        take_line(line_buf)
        line_buf = ""
      end
      return
    end
    line_buf = line_buf .. data
    while true do
      local nl = line_buf:find("\n", 1, true)
      if not nl then break end
      local line = line_buf:sub(1, nl - 1)
      line_buf = line_buf:sub(nl + 1)
      if line:sub(-1) == "\r" then line = line:sub(1, -2) end
      take_line(line)
    end
  end

  opts.stdout = function(_, data)
    consume(data)
  end

  M.active_job = vim.system({ exe }, opts, function(job)
    consume(nil)
    if M.active_job == job then M.active_job = nil end
    on_done {
      code = job.code,
      signal = job.signal,
      stdout = table.concat(acc),
      stderr = job.stderr,
    }
  end)
end

---@param payload table
---@param cwd string|nil
---@return vim.SystemCompleted
function M.invoke(payload, cwd)
  local done = false
  local completed ---@type vim.SystemCompleted
  M.invoke_async(payload, cwd, function(job)
    completed = job
    done = true
  end)
  local wait_ms = invoke_timeout_ms() or 600000
  if payload_keep_alive(payload) then wait_ms = 24 * 60 * 60 * 1000 end
  vim.wait(wait_ms, function()
    return done
  end, 20)
  return completed or { code = 124, stdout = "", stderr = "kulala-core subprocess timed out" }
end

---@param item table|nil
---@return boolean
local function is_prompt_item(item)
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

local function wrapper_has_prompt(wrapper)
  if not wrapper or wrapper.type ~= "responses" or type(wrapper.data) ~= "table" then return false end
  for _, item in ipairs(wrapper.data) do
    if is_prompt_item(item) then return true end
  end
  return false
end

---@param job vim.SystemCompleted
---@return table|nil catalog
---@return string|nil err
local function catalog_from_job(job)
  local raw = vim.trim(job.stdout or "")
  if raw == "" then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core environments failed"
  end
  local ok, catalog = pcall(vim.json.decode, raw)
  if ok and type(catalog) == "table" and type(catalog.environments) == "table" then return catalog, nil end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core environments failed"
  end
  return nil, "invalid kulala-core environments output"
end

---@param cwd string|nil
---@return table|nil catalog `{ environments, $kulalaShared? }`
---@return string|nil err
function M.list_environments(cwd)
  M.require_enabled()
  cwd = cwd or vim.loop.cwd()
  local payload = { action = "environments", cwd = cwd }
  local job = M.invoke(payload, cwd)
  return catalog_from_job(job)
end

---@param cwd string|nil
---@param on_done fun(catalog: table|nil, err: string|nil)
function M.list_environments_async(cwd, on_done)
  M.require_enabled()
  cwd = cwd or vim.loop.cwd()
  local payload = { action = "environments", cwd = cwd }
  M.invoke_async(payload, cwd, function(job)
    vim.schedule(function()
      on_done(catalog_from_job(job))
    end)
  end)
end

function M.parse_document(content, filepath, cwd_override)
  M.require_enabled()
  local cwd = cwd_override
  if not cwd and type(filepath) == "string" and filepath ~= "" then
    local d = vim.fn.fnamemodify(filepath, ":h")
    if vim.fn.isdirectory(d) == 1 then cwd = d end
  end
  local payload = { action = "parse", content = content }
  if type(filepath) == "string" and filepath ~= "" then payload.filepath = filepath end
  local job = M.invoke(payload, cwd)

  local doc = decode_document_json(job.stdout) or decode_document_json(job.stderr)
  if doc then return doc, nil end

  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core parse failed"
  end
  return nil, "invalid kulala-core parse output"
end

---@param job vim.SystemCompleted
---@return table|nil wrapper
---@return string|nil err
local function run_result_from_job(job)
  local wrapper = M.try_decode_wrapper(job.stdout)
  local is_prompt = wrapper_has_prompt(wrapper)

  if job.code ~= 0 and not is_prompt then
    local err = vim.trim(job.stderr or "")
    if err == "" then
      if job.code == 124 or job.code == -1 then
        err = "kulala-core subprocess timed out"
      else
        err = "kulala-core run failed (exit " .. tostring(job.code) .. ")"
      end
    end
    return nil, err
  end

  if not wrapper or type(wrapper) ~= "table" then return nil, "invalid kulala-core run output" end
  return wrapper, nil
end

function M.run(payload, cwd)
  M.require_enabled()
  payload.action = "run"
  local job = M.invoke(payload, cwd)
  return run_result_from_job(job)
end

---Non-blocking run; calls `on_done(wrapper, err)` on the main loop when finished.
---@param payload table
---@param cwd string|nil
---@param on_done fun(wrapper: table|nil, err: string|nil)
---@param hooks? { on_http_stream?: fun(event: table) }
function M.run_async(payload, cwd, on_done, hooks)
  M.require_enabled()
  payload.action = "run"
  M.invoke_async(payload, cwd, function(job)
    local wrapper, err = run_result_from_job(job)
    on_done(wrapper, err)
  end, hooks)
end

---@param job vim.SystemCompleted
---@return table|nil wrapper
---@return string|nil err
local function continue_result_from_job(job)
  local wrapper = M.try_decode_wrapper(job.stdout)
  if wrapper then return wrapper, nil end
  if job.code ~= 0 then
    local err = vim.trim(job.stderr or "")
    if err == "" then err = "kulala-core continue failed (exit " .. tostring(job.code) .. ")" end
    return nil, err
  end
  return nil, "invalid kulala-core continue output"
end

function M.continue(payload, cwd)
  M.require_enabled()
  payload.action = "continue"
  local job = M.invoke(payload, cwd)
  return continue_result_from_job(job)
end

---@param payload table
---@param cwd string|nil
---@param on_done fun(wrapper: table|nil, err: string|nil)
function M.continue_async(payload, cwd, on_done)
  M.require_enabled()
  payload.action = "continue"
  M.invoke_async(payload, cwd, function(job)
    local wrapper, err = continue_result_from_job(job)
    on_done(wrapper, err)
  end)
end

---@param stdout string|nil
---@return table|nil
local function decode_action_response(stdout)
  local raw = vim.trim(stdout or "")
  if raw == "" then return nil end
  local ok, res = pcall(vim.json.decode, raw)
  if ok and type(res) == "table" then return res end
  return nil
end

---@param job vim.SystemCompleted
---@return table|nil
---@return string|nil
local function decode_job_stdout(job)
  local res = decode_action_response(job.stdout)
  if res then return res, nil end
  if job.code ~= 0 then
    local err = vim.trim(job.stderr or "")
    if err == "" then err = "kulala-core subprocess failed (exit " .. tostring(job.code) .. ")" end
    return nil, err
  end
  return nil, "invalid kulala-core output"
end

---@param key_or_keys string|string[]|nil nil clears all global script variables
---@return boolean ok
---@return string|nil err
function M.clear_globals(key_or_keys)
  M.require_enabled()
  local names = nil
  if type(key_or_keys) == "string" then
    names = { key_or_keys }
  elseif type(key_or_keys) == "table" then
    names = key_or_keys
  end
  local payload = { action = "clear_globals" }
  if names then payload.names = names end
  local job = M.invoke(payload, nil)
  local res = decode_action_response(job.stdout)
  if res and res.success == true then return true, nil end
  if res and res.error then return false, res.error end
  if job.code ~= 0 then
    return false, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core clear_globals failed"
  end
  return false, "invalid kulala-core clear_globals output"
end

---@param op string
---@param args table|nil
---@param cwd string|nil
---@return string|nil value
---@return string|nil err
function M.crypto(op, args, cwd)
  M.require_enabled()
  local payload = vim.tbl_extend("force", { action = "crypto", op = op }, args or {})
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.success == true and res.value ~= nil then return tostring(res.value), nil end
  if res and res.error then return nil, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core crypto failed"
  end
  return nil, "invalid kulala-core crypto output"
end

---@param body table|string|nil
---@return string
local function response_body_text(body)
  if type(body) == "table" and body.type == "json" then
    if type(body.formatted) == "string" then return body.formatted end
    return vim.json.encode(body.content) or ""
  end
  if type(body) == "table" and body.type == "text" then return body.content or "" end
  if type(body) == "table" and body.type == "binary" then
    local media_type = body.mediaType or "application/octet-stream"
    local bytes = tonumber(body.byteLength) or 0
    local size
    if bytes < 1024 then
      size = ("%d B"):format(bytes)
    elseif bytes < 1024 * 1024 then
      size = ("%.1f KB"):format(bytes / 1024)
    else
      size = ("%.1f MB"):format(bytes / (1024 * 1024))
    end
    if type(media_type) == "string" and media_type:lower():find("^image/", 1, false) then
      return ("Image response (%s, %s)"):format(media_type, size)
    end
    return ("Binary response body (%s, %s)"):format(media_type, size)
  end
  if type(body) == "string" then return body end
  return ""
end

---@param opts {
---   url: string,
---   method?: string,
---   headers?: table,
---   body?: string,
---   insecure?: boolean,
---   timeoutSec?: number,
---   connectionTimeoutSec?: number,
--- }
---@param cwd string|nil
---@return table|nil result { status, headers, body, url }
---@return string|nil err
function M.http_request(opts, cwd)
  M.require_enabled()
  local response_format = CONFIG.get().response_format or {}
  local payload = vim.tbl_extend("force", {
    action = "http_request",
    url = opts.url,
    method = opts.method or "GET",
    headers = opts.headers or {},
    body = opts.body,
    insecure = opts.insecure,
    timeoutSec = opts.timeoutSec,
    connectionTimeoutSec = opts.connectionTimeoutSec,
    responseFormat = {
      indent = response_format.indent,
      expand_tabs = response_format.expand_tabs,
      sort_keys = response_format.sort_keys,
    },
  }, {})
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.success == true then
    return {
      status = res.status,
      headers = res.headers or {},
      body = response_body_text(res.body),
      url = res.url or opts.url,
    },
      nil
  end
  if res and res.error then return nil, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core http_request failed"
  end
  return nil, "invalid kulala-core http_request output"
end

---Apply a jq filter to a stored raw response body (no HTTP re-request).
---@param opts { rawBody: string, filter: string, contentType?: string }
---@param cwd string|nil
---@return table|nil result `{ text, body_type?, media_type? }`
---@return string|nil err
function M.apply_jq_filter(opts, cwd)
  M.require_enabled()
  local response_format = CONFIG.get().response_format or {}
  local payload = {
    action = "apply_jq_filter",
    rawBody = opts.rawBody,
    filter = opts.filter,
    contentType = opts.contentType,
    responseFormat = {
      indent = response_format.indent,
      expand_tabs = response_format.expand_tabs,
      sort_keys = response_format.sort_keys,
    },
  }
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.success == true and type(res.filteredBody) == "table" then
    return {
      text = response_body_text(res.filteredBody),
      body_type = res.filteredBody.type,
      media_type = res.filteredBody.mediaType,
    },
      nil
  end
  if res and res.error then return nil, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core apply_jq_filter failed"
  end
  return nil, "invalid kulala-core apply_jq_filter output"
end

---Convert an image body to PNG for terminal graphics protocols.
---@param opts { content: string, mediaType?: string, target?: "png" }
---@param cwd string|nil
---@return table|nil result `{ content, mediaType, byteLength, convertedFrom? }`
---@return string|nil err
function M.convert_image(opts, cwd)
  M.require_enabled()
  local payload = {
    action = "convert_image",
    content = opts.content,
    mediaType = opts.mediaType,
    target = opts.target or "png",
  }
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.success == true and type(res.content) == "string" then
    return {
      content = res.content,
      mediaType = res.mediaType or "image/png",
      byteLength = res.byteLength or 0,
      convertedFrom = res.convertedFrom,
    },
      nil
  end
  if res and res.error then return nil, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core convert_image failed"
  end
  return nil, "invalid kulala-core convert_image output"
end

---@param bufnr? integer
---@return boolean
local function valid_bufnr(bufnr)
  return type(bufnr) == "number" and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr)
end

---@param line string
---@param end_col integer 1-based column after the last typed character (Vim/LSP end)
---@param new_text string
---@param label? string
---@return integer start_col 0-based LSP start of replaced range
---@return integer end_col 0-based LSP exclusive end of replaced range
---@return string|nil closing_suffix appended when `{{` is not closed yet
local function completion_replace_range(line, end_col, new_text, label)
  end_col = math.max(0, math.min(end_col, #line))
  local before = end_col > 0 and line:sub(1, end_col) or ""

  local open_col1 = nil
  local search_from = 1
  while true do
    local next_open = before:find("{{", search_from, true)
    if not next_open then break end
    open_col1 = next_open
    search_from = next_open + 1
  end

  if open_col1 then
    local inner_start = open_col1 + 2

    local function find_template_close(from)
      local i = from
      while i < #line do
        if line:sub(i, i + 1) == "{{" then
          local nested_close = find_template_close(i + 2)
          if not nested_close then return nil end
          i = nested_close + 2
        elseif line:sub(i, i + 1) == "}}" then
          return i
        else
          i = i + 1
        end
      end
      return nil
    end

    local close_col1 = find_template_close(inner_start)
    if close_col1 then
      local replace_end = math.max(inner_start, math.min(end_col, close_col1 - 1))
      return inner_start - 1, replace_end, nil
    end

    local typed = before:sub(inner_start)
    if not typed:find("}", 1, true) then
      local function template_var_replace_end(from, limit)
        local i = from
        while i <= limit do
          local ch = line:sub(i, i)
          if not ch:match("[%w%$%.%[%]%*%-]") then break end
          i = i + 1
        end
        return math.max(from, i - 1)
      end
      local replace_end = template_var_replace_end(inner_start, end_col)
      return inner_start - 1, replace_end, "}}"
    end
  end

  local function longest_suffix_prefix_match(candidate)
    local max_len = math.min(#before, #candidate)
    for len = max_len, 1, -1 do
      local suffix = before:sub(#before - len + 1)
      if candidate:sub(1, len) == suffix then return len end
    end
    return 0
  end

  local match_len = longest_suffix_prefix_match(new_text)
  if match_len == 0 and type(label) == "string" and label ~= new_text then
    match_len = longest_suffix_prefix_match(label)
  end
  if match_len > 0 then return end_col - match_len, end_col, nil end

  local template_prefix = before:match("{{([^}]*)$")
  if template_prefix ~= nil then return end_col - #template_prefix, end_col, "}}" end

  -- Include `$` (not a Vim keyword char); avoid matching only `kul` after `$`.
  local word = before:match("([%w$%.]+)$") or ""
  return end_col - #word, end_col, nil
end

---blink.cmp workaround for `$kulala.*` plus fallback textEdit when kulala-core did not set one.
---@param items table[]
---@param bufnr integer
---@param position table LSP position (`line`/`character`, 0-based)
function M.apply_completion_text_edits(items, bufnr, position)
  if type(items) ~= "table" or type(position) ~= "table" then return end
  local line0 = position.line
  if type(line0) ~= "number" then return end

  local line = vim.api.nvim_buf_get_lines(bufnr, line0, line0 + 1, false)[1] or ""

  -- Vim cursor col is 1-based on the current character; include it in the replaced range.
  -- (`col - 1` wrongly drops the last typed character, e.g. `u` in `$ku`.)
  local end_col0 = position.character + 1
  local wins = vim.fn.win_findbuf(bufnr)
  if wins[1] then
    local cursor = vim.api.nvim_win_get_cursor(wins[1])
    if cursor[1] - 1 == line0 then end_col0 = math.min(cursor[2], #line) end
  end
  if type(end_col0) ~= "number" then return end

  local plain_text = vim.lsp.protocol.InsertTextFormat.PlainText

  for _, item in ipairs(items) do
    local new_text = item.insertText or item.label
    if not new_text then goto continue end

    -- blink.cmp + vim.snippet.expand strip a prefix that excludes `$` (e.g. `$kul` → `.prompt`).
    if type(item.label) == "string" and item.label:match("^%$kulala") then item.insertTextFormat = plain_text end

    if item.textEdit then
      item.insertText = nil
      goto continue
    end

    local start_col0, end_col0_edit, closing_suffix = completion_replace_range(line, end_col0, new_text, item.label)
    if closing_suffix then new_text = new_text .. closing_suffix end

    item.textEdit = {
      range = {
        start = { line = line0, character = start_col0 },
        ["end"] = { line = line0, character = end_col0_edit },
      },
      newText = new_text,
    }
    item.insertText = nil
    ::continue::
  end
end

---@param bufnr? integer
---@param lsp_position? table|nil LSP position (`line`/`character`, 0-based)
---@return table|nil payload
---@return string|nil cwd
local function cursor_request_payload(bufnr, lsp_position)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not valid_bufnr(bufnr) then return nil, nil end
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local filepath, cwd = M.resolve_document_paths(bufnr, nil)
  local line1, col1
  if lsp_position and type(lsp_position.line) == "number" and type(lsp_position.character) == "number" then
    line1 = lsp_position.line + 1
    col1 = lsp_position.character + 1
    local wins = vim.fn.win_findbuf(bufnr)
    if wins[1] then
      local cursor = vim.api.nvim_win_get_cursor(wins[1])
      if cursor[1] == line1 then col1 = math.max(col1, cursor[2]) end
    end
  else
    line1 = vim.fn.line(".")
    col1 = math.max(1, vim.fn.col("."))
  end
  local payload = {
    content = content,
    line = line1,
    column = col1,
    env = require("kulala.parser.env").get_current_env() or "default",
    filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr }),
  }
  if filepath then payload.filepath = filepath end
  return payload, cwd
end

---@param bufnr? integer
---@return table|nil payload
---@return string|nil cwd
local function buffer_payload(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not valid_bufnr(bufnr) then return nil, nil end
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
  local filepath, cwd = M.resolve_document_paths(bufnr, nil)
  local payload = { content = content }
  if filepath then payload.filepath = filepath end
  return payload, cwd
end

---@param host string|nil When omitted, clears all cached GraphQL schemas.
---@return boolean ok
---@return string|nil err
---@return table|nil result { cleared, hosts? }
function M.clear_graphql_schema(host)
  M.require_enabled()
  local payload = { action = "clear_graphql_schema" }
  if type(host) == "string" and host ~= "" then payload.host = host end
  local job = M.invoke(payload, nil)
  local res = decode_action_response(job.stdout)
  if res and res.success == true then return true, nil, res end
  if res and res.error then return false, res.error, nil end
  if job.code ~= 0 then
    return false,
      vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core clear_graphql_schema failed",
      nil
  end
  return false, "invalid kulala-core clear_graphql_schema output", nil
end

---Fetch and cache GraphQL introspection for the request at cursor.
---@param bufnr? integer
---@return table|nil result { ok, host?, fromCache?, error? }
---@return string|nil err
function M.graphql_introspect(bufnr)
  M.require_enabled()
  local payload, cwd = cursor_request_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "graphql_introspect"
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.ok == true and type(res.host) == "string" then return res, nil end
  if res and res.error then return res, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core graphql_introspect failed"
  end
  return nil, "invalid kulala-core graphql_introspect output"
end

---@param cache_key string|nil When omitted, clears all cached OpenAPI schemas.
---@return boolean ok
---@return string|nil err
---@return table|nil result { cleared, keys? }
function M.clear_openapi_schema(cache_key)
  M.require_enabled()
  local payload = { action = "clear_openapi_schema" }
  if type(cache_key) == "string" and cache_key ~= "" then payload.cacheKey = cache_key end
  local job = M.invoke(payload, nil)
  local res = decode_action_response(job.stdout)
  if res and res.success == true then return true, nil, res end
  if res and res.error then return false, res.error, nil end
  if job.code ~= 0 then
    return false,
      vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core clear_openapi_schema failed",
      nil
  end
  return false, "invalid kulala-core clear_openapi_schema output", nil
end

---Load OpenAPI spec and return explorer tree for block at cursor.
---@param bufnr? integer
---@param line? integer 1-based line (defaults to cursor)
---@param column? integer 1-based column
---@return table|nil result { ok, openapi? }
---@return string|nil err
function M.openapi_load(bufnr, line, column)
  M.require_enabled()
  local payload, cwd = cursor_request_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  if type(line) == "number" then payload.line = line end
  if type(column) == "number" then payload.column = column end
  payload.action = "openapi_load"
  payload.env = require("kulala.parser.env").get_current_env() or "default"
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.ok == true and type(res.openapi) == "table" then return res, nil end
  if res and res.error then return res, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core openapi_load failed"
  end
  return nil, "invalid kulala-core openapi_load output"
end

---Run one OpenAPI operation with scripts inherited from parent block.
---@param bufnr? integer HTTP buffer
---@param operation_key string e.g. `GET /pets`
---@param line? integer 1-based line on openapi block
---@param column? integer 1-based column
---@return table|nil item kulala-core run result item
---@return string|nil err
function M.openapi_run_operation(bufnr, operation_key, line, column, parameter_overrides)
  M.require_enabled()
  local payload, cwd = buffer_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "openapi_run_operation"
  payload.operationKey = operation_key
  payload.env = require("kulala.parser.env").get_current_env() or "default"
  if type(parameter_overrides) == "table" and not vim.tbl_isempty(parameter_overrides) then
    payload.parameterOverrides = parameter_overrides
  end
  if type(line) == "number" then
    payload.line = line
    payload.column = column or 1
  else
    local pos = vim.api.nvim_win_get_cursor(0)
    payload.line = pos[1]
    payload.column = pos[2]
  end
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.success == true then return res, nil end
  if res and res.error then return res, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core openapi_run_operation failed"
  end
  return nil, "invalid kulala-core openapi_run_operation output"
end

---Serialize one OpenAPI operation as a standalone `.http` block.
---@param bufnr? integer HTTP buffer
---@param operation_key string e.g. `GET /pets`
---@param line? integer 1-based line on openapi block
---@param column? integer 1-based column
---@return string|nil content
---@return string|nil err
function M.openapi_to_http(bufnr, operation_key, line, column, parameter_overrides)
  M.require_enabled()
  local payload, cwd = buffer_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "openapi_to_http"
  payload.operationKey = operation_key
  payload.env = require("kulala.parser.env").get_current_env() or "default"
  if type(parameter_overrides) == "table" and not vim.tbl_isempty(parameter_overrides) then
    payload.parameterOverrides = parameter_overrides
  end
  if type(line) == "number" then
    payload.line = line
    payload.column = column or 1
  else
    local pos = vim.api.nvim_win_get_cursor(0)
    payload.line = pos[1]
    payload.column = pos[2]
  end
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.ok == true and type(res.content) == "string" then return res.content, nil end
  if res and res.error then return nil, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core openapi_to_http failed"
  end
  return nil, "invalid kulala-core openapi_to_http output"
end

---@param on_done fun(res: table|nil, err: string|nil)
local function invalid_buffer_async(on_done)
  vim.schedule(function()
    on_done(nil, "invalid buffer")
  end)
end

---@param bufnr? integer
---@return string[]|nil lines
---@return string|nil err
function M.inspect_request_at_cursor(bufnr)
  M.require_enabled()
  local payload, cwd = cursor_request_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "inspect_request"
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.ok == true and type(res.lines) == "table" then return res.lines, nil end
  if res and res.error then return nil, res.error end
  if res and res.prompt then return nil, "prompt required" end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core inspect_request failed"
  end
  local out = vim.trim(job.stdout or "")
  local err = vim.trim(job.stderr or "")
  local detail = out ~= "" and out:sub(1, 200) or err:sub(1, 200)
  if detail ~= "" then return nil, "invalid kulala-core inspect_request output: " .. detail end
  return nil, "invalid kulala-core inspect_request output"
end

---@param bufnr? integer
---@param user_agent? string
---@return string|nil curl
---@return string|nil err
function M.to_curl_at_cursor(bufnr, user_agent)
  M.require_enabled()
  local payload, cwd = cursor_request_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "to_curl"
  if user_agent then payload.userAgent = user_agent end
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and res.ok == true and type(res.curl) == "string" then return res.curl, nil end
  if res and res.error then return nil, res.error end
  if res and res.prompt then return nil, "prompt required" end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core to_curl failed"
  end
  return nil, "invalid kulala-core to_curl output"
end

---@param bufnr? integer
---@return table|nil completion_list { isIncomplete, items }
---@return string|nil err
function M.lsp_completion(bufnr)
  M.require_enabled()
  local payload, cwd = cursor_request_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "lsp_completion"
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and type(res.items) == "table" then return res, nil end
  if res and res.error then return nil, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core lsp_completion failed"
  end
  return nil, "invalid kulala-core lsp_completion output"
end

---@param bufnr? integer
---@param lsp_params? table|nil `textDocument/completion` params (uses `position` when set)
---@param on_done fun(res: table|nil, err: string|nil)
function M.lsp_completion_async(bufnr, lsp_params, on_done)
  M.require_enabled()
  local position = type(lsp_params) == "table" and lsp_params.position or nil
  local payload, cwd = cursor_request_payload(bufnr, position)
  if not payload then return invalid_buffer_async(on_done) end
  payload.action = "lsp_completion"
  M.invoke_async(payload, cwd, function(job)
    local res, err = decode_job_stdout(job)
    if res and type(res.items) ~= "table" then
      res = nil
      err = "invalid kulala-core lsp_completion output"
    end
    vim.schedule(function()
      on_done(res, err)
    end)
  end)
end

---@param bufnr? integer
---@return table|nil hover { contents = ... }
---@return string|nil err
function M.lsp_hover(bufnr)
  M.require_enabled()
  local payload, cwd = cursor_request_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "lsp_hover"
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if res and type(res.contents) == "table" then return res, nil end
  if res and res.error then return nil, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core lsp_hover failed"
  end
  return nil, "invalid kulala-core lsp_hover output"
end

---@param bufnr? integer
---@param on_done fun(res: table|nil, err: string|nil)
function M.lsp_hover_async(bufnr, on_done)
  M.require_enabled()
  local payload, cwd = cursor_request_payload(bufnr)
  if not payload then return invalid_buffer_async(on_done) end
  payload.action = "lsp_hover"
  M.invoke_async(payload, cwd, function(job)
    local res, err = decode_job_stdout(job)
    if res and type(res.contents) ~= "table" then
      res = nil
      err = "invalid kulala-core lsp_hover output"
    end
    vim.schedule(function()
      on_done(res, err)
    end)
  end)
end

---@param bufnr? integer
---@return table[]|nil symbols DocumentSymbol[]
---@return string|nil err
function M.lsp_symbols(bufnr)
  M.require_enabled()
  local payload, cwd = buffer_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "lsp_symbols"
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if type(res) == "table" then return res, nil end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core lsp_symbols failed"
  end
  return nil, "invalid kulala-core lsp_symbols output"
end

---@param bufnr? integer
---@param on_done fun(res: table|nil, err: string|nil)
function M.lsp_symbols_async(bufnr, on_done)
  M.require_enabled()
  local payload, cwd = buffer_payload(bufnr)
  if not payload then return invalid_buffer_async(on_done) end
  payload.action = "lsp_symbols"
  M.invoke_async(payload, cwd, function(job)
    local res, err = decode_job_stdout(job)
    if type(res) ~= "table" then
      res = nil
      err = err or "invalid kulala-core lsp_symbols output"
    end
    vim.schedule(function()
      on_done(res, err)
    end)
  end)
end

---@param bufnr? integer
---@return table[]|nil diags Diagnostic[]
---@return string|nil err
function M.lsp_diagnostics(bufnr)
  M.require_enabled()
  local payload, cwd = buffer_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "lsp_diagnostics"
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if type(res) == "table" then return res, nil end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core lsp_diagnostics failed"
  end
  return nil, "invalid kulala-core lsp_diagnostics output"
end

---@param bufnr? integer
---@param on_done fun(res: table|nil, err: string|nil)
function M.lsp_diagnostics_async(bufnr, on_done)
  M.require_enabled()
  local payload, cwd = buffer_payload(bufnr)
  if not payload then return invalid_buffer_async(on_done) end
  payload.action = "lsp_diagnostics"
  M.invoke_async(payload, cwd, function(job)
    local res, err = decode_job_stdout(job)
    if type(res) ~= "table" then
      res = nil
      err = err or "invalid kulala-core lsp_diagnostics output"
    end
    vim.schedule(function()
      on_done(res, err)
    end)
  end)
end

---@param bufnr? integer
---@param lsp_params? table|nil `textDocument/inlayHint` params (uses `range` when set)
---@return table[]|nil hints InlayHint[]
---@return string|nil err
function M.lsp_inlay_hints(bufnr, lsp_params)
  M.require_enabled()
  local payload, cwd = buffer_payload(bufnr)
  if not payload then return nil, "invalid buffer" end
  payload.action = "lsp_inlay_hints"
  payload.env = require("kulala.parser.env").get_current_env() or "default"
  if type(lsp_params) == "table" and type(lsp_params.range) == "table" then payload.range = lsp_params.range end
  local job = M.invoke(payload, cwd)
  local res = decode_action_response(job.stdout)
  if type(res) == "table" then return res, nil end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core lsp_inlay_hints failed"
  end
  return nil, "invalid kulala-core lsp_inlay_hints output"
end

---@param bufnr? integer
---@param lsp_params? table|nil `textDocument/inlayHint` params (uses `range` when set)
---@param on_done fun(res: table[]|nil, err: string|nil)
function M.lsp_inlay_hints_async(bufnr, lsp_params, on_done)
  M.require_enabled()
  local payload, cwd = buffer_payload(bufnr)
  if not payload then return invalid_buffer_async(on_done) end
  payload.action = "lsp_inlay_hints"
  payload.env = require("kulala.parser.env").get_current_env() or "default"
  if type(lsp_params) == "table" and type(lsp_params.range) == "table" then payload.range = lsp_params.range end
  M.invoke_async(payload, cwd, function(job)
    local res, err = decode_job_stdout(job)
    if type(res) ~= "table" then
      res = nil
      err = err or "invalid kulala-core lsp_inlay_hints output"
    end
    vim.schedule(function()
      on_done(res, err)
    end)
  end)
end

---@param curl string
---@return string[]|nil lines
---@return string|nil err
function M.from_curl(curl)
  M.require_enabled()
  local job = M.invoke({ action = "from_curl", curl = curl }, nil)
  local res = decode_action_response(job.stdout)
  if res and res.ok == true and type(res.lines) == "table" then return res.lines, nil end
  if res and res.error then return nil, res.error end
  if job.code ~= 0 then
    return nil, vim.trim(job.stderr or "") ~= "" and vim.trim(job.stderr) or "kulala-core from_curl failed"
  end
  return nil, "invalid kulala-core from_curl output"
end

---Start a long-lived WebSocket session (native kulala-core, replaces websocat).
---@param opts { url: string, body?: string, headers?: table, messages?: table, timeoutMs?: number }
---@param handlers { on_stdout: function, on_stderr: function, on_exit: function }
---@param cwd string|nil
---@return vim.SystemObj|nil
function M.websocket_start(opts, handlers, cwd)
  M.require_enabled()
  local exe = M.executable_path()
  if not exe then return nil end

  local tmp = vim.fn.tempname() .. ".json"
  local payload = {
    url = opts.url,
    headers = opts.headers,
  }
  if type(opts.messages) == "table" then
    payload.messages = opts.messages
    if type(opts.timeoutMs) == "number" then payload.timeoutMs = opts.timeoutMs end
  else
    payload.body = opts.body
  end
  vim.fn.writefile({ vim.json.encode(payload) }, tmp)

  return vim.system({ exe, "--websocket", "-i", tmp }, {
    stdin = true,
    text = true,
    cwd = cwd,
    env = env_with_data_dir(),
    stdout = handlers.on_stdout,
    stderr = handlers.on_stderr,
  }, handlers.on_exit)
end

---@param err string|nil
---@return boolean
function M.is_preview_unsupported_err(err)
  return type(err) == "string" and err:find("cannot be shown as curl or HTTP inspect preview", 1, true) ~= nil
end

return M
