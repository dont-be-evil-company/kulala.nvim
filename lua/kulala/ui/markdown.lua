---Shared markdown formatting for Kulala UI views.
local Config = require("kulala.config")

local M = {}

---@param s string
---@return string
function M.trim(s)
  return vim.trim(s or "")
end

---Insert a blank line after ATX headings (`#` …).
---Skips lines inside fenced code blocks.
---@param s string
---@return string
function M.normalize_headings(s)
  if s == "" then return s end

  local lines = vim.split(s, "\n", { plain = true })
  local result = {}
  local in_fence = false

  for i, line in ipairs(lines) do
    table.insert(result, line)

    if line:match("^```") then
      in_fence = not in_fence
    elseif not in_fence and line:match("^#+%s") and lines[i + 1] ~= "" then
      table.insert(result, "")
    end
  end

  return table.concat(result, "\n")
end

---Escape inline markdown (headings, lists, etc.); wraps in backticks.
---@param s string
---@return string
function M.md_escape_cell(s)
  s = tostring(s):gsub("|", "\\|"):gsub("\r", ""):gsub("\n", "<br>")
  local max_run = 0
  local run = 0
  for i = 1, #s do
    if s:byte(i) == 96 then
      run = run + 1
      max_run = math.max(max_run, run)
    else
      run = 0
    end
  end
  local fence = string.rep("`", max_run + 1)
  return fence .. s .. fence
end

---Escape table cell text; use inline code for markdown-special content so values
---like `*/*` render literally, otherwise keep plain text for column alignment.
---@param s string
---@return string
function M.md_table_cell(s)
  s = tostring(s):gsub("\r", ""):gsub("\n", "<br>")
  if s:find("[%*_\\|]") then return M.md_escape_cell(s) end
  return s
end

---@param s string
---@return number
local function display_width(s)
  return vim.api.nvim_strwidth(s)
end

---@param rows string[][] row 1 = plain header labels; row 2+ = rendered cells
---@param align? "l"|"r" -- right-align columns after the first (GFM `---:`)
---@return string
function M.md_table(rows, align)
  if #rows == 0 then return "" end
  local ncols = #rows[1]
  local widths = {}
  for _, row in ipairs(rows) do
    for i = 1, ncols do
      widths[i] = math.max(widths[i] or 0, display_width(tostring(row[i] or "")))
    end
  end

  local function col_width(col_idx)
    local w = math.max(3, widths[col_idx] or 3)
    if align == "r" and col_idx > 1 then
      w = math.max(4, w) -- GFM right-align needs at least `---:` (3 dashes + colon)
    end
    return w
  end

  ---@param col string
  ---@param col_idx number
  local function fmt_cell(col, col_idx)
    col = tostring(col or "")
    local w = col_width(col_idx)
    local dw = display_width(col)
    if dw > w then
      widths[col_idx] = dw
      w = col_width(col_idx)
      dw = display_width(col)
    end
    local pad = math.max(0, w - dw)
    if align == "r" and col_idx > 1 then return string.rep(" ", pad) .. col end
    return col .. string.rep(" ", pad)
  end

  ---@param col_idx number
  local function fmt_sep(col_idx)
    local w = col_width(col_idx)
    if align == "r" and col_idx > 1 then return fmt_cell(string.rep("-", w - 1) .. ":", col_idx) end
    return fmt_cell(string.rep("-", w), col_idx)
  end

  local function fmt_row(row)
    local cells = {}
    for i = 1, ncols do
      cells[i] = fmt_cell(row[i] or "", i)
    end
    return "| " .. table.concat(cells, " | ") .. " |"
  end

  local sep_cells = {}
  for i = 1, ncols do
    sep_cells[i] = fmt_sep(i)
  end

  local lines = { fmt_row(rows[1]), "| " .. table.concat(sep_cells, " | ") .. " |" }
  for r = 2, #rows do
    table.insert(lines, fmt_row(rows[r]))
  end
  return table.concat(lines, "\n")
end

---@param v string|table|nil
---@return string
local function header_value(v)
  if v == nil then return "" end
  if type(v) == "table" then
    if vim.islist(v) then return table.concat(vim.tbl_map(tostring, v), ", ") end
    return vim.inspect(v)
  end
  return tostring(v)
end

---Prefer raw header text (same source as the legacy headers pane); fall back to parsed table.
---@param r Response
---@return string|table|nil
function M.response_headers_source(r)
  if type(r.headers) == "string" and M.trim(r.headers) ~= "" then return r.headers end
  if type(r.headers_tbl) == "table" and next(r.headers_tbl) then return r.headers_tbl end
  return nil
end

---@param headers table<string, string|table>|string|nil
---@return string[][]
function M.headers_rows(headers)
  local rows = { { "Header", "Value" } }
  if type(headers) == "string" then
    for line in vim.gsplit(headers, "\n", { plain = true, trimempty = true }) do
      local k, v = line:match("^([^:]+):%s*(.*)$")
      if k then table.insert(rows, { M.md_table_cell(k), M.md_escape_cell(v) }) end
    end
    return rows
  end
  if type(headers) ~= "table" then return rows end
  local keys = vim.tbl_keys(headers)
  table.sort(keys, function(a, b)
    return a:lower() < b:lower()
  end)
  for _, k in ipairs(keys) do
    table.insert(rows, { M.md_table_cell(k), M.md_escape_cell(header_value(headers[k])) })
  end
  return rows
end

---@param headers table<string, string|table>|string|nil
---@return string
function M.format_headers_table(headers)
  local rows = M.headers_rows(headers)
  if #rows < 2 then return "_No headers_\n" end
  return M.md_table(rows) .. "\n"
end

---@param s string
---@return string
function M.pretty_maybe_json(s)
  if not s or s == "" then return s end
  local KULALA_CORE = require("kulala.cmd.kulala_core_bridge")
  if not KULALA_CORE.enabled() then return s end
  local response_format = Config.get().response_format or {}
  local formatted = KULALA_CORE.format_json(nil, {
    text = s,
    indent = response_format.indent,
    expand_tabs = response_format.expand_tabs,
    sort_keys = response_format.sort_keys,
  })
  return formatted or s
end

---@param lang string
---@param body string
---@param prettify boolean|nil whether to attempt pretty-printing (e.g. for JSON)
---@return string
function M.fenced(lang, body, prettify)
  body = body or ""
  if body == "" then return "_Empty_\n" end
  local fence = "```"
  while body:find(fence, 1, true) do
    fence = fence .. "`"
  end
  if prettify and lang == "json" then body = M.pretty_maybe_json(body) end
  return fence .. lang .. "\n" .. body .. "\n" .. fence .. "\n"
end

---Resolve treesitter/fence language from kulala-core body hints.
---@param media_type string|nil kulala-core `body.mediaType`
---@param kulala_body_type string|nil `"json"` | `"text"` | `"binary"`
---@return string language name (e.g. "json", "xml", "html", "text")
function M.get_body_ft(media_type, kulala_body_type)
  if kulala_body_type == "json" then return "json" end
  if kulala_body_type == "binary" then return "text" end
  if type(media_type) == "string" and media_type ~= "" then
    local mt = media_type:lower()
    if mt:find("json", 1, true) then return "json" end
    if mt:find("xml", 1, true) then return "xml" end
    if mt:find("html", 1, true) then return "html" end
  end
  return "text"
end

---Markdown fence language for a stored response body (uses Content-Type / kulala-core hints).
---@param r Response
---@param body? string
---@return string body
---@return string ft
function M.get_body_and_guess_ft(r, body)
  body = body or r.body or ""
  local content_type = M.get_body_ft(r._kulala_media_type, r._kulala_body_type)
  return body, content_type
end

---@param parts string[]
---@param heading string
---@param content string|nil
function M.add_section(parts, heading, content)
  content = M.trim(content or "")
  if content == "" then return end
  table.insert(parts, heading)
  table.insert(parts, content)
  table.insert(parts, "")
end

---@param tm table|nil
---@return string[][]
function M.timings_rows(tm)
  local rows = { { "Phase", "ms" } }
  if type(tm) ~= "table" then return rows end

  local order = {
    { "dns", "DNS" },
    { "namelookup", "DNS" },
    { "tcp", "TCP" },
    { "connect", "TCP connect" },
    { "tls", "TLS" },
    { "appconnect", "TLS handshake" },
    { "request", "Request" },
    { "pretransfer", "Pre-transfer" },
    { "redirect", "Redirect" },
    { "firstByte", "TTFB" },
    { "starttransfer", "Start transfer" },
    { "startTransfer", "Start transfer" },
    { "total", "Total" },
  }

  local seen = {}
  if vim.islist(tm) then
    for _, e in ipairs(tm) do
      if type(e) == "table" and e.name and e.duration ~= nil and not seen[e.name] then
        seen[e.name] = true
        local sec = tonumber(e.duration) or 0
        table.insert(rows, { M.md_table_cell(e.name), M.md_table_cell(("%.3f"):format(sec * 1000)) })
      end
    end
    return rows
  end

  local max_val = 0
  for _, pair in ipairs(order) do
    local v = tm[pair[1]]
    if type(v) == "number" then max_val = math.max(max_val, v) end
  end
  local scale_seconds = max_val > 0 and max_val < 30

  for _, pair in ipairs(order) do
    local key, label = pair[1], pair[2]
    local v = tm[key]
    if v ~= nil and not seen[label] then
      seen[label] = true
      local ms = tonumber(v) or 0
      if scale_seconds then ms = ms * 1000 end
      table.insert(rows, { M.md_table_cell(label), M.md_table_cell(("%.3f"):format(ms)) })
    end
  end
  return rows
end

---@param tm table|nil
---@return string
function M.format_timings(tm)
  local rows = M.timings_rows(tm)
  if #rows < 2 then return "" end
  return M.md_table(rows, "r") .. "\n"
end

---@param stats table|string|nil
---@return string
function M.format_stats_table(stats)
  if type(stats) ~= "table" then return "" end
  local tm = stats.timings
  if type(tm) == "table" then return M.format_timings(tm) end
  return ""
end

---@param trace string
---@return string connection, string request_hdrs, string response_hdrs, string other
function M.split_curl_trace(trace)
  local connection, request_hdrs, response_hdrs, other = {}, {}, {}, {}
  for line in vim.gsplit(trace or "", "\n", { plain = true }) do
    if line:match("^%*") then
      table.insert(connection, line:sub(2))
    elseif line:match("^>") then
      table.insert(request_hdrs, line:sub(2))
    elseif line:match("^<") then
      table.insert(response_hdrs, line:sub(2))
    elseif M.trim(line) ~= "" then
      table.insert(other, line)
    end
  end
  local join = function(t)
    if #t == 0 then return "" end
    return table.concat(t, "\n")
  end
  return join(connection), join(request_hdrs), join(response_hdrs), join(other)
end

---@param trace string|nil
---@return string
function M.format_connection_trace(trace)
  trace = M.trim(trace or "")
  if trace == "" then return "" end

  local conn, req_hdr, res_hdr, other = M.split_curl_trace(trace)
  local parts = {}

  local function trace_header_rows(block)
    local rows = { { "Header", "Value" } }
    local status_line
    for line in vim.gsplit(block, "\n", { plain = true }) do
      local text = M.trim(line)
      if text:match("^HTTP/") then
        status_line = text
      else
        local k, v = text:match("^([^:]+):%s*(.*)$")
        if k then table.insert(rows, { M.md_table_cell(k), M.md_table_cell(v) }) end
      end
    end
    return rows, status_line
  end

  if conn ~= "" then
    table.insert(parts, "### Connection & TLS\n")
    for line in vim.gsplit(conn, "\n", { plain = true }) do
      local text = M.trim(line)
      if text ~= "" then table.insert(parts, ("- %s"):format(M.md_escape_cell(text))) end
    end
    table.insert(parts, "")
  end

  if req_hdr ~= "" then
    table.insert(parts, "### Request (from trace)\n")
    local rows, status = trace_header_rows(req_hdr)
    if status then table.insert(parts, ("**Request line:** %s\n"):format(M.md_escape_cell(status))) end
    if #rows > 1 then table.insert(parts, M.md_table(rows) .. "\n") end
  end

  if res_hdr ~= "" then
    table.insert(parts, "### Response (from trace)\n")
    local rows, status = trace_header_rows(res_hdr)
    if status then table.insert(parts, ("**Status:** %s\n"):format(M.md_escape_cell(status))) end
    if #rows > 1 then table.insert(parts, M.md_table(rows) .. "\n") end
  end

  if other ~= "" then
    table.insert(parts, "### Trace (other)\n")
    table.insert(parts, M.fenced("text", other))
  end

  return table.concat(parts, "\n")
end

---@param r Response
---@return string
function M.format_headers_view(r)
  return ("### Response headers\n%s"):format(M.format_headers_table(M.response_headers_source(r)))
end

---@param body string|nil
---@param r? Response when set, Content-Type / kulala-core hints choose the fence language
---@return string
function M.format_body_view(body, r)
  body = body or ""
  if body:match("^No response body %(check Verbose output%)") then return "### Response body\n_No response body_\n" end
  local content, lang
  if r then
    content, lang = M.get_body_and_guess_ft(r, body)
  else
    content = body
  end
  return ("### Response body\n%s"):format(M.fenced(lang, content))
end

---@param r Response
---@param body? string optional pre-formatted body (e.g. after external formatter)
---@return string
function M.format_headers_body_view(r, body)
  return M.format_headers_view(r) .. "\n" .. M.format_body_view(body or r.body, r)
end

---@param path string|nil
---@return string
local function normalize_path(path)
  if type(path) ~= "string" or path == "" then return "" end
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

---@param a string|nil
---@param b string|nil
---@return boolean
local function paths_equal(a, b)
  local na, nb = normalize_path(a), normalize_path(b)
  return na ~= "" and nb ~= "" and na == nb
end

---@param origin_file string|nil
---@param request_file string|nil
---@return string|nil relative path, or nil when same as request file (omit in UI)
local function script_console_display_path(origin_file, request_file)
  if type(origin_file) ~= "string" or origin_file == "" then return "?" end
  if type(request_file) ~= "string" or request_file == "" then return vim.fn.fnamemodify(origin_file, ":t") end
  if paths_equal(origin_file, request_file) then return nil end

  local origin_abs = normalize_path(origin_file)
  local request_abs = normalize_path(request_file)
  local request_dir = vim.fn.fnamemodify(request_abs, ":p:h")

  local rel = vim.fs.relpath(origin_abs, request_dir)
  if type(rel) == "string" and rel ~= "" and rel ~= "." then return rel end

  return vim.fn.fnamemodify(origin_abs, ":t")
end

---@param r Response|nil
---@return string|nil
local function resolve_request_file(r)
  if type(r) ~= "table" then return nil end
  if type(r.file) == "string" and vim.trim(r.file) ~= "" then return r.file end
  if type(r.buf_name) == "string" and vim.trim(r.buf_name) ~= "" then return r.buf_name end
  return nil
end

---@param origin table|nil
---@return boolean
local function script_console_is_pre(origin)
  if type(origin) ~= "table" then return false end
  local ph = origin.phase or origin["phase"]
  if ph == nil or type(ph) ~= "string" and type(ph) ~= "number" then return false end
  ph = tostring(ph)
  return ph == "preRequest" or ph == "pre-request" or ph == "pre_request"
end

---@param origin table|nil
---@param request_file string|nil
---@return string
local function format_script_console_origin(origin, request_file)
  if type(origin) ~= "table" then return "[?]" end
  local src = tostring(origin.source or origin["source"] or "?")
  local origin_file = origin.file or origin["file"]
  local fp = script_console_display_path(type(origin_file) == "string" and origin_file or nil, request_file)
  local loc
  if type(origin.line) == "number" then
    loc = "L" .. tostring(origin.line)
    if type(origin.column) == "number" then loc = loc .. ":" .. tostring(origin.column) end
  else
    loc = "directive L" .. tostring(origin.httpDirectiveLine or origin["httpDirectiveLine"] or "?")
  end
  if fp then return ("[%s · %s · %s]"):format(src, fp, loc) end
  return ("[%s · %s]"):format(src, loc)
end

---@param lines table|nil
---@return table[]
local function script_console_entries(lines)
  if type(lines) ~= "table" then return {} end
  if vim.islist(lines) then return lines end
  local indexed = {}
  for k, v in pairs(lines) do
    if type(v) == "table" then
      local n = tonumber(k)
      if n then indexed[n] = v end
    end
  end
  if next(indexed) then
    local keys = vim.tbl_keys(indexed)
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do
      table.insert(out, indexed[k])
    end
    return out
  end
  return {}
end

---@param entry table
---@return string|nil
local function script_console_message(entry)
  if type(entry) ~= "table" then return nil end
  local msg = entry.message
  if msg == nil then msg = entry["message"] end
  if msg == nil then return nil end
  msg = tostring(msg)
  if msg == "" then return nil end
  return msg
end

---@param entry table
---@param request_file string|nil
---@return string
local function format_script_console_line(entry, request_file)
  local msg = script_console_message(entry) or ""
  local lvl = entry.level or entry["level"] or "log"
  local lvl_prefix = lvl == "error" and "[error] "
    or lvl == "warn" and "[warn] "
    or lvl == "info" and "[info] "
    or lvl == "debug" and "[debug] "
    or ""
  local origin = entry.origin or entry["origin"]
  if type(origin) == "table" then
    return ("%s%s %s"):format(lvl_prefix, format_script_console_origin(origin, request_file), msg)
  end
  return ("%s%s"):format(lvl_prefix, msg)
end

--- kulala-core `scriptConsole` → pre/post text (for API/report fields).
---@param lines table[]|nil
---@param request_file string|nil HTTP document path for relative / omitted file display
---@return string pre
---@return string post
function M.split_script_console(lines, request_file)
  local pre_lines, post_lines = {}, {}
  for _, entry in ipairs(script_console_entries(lines)) do
    local msg = script_console_message(entry)
    if msg then
      local line = format_script_console_line(entry, request_file)
      if script_console_is_pre(entry.origin or entry["origin"]) then
        table.insert(pre_lines, line)
      else
        table.insert(post_lines, line)
      end
    end
  end
  return table.concat(pre_lines, "\n"), table.concat(post_lines, "\n")
end

---@param lines table[]|nil
---@param request_file string|nil
---@return string
function M.format_script_console_lines(lines, request_file)
  local pre, post = M.split_script_console(lines, request_file)
  return M.format_script_sections(pre, post)
end

---@param pre string|nil
---@param post string|nil
---@return string
function M.format_script_sections(pre, post)
  local parts = {}
  pre, post = pre or "", post or ""
  if M.trim(pre) ~= "" then
    table.insert(parts, "### Pre-request script\n")
    table.insert(parts, M.fenced("text", pre))
  end
  if M.trim(post) ~= "" then
    table.insert(parts, "### Post-request script\n")
    table.insert(parts, M.fenced("text", post))
  end
  if #parts == 0 then return "_No script output_\n" end
  return table.concat(parts, "\n")
end

---@param r Response
---@return string
function M.format_script_output(r)
  local request_file = resolve_request_file(r)
  if type(r.script_console) == "table" then
    local out = M.format_script_console_lines(r.script_console, request_file)
    if out ~= "_No script output_\n" then return out end
  end
  if M.trim(r.script_pre_output or "") ~= "" or M.trim(r.script_post_output or "") ~= "" then
    return M.format_script_sections(r.script_pre_output, r.script_post_output)
  end
  return "_No script output_\n"
end

return M
