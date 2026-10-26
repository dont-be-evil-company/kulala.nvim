---Long-lived kulala-core client. One connection per data dir and core version.
---Falls back to the caller when the daemon cannot be reached before a request is sent.
local M = {}

local PROTOCOL = 1
local START_TIMEOUT_MS = 10000
local is_win = vim.fn.has("win32") == 1

local state = {
  sock = nil,
  buf = "",
  opening = false,
  hello_ok = false,
  pid = nil,
  version = nil,
  version_exe = nil,
  waiters = {},
  pending = {},
  active_id = nil,
  search_id = nil,
  seq = 0,
  generation = 0,
}

local function log_fallback(err)
  local ok, Logger = pcall(require, "kulala.logger")
  if ok and type(Logger.info) == "function" then
    Logger.info("kulala-core daemon unavailable (" .. tostring(err) .. "); using a one-shot process")
  end
end

local function pid_alive(pid)
  if type(pid) ~= "number" or pid <= 0 then return false end
  local ok, err = vim.uv.kill(pid, 0)
  if ok then return true end
  return err == "EPERM"
end

local function sanitize_version(version)
  local cleaned = vim.trim(tostring(version or "")):gsub("[^A-Za-z0-9._%-]", "_")
  if cleaned == "" then return "unknown" end
  return cleaned
end

local function meta_path(data_dir, version)
  return vim.fs.joinpath(data_dir, "daemon", sanitize_version(version) .. ".json")
end

local function lock_path(data_dir, version)
  return vim.fs.joinpath(data_dir, "daemon", sanitize_version(version) .. ".lock")
end

local function read_file(path)
  local fd = vim.uv.fs_open(path, "r", 438)
  if not fd then return nil end
  local stat = vim.uv.fs_fstat(fd)
  local data = stat and vim.uv.fs_read(fd, stat.size, 0) or nil
  vim.uv.fs_close(fd)
  if type(data) ~= "string" or data == "" then return nil end
  return data
end

local function present(value)
  return value ~= nil and value ~= vim.NIL
end

local function read_meta(path)
  local raw = read_file(path)
  if not raw then return nil end
  local ok, meta = pcall(vim.json.decode, raw)
  if not ok or type(meta) ~= "table" then return nil end
  if type(meta.token) ~= "string" or meta.token == "" then return nil end
  if type(meta.endpoint) ~= "string" or meta.endpoint == "" then return nil end
  if meta.protocol ~= PROTOCOL or not pid_alive(meta.pid) then return nil end
  return meta
end

local function lock_is_stale(path, meta)
  local raw = read_file(path)
  if not raw then return true end
  local ok, lock = pcall(vim.json.decode, raw)
  if not ok or type(lock) ~= "table" then return true end
  if not pid_alive(lock.pid) then return true end
  local started = tonumber(lock.startedAt) or 0
  local age = (os.time() * 1000) - started
  return age > 15000 and vim.uv.fs_stat(meta) == nil
end

local function mkdir_p(path)
  if path == nil or path == "" or path == "." or path == "/" then return end
  if vim.uv.fs_stat(path) then return end
  local parent = vim.fs.dirname(path)
  if parent and parent ~= path then mkdir_p(parent) end
  vim.uv.fs_mkdir(path, tonumber("700", 8))
end

local function try_lock(path)
  mkdir_p(vim.fs.dirname(path))
  local fd, err = vim.uv.fs_open(path, "wx", tonumber("600", 8))
  if not fd then return false, err end
  local body = vim.json.encode { pid = vim.uv.os_getpid(), startedAt = os.time() * 1000 }
  vim.uv.fs_write(fd, body, 0)
  vim.uv.fs_close(fd)
  return true
end

local function env_list(env)
  local list = {}
  for key, value in pairs(env or {}) do
    if type(key) == "string" and type(value) == "string" then list[#list + 1] = key .. "=" .. value end
  end
  return list
end

local function ignore_fd(mode)
  return vim.uv.fs_open(is_win and "NUL" or "/dev/null", mode, 438)
end

local function spawn_daemon(exe, env)
  local stdin = ignore_fd("r")
  local stdout = ignore_fd("w")
  local stderr = ignore_fd("w")
  local handle
  handle = vim.uv.spawn(exe, {
    args = { "--daemon" },
    detached = true,
    hide = true,
    env = env_list(env),
    stdio = { stdin, stdout, stderr },
  }, function()
    if handle and not handle:is_closing() then handle:close() end
  end)
  if stdin then vim.uv.fs_close(stdin) end
  if stdout then vim.uv.fs_close(stdout) end
  if stderr then vim.uv.fs_close(stderr) end
  if not handle then return nil end
  handle:unref()
  return handle
end

local function close_sock()
  local sock = state.sock
  state.sock = nil
  state.hello_ok = false
  state.buf = ""
  if sock and not sock:is_closing() then
    sock:read_stop()
    sock:close()
  end
end

local function finish(entry, result)
  if not entry or entry.done then return end
  entry.done = true
  if state.pending[entry.id] == entry then state.pending[entry.id] = nil end
  if state.active_id == entry.id then state.active_id = nil end
  if state.search_id == entry.id then state.search_id = nil end
  if entry.timer and not entry.timer:is_closing() then
    entry.timer:stop()
    entry.timer:close()
  end
  entry.timer = nil
  local cb = entry.on_done
  vim.schedule(function()
    if cb then cb(result) end
  end)
end

local function drop_unsent(entry, reason)
  if not entry or entry.done then return end
  entry.done = true
  if state.pending[entry.id] == entry then state.pending[entry.id] = nil end
  if state.active_id == entry.id then state.active_id = nil end
  if state.search_id == entry.id then state.search_id = nil end
  if entry.timer and not entry.timer:is_closing() then
    entry.timer:stop()
    entry.timer:close()
  end
  entry.timer = nil
  local cb = entry.on_unavailable
  vim.schedule(function()
    log_fallback(reason or "request was not sent")
    if cb then cb() end
  end)
end

local function fail_open(generation, err)
  if state.generation ~= generation or not state.opening then return end
  state.generation = state.generation + 1
  state.opening = false
  close_sock()
  local waiters = state.waiters
  state.waiters = {}
  for _, waiter in ipairs(waiters) do
    vim.schedule(function()
      waiter(false, err)
    end)
  end
end

local function succeed_open(generation)
  if state.generation ~= generation or not state.opening then return end
  state.opening = false
  local waiters = state.waiters
  state.waiters = {}
  for _, waiter in ipairs(waiters) do
    vim.schedule(function()
      waiter(true)
    end)
  end
end

local function on_disconnect()
  state.generation = state.generation + 1
  state.opening = false
  close_sock()
  local pending = state.pending
  state.pending = {}
  state.active_id = nil
  state.search_id = nil
  for _, entry in pairs(pending) do
    if entry.sent then
      finish(entry, { code = 1, stdout = "", stderr = "daemon connection closed" })
    else
      drop_unsent(entry, "daemon connection closed")
    end
  end
  local waiters = state.waiters
  state.waiters = {}
  for _, waiter in ipairs(waiters) do
    vim.schedule(function()
      waiter(false, "daemon connection closed")
    end)
  end
end

local function result_stdout(result)
  if not present(result) then return "null" end
  return vim.json.encode(result)
end

local function dispatch(message)
  if message.op == "ready" then
    state.hello_ok = true
    if type(message.pid) == "number" then state.pid = message.pid end
    return
  end
  if message.op == "error" and type(message.id) ~= "string" then
    state.hello_error = type(message.error) == "string" and message.error or "daemon hello failed"
    return
  end
  if type(message.id) ~= "string" then return end
  local entry = state.pending[message.id]
  if not entry then return end
  if type(message.event) == "string" then
    if entry.on_event then entry.on_event(message) end
    return
  end
  if type(message.ok) ~= "boolean" then return end
  if message.ok then
    finish(entry, { code = 0, stdout = result_stdout(message.result), stderr = "" })
    return
  end
  local stderr
  if present(message.result) then
    stderr = vim.json.encode(message.result)
  elseif type(message.error) == "string" then
    stderr = message.error
  else
    stderr = "kulala-core request failed"
  end
  finish(entry, { code = 1, stdout = "", stderr = stderr })
end

local function consume(chunk)
  state.buf = state.buf .. chunk
  while true do
    local nl = state.buf:find("\n", 1, true)
    if not nl then break end
    local line = state.buf:sub(1, nl - 1)
    state.buf = state.buf:sub(nl + 1)
    if line:sub(-1) == "\r" then line = line:sub(1, -2) end
    if vim.trim(line) ~= "" then
      local ok, message = pcall(vim.json.decode, line)
      if ok and type(message) == "table" then dispatch(message) end
    end
  end
end

local function write_sock(value)
  local sock = state.sock
  if not sock or sock:is_closing() or not state.hello_ok then return false, "daemon socket is closed" end
  local ok, err = pcall(function()
    sock:write(vim.json.encode(value) .. "\n")
  end)
  if not ok then return false, err end
  return true
end

local function connect_meta(meta, generation, deadline)
  local sock = vim.uv.new_pipe(false)
  state.sock = sock
  state.buf = ""
  state.hello_ok = false
  state.hello_error = nil
  state.pid = meta.pid
  local timer = vim.uv.new_timer()
  local remain = math.max(deadline - vim.uv.now(), 1)
  timer:start(remain, 0, function()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    fail_open(generation, "daemon hello timed out")
  end)
  local function stop_timer()
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end
  sock:connect(meta.endpoint, function(err)
    if state.generation ~= generation or state.sock ~= sock then
      stop_timer()
      return
    end
    if err then
      stop_timer()
      fail_open(generation, err)
      return
    end
    sock:read_start(function(read_err, data)
      if state.sock ~= sock then return end
      if read_err or data == nil then
        stop_timer()
        if state.hello_ok then
          on_disconnect()
        else
          fail_open(generation, read_err or state.hello_error or "daemon connection closed")
        end
        return
      end
      consume(data)
      if state.hello_error and not state.hello_ok then
        stop_timer()
        fail_open(generation, state.hello_error)
        return
      end
      if state.hello_ok and state.opening and state.generation == generation then
        stop_timer()
        succeed_open(generation)
      end
    end)
    local ok, write_err = pcall(function()
      sock:write(vim.json.encode {
        op = "hello",
        token = meta.token,
        protocol = PROTOCOL,
        client = "kulala.nvim",
      } .. "\n")
    end)
    if not ok then
      stop_timer()
      fail_open(generation, write_err)
    end
  end)
end

local function poll_meta(path, generation, deadline, on_meta)
  if state.generation ~= generation then return end
  local meta = read_meta(path)
  if meta then
    on_meta(meta)
    return
  end
  if vim.uv.now() >= deadline then
    on_meta(nil)
    return
  end
  vim.defer_fn(function()
    poll_meta(path, generation, deadline, on_meta)
  end, 50)
end

local function version_of(exe, cb)
  if state.version and state.version_exe == exe then
    cb(state.version)
    return
  end
  vim.system({ exe, "--version" }, { text = true, timeout = 20000 }, function(result)
    if result.code ~= 0 then
      cb(nil, vim.trim(result.stderr or "") ~= "" and vim.trim(result.stderr) or "kulala-core --version failed")
      return
    end
    local version = vim.trim(result.stdout or "")
    if version == "" then version = "dev" end
    state.version = version
    state.version_exe = exe
    cb(version)
  end)
end

local function start_open(exe, data_dir, env)
  local generation = state.generation
  local deadline = vim.uv.now() + START_TIMEOUT_MS
  version_of(exe, function(version, verr)
    if state.generation ~= generation then return end
    if not version then
      fail_open(generation, verr or "kulala-core --version failed")
      return
    end
    local meta_file = meta_path(data_dir, version)
    local lock_file = lock_path(data_dir, version)
    local function after_meta(meta)
      if state.generation ~= generation then return end
      if not meta then
        pcall(vim.uv.fs_unlink, lock_file)
        fail_open(generation, "kulala-core daemon did not become ready")
        return
      end
      connect_meta(meta, generation, deadline)
    end
    local existing = read_meta(meta_file)
    if existing then
      connect_meta(existing, generation, deadline)
      return
    end
    local owned = try_lock(lock_file)
    if not owned and lock_is_stale(lock_file, meta_file) then
      pcall(vim.uv.fs_unlink, lock_file)
      owned = try_lock(lock_file)
    end
    if not owned then
      poll_meta(meta_file, generation, deadline, after_meta)
      return
    end
    local handle = spawn_daemon(exe, env)
    if not handle then
      pcall(vim.uv.fs_unlink, lock_file)
      fail_open(generation, "failed to spawn kulala-core daemon")
      return
    end
    poll_meta(meta_file, generation, deadline, after_meta)
  end)
end

local function ensure(exe, data_dir, env, cb)
  if state.sock and state.hello_ok and not state.sock:is_closing() then
    cb(true)
    return
  end
  state.waiters[#state.waiters + 1] = cb
  if state.opening then return end
  state.opening = true
  state.generation = state.generation + 1
  start_open(exe, data_dir, env)
end

local function send_cancel(id)
  if not state.sock or not state.hello_ok then return end
  pcall(function()
    state.sock:write(vim.json.encode { op = "cancel", id = id } .. "\n")
  end)
end

local function cancel_id(id)
  local entry = state.pending[id]
  if not entry or entry.done then return false end
  entry.cancelled = true
  if entry.sent then
    send_cancel(id)
    return true
  end
  finish(entry, { code = 1, stdout = "", stderr = "cancelled" })
  return true
end

function M.cancel_active()
  if not state.active_id then return false end
  return cancel_id(state.active_id)
end

function M.cancel_search()
  if not state.search_id then return false end
  return cancel_id(state.search_id)
end

---@param spec { exe: string, data_dir: string, env: table, payload: table, cwd: string|nil, timeout_ms: number|nil, track: string|nil, on_http_stream: function|nil }
---@param on_done fun(result: { code: number, stdout: string, stderr: string })
---@param on_unavailable fun()
function M.request(spec, on_done, on_unavailable)
  state.seq = state.seq + 1
  local id = "n" .. tostring(state.seq)
  local track = spec.track or "active"
  if track == "search" and state.search_id and state.search_id ~= id then cancel_id(state.search_id) end

  local entry = {
    id = id,
    done = false,
    sent = false,
    cancelled = false,
    on_done = on_done,
    on_unavailable = on_unavailable,
    on_event = function(message)
      if message.event ~= "http-stream" or type(message.data) ~= "table" then return end
      if message.data.type ~= "http-stream" or not spec.on_http_stream then return end
      vim.schedule(function()
        spec.on_http_stream(message.data)
      end)
    end,
  }
  state.pending[id] = entry
  if track == "active" then state.active_id = id end
  if track == "search" then state.search_id = id end

  if spec.timeout_ms and spec.timeout_ms > 0 then
    entry.timer = vim.uv.new_timer()
    entry.timer:start(spec.timeout_ms, 0, function()
      local timer = entry.timer
      entry.timer = nil
      if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
      end
      if entry.done then return end
      if entry.sent then send_cancel(id) end
      finish(entry, { code = 124, stdout = "", stderr = "kulala-core subprocess timed out" })
    end)
  end
  local process_env = vim.fn.environ()

  ensure(spec.exe, spec.data_dir, spec.env, function(ok, err)
    if entry.done then return end
    if not ok then
      drop_unsent(entry, err)
      return
    end
    if entry.cancelled then
      finish(entry, { code = 1, stdout = "", stderr = "cancelled" })
      return
    end
    local body = {}
    for key, value in pairs(spec.payload) do
      body[key] = value
    end
    body.id = id
    body.processEnv = process_env
    if type(spec.cwd) == "string" and spec.cwd ~= "" then body.cwd = spec.cwd end
    local wrote, write_err = write_sock(body)
    if not wrote then
      drop_unsent(entry, write_err)
      return
    end
    entry.sent = true
  end)
end

local function websocket_oneshot(exe, env, connect, handlers, cwd)
  local tmp = vim.fn.tempname() .. ".json"
  vim.fn.writefile({ vim.json.encode(connect) }, tmp)
  return vim.system({ exe, "--websocket", "-i", tmp }, {
    stdin = true,
    text = true,
    cwd = cwd,
    env = env,
    stdout = handlers.on_stdout,
    stderr = handlers.on_stderr,
  }, function(result)
    pcall(vim.fn.delete, tmp)
    handlers.on_exit(result)
  end)
end

---Returns a vim.SystemObj-shaped handle. Writes received before the daemon
---answers are queued. A failed daemon start becomes a one-shot `--websocket` process.
function M.open_websocket(exe, data_dir, env, connect, handlers, cwd)
  local shim = {
    pid = 0,
    _closing = false,
    _queue = {},
    _mode = nil,
    _job = nil,
  }

  function shim:is_closing()
    if self._job then return self._job:is_closing() end
    return self._closing
  end

  function shim:kill()
    self._closing = true
    if self._job then
      pcall(function()
        self._job:kill("sigterm")
      end)
      return
    end
    if self._id and self._mode == "daemon" then
      pcall(function()
        write_sock { op = "ws-close", id = self._id }
      end)
    end
  end

  local function forward_line(line)
    if shim._mode == "job" and shim._job then
      pcall(function()
        shim._job:write(line .. "\n")
      end)
      return
    end
    local ok, message = pcall(vim.json.decode, line)
    if not ok or type(message) ~= "table" or not shim._id then return end
    if message.op == "send" then
      write_sock { op = "ws-send", id = shim._id, data = message.data }
    elseif message.op == "close" then
      write_sock { op = "ws-close", id = shim._id }
    end
  end

  function shim:write(data)
    if type(data) ~= "string" or data == "" then return end
    if not self._mode then
      self._queue[#self._queue + 1] = data
      return
    end
    for line in data:gmatch("[^\n]+") do
      forward_line(line)
    end
  end

  local function flush()
    local queued = shim._queue
    shim._queue = {}
    for _, chunk in ipairs(queued) do
      for line in chunk:gmatch("[^\n]+") do
        forward_line(line)
      end
    end
  end

  state.seq = state.seq + 1
  local id = "ws" .. tostring(state.seq)
  local process_env = vim.fn.environ()
  shim._id = id
  local entry = {
    id = id,
    done = false,
    sent = false,
    on_done = function(result)
      shim._closing = true
      handlers.on_exit { code = result.code }
    end,
    on_unavailable = function() end,
    on_event = function(message)
      if message.event ~= "websocket" or type(message.data) ~= "table" then return end
      handlers.on_stdout(nil, vim.json.encode(message.data) .. "\n")
    end,
  }
  state.pending[id] = entry

  ensure(exe, data_dir, env, function(ok, err)
    if shim._closing and not entry.sent then
      finish(entry, { code = 1, stdout = "", stderr = "cancelled" })
      handlers.on_exit { code = 1 }
      return
    end
    if shim._closing then return end
    if not ok then
      log_fallback(err)
      if state.pending[id] == entry then state.pending[id] = nil end
      entry.done = true
      local job = websocket_oneshot(exe, env, connect, handlers, cwd)
      shim._job = job
      shim.pid = job.pid or 0
      shim._mode = "job"
      flush()
      return
    end
    shim.pid = state.pid or 0
    shim._mode = "daemon"
    local body = {
      id = id,
      action = "websocket",
      connect = connect,
      processEnv = process_env,
    }
    if type(cwd) == "string" and cwd ~= "" then body.cwd = cwd end
    local wrote, write_err = write_sock(body)
    if not wrote then
      log_fallback(write_err)
      if state.pending[id] == entry then state.pending[id] = nil end
      entry.done = true
      local job = websocket_oneshot(exe, env, connect, handlers, cwd)
      shim._job = job
      shim.pid = job.pid or 0
      shim._mode = "job"
      flush()
      return
    end
    entry.sent = true
    flush()
  end)

  return shim
end

return M
