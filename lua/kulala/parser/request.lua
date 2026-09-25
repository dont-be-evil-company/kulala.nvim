local CONFIG = require("kulala.config")
local DB = require("kulala.db")
local DOCUMENT_PARSER = require("kulala.parser.document")
local ENV_PARSER = require("kulala.parser.env")
local FS = require("kulala.utils.fs")
local GRAPHQL_PARSER = require("kulala.parser.graphql")
local PARSER_UTILS = require("kulala.parser.utils")
local STRING_UTILS = require("kulala.utils.string")
local StringVariablesParser = require("kulala.parser.string_variables_parser")
local Table = require("kulala.utils.table")

local M = {}

---@class Request: DocumentRequest
---@field metadata { name: string, value: string }[] -- Metadata of the request
---@field variables table<{name: string, value: string|number|boolean}>
---@field environment table<string, string|number> -- The environment and request variables
---
---@field method string -- The HTTP method of the request
---@field url string -- The URL with variables and dynamic variables replaced
---@field url_raw string -- The raw URL as it appears in the document
---@field request_target string|nil -- The target of the request
---@field http_version string -- The HTTP version of the request
---@field type "rest"|"graphql"|"grpc"|"websocket"
---   Request type from method, metadata, and headers
---
---@field headers table<string, string> -- The headers with variables and dynamic variables replaced
---@field headers_raw table<string, string> -- The headers as they appear in the document
---@field headers_display table<string, string>
---   Headers with variables replaced and sanitized
---@field cookie string -- The cookie as it appears in the document
---
---@field body string|nil -- The body with variables and dynamic variables replaced
---@field body_raw string|nil -- The raw body as it appears in the document
---@field body_computed string|nil
---   Body as sent (variables and dynamic variables replaced)
---@field body_display string|nil -- The body with variables and dynamic variables replaced and sanitized
---(e.g. with binary files replaced with a placeholder)
---
---@field show_icon_line_number number|nil -- 1-based `###` delimiter line for icons / timings
---
---@field redirect_response_body_to_files ResponseBodyToFile[]
---
---@field scripts Scripts -- The scripts to run before and after the request
---
---@field cmd string[] -- The command to execute the request
---@field body_temp_file string -- The path to the temporary file containing the body
---
---@field file string -- The file path of the document
---@field ft string -- The filetype of the document

---@type Request
---@diagnostic disable-next-line: missing-fields
local default_request = {
  environment = {},
  headers_display = {},
  ft = "text",
  cmd = {},
  body_temp_file = "",
}

-- Reserved Characters: ! # $ & ' ( ) * + , / : ; = ? @ [ ]
-- https://stackoverflow.com/questions/1547899/which-characters-make-a-url-invalid/1547940#1547940
local function encode_url(url, method)
  local urlencode = CONFIG.get().urlencode == "always"
  if urlencode and vim.uri_decode(url) ~= url then return url end

  local index
  local scheme, authority, query, fragment = "", "", "", ""
  local url_encode = urlencode and STRING_UTILS.url_encode or STRING_UTILS.url_encode_skipencoded

  if method == "GRPC" then return url_encode(url, "/:%s") end

  index = select(2, url:find(".*#"))
  if index then
    fragment = url_encode(url:sub(index), "#/%(%)!$',*")
    url = url:sub(1, index - 1)
  end

  index = select(2, url:find(".*?"))
  if index then
    query = url_encode(url:sub(index), "%?/=&%(%)!$',*")
    url = url:sub(1, index - 1)
  end

  index = select(2, url:find(".*://"))
  if index then
    scheme = url_encode(url:sub(1, index - 3), "+") .. "://"
    url = url:sub(index + 1)
  end

  index = url:find("/")
  if index then
    authority = url_encode(url:sub(1, index - 1), "@:%[%]")
    url = url:sub(index)
  end

  local path = url_encode(url, "/:;=%[%]%(%)!$',*")

  return scheme .. authority .. path .. query .. fragment
end

local function parse_url(url, variables, env, silent)
  return StringVariablesParser.parse(url, variables, env, silent)
end

local function parse_headers(headers, variables, env, silent)
  return vim.iter(headers):fold({}, function(ret, k, v)
    ret[StringVariablesParser.parse(k, variables, env, silent)] = StringVariablesParser.parse(v, variables, env, silent)
    return ret
  end)
end

local function get_file_with_replaced_variables(path, request)
  local contents = FS.read_file(path)

  if vim.fn.fnamemodify(path, ":e") == "graphql" or vim.fn.fnamemodify(path, ":e") == "gql" then
    contents = contents:gsub("#[^\n]*", "") -- remove comments from GraphQL files
  end

  contents = StringVariablesParser.parse(contents, request.environment, request.environment)
  contents = contents:gsub("[\n\r]", "")

  return FS.get_temp_file(contents), contents
end

local function process_graphql(request)
  local has_graphql_meta_tag = PARSER_UTILS.contains_meta_tag(request, "graphql")
  local has_graphql_header = PARSER_UTILS.contains_header(request.headers, "x-request-type", "graphql")

  local is_graphql = request.method == "GRAPHQL" or has_graphql_meta_tag or has_graphql_header

  if is_graphql and request.body and #request.body > 0 then
    local content_type_header_name = PARSER_UTILS.get_header(request.headers, "Content-Type") or "Content-Type"

    request.method = "POST"
    request.type = "graphql"
    request.headers[content_type_header_name] = "application/json"

    if not has_graphql_header then request.headers["x-request-type"] = "GraphQL" end

    request.body_computed = request.body:gsub("\n<%s([^\n]+)", function(path)
      local _, contents = get_file_with_replaced_variables(path, request)
      return contents and ("\n" .. contents) or ""
    end)

    local gql_json = GRAPHQL_PARSER.get_json(request.body_computed)
    if gql_json then request.body_computed = gql_json end
  end

  return request
end

---Replace the variables in the URL, headers and body
---@param request Request -- The request object
---@param silent boolean|nil -- Whether to suppress not found variable warnings
local process_variables = function(request, silent)
  local env = ENV_PARSER.get_env() or {}
  local params = { request.variables, env, silent }

  request.url = parse_url(request.url_raw, unpack(params))
  request.headers = parse_headers(request.headers, unpack(params))
  request.cookie = StringVariablesParser.parse(request.cookie, unpack(params))
  request.body = StringVariablesParser.parse(request.body_raw, unpack(params))
  request.body_display = StringVariablesParser.parse(request.body_display, unpack(params))
  -- INFO:
  -- Special treatment for GraphQL requests:
  -- we need to replace variables in the body before parsing GraphQL,
  -- because the body may contain already parsed GQL.
  -- See:
  -- - GraphQL request with pre-request script, body not converted to json
  --   https://github.com/dont-be-evil-company/kulala.nvim/issues/844
  -- - Variables in request body not re-evaluated on request.replay()
  --   https://github.com/dont-be-evil-company/kulala.nvim/issues/814
  if request.type == "graphql" then
    process_graphql(request)
  else
    request.body_computed = StringVariablesParser.parse(request.body_raw, unpack(params))
  end

  vim.iter(request.redirect_response_body_to_files):each(function(redirect)
    redirect.file = StringVariablesParser.parse(redirect.file, unpack(params))
  end)

  vim.iter(request.metadata):each(function(metadata)
    metadata.value = StringVariablesParser.parse(metadata.value, unpack(params))
  end)

  request.environment = vim.tbl_extend("keep", env, request.variables)

  return env
end

local function set_variables(request)
  return process_variables(request)
end

local function set_headers(request, env)
  -- Default HTTP headers come from kulala-core (`$kulalaShared` / `$kulalaDefaultHeaders` in http-client.env.json).
  vim.iter(request.headers):each(function(name, value)
    name = PARSER_UTILS.get_header(request.headers, name) or name
    value = StringVariablesParser.parse(value, request.variables, env)

    if name == "Host" then
      request.headers[name] = value:gsub("^https?://", ""):gsub("/.*$", "")
      request.url = (request.url == "" or request.url:match("^/")) and (value .. request.url) or request.url
    else
      request.headers[name] = request.headers[name] or StringVariablesParser.parse(value, request.variables, env)
    end
  end)

  request.headers_display = vim.deepcopy(request.headers)
end

---Gets data from a DocumentRequest, a line in the list, or the first request when none is given.
---@param requests DocumentRequest[] List of document requests
---@param document_request DocumentRequest|nil The request to parse
---@param line_nr number|nil The line number where the request starts
---@return Request|nil -- Table containing the request data or nil if parsing fails
function M.get_basic_request_data(requests, document_request, line_nr)
  local request = vim.deepcopy(default_request)

  if not document_request then
    local doc_requests = DOCUMENT_PARSER.get_request_at(requests, line_nr) or {}
    -- return shared requests if it is the only one
    document_request = line_nr and line_nr > 0 and doc_requests[2] or doc_requests[1]
  end

  if not document_request then return end

  request = vim.tbl_extend("keep", request, document_request)

  -- url_raw/body_raw may already be set when replaying a request
  request.url_raw = request.url_raw or document_request.url
  request.body_raw = request.body_raw or document_request.body

  Table.remove_keys(request, { "comments", "body", "inlined_files" })

  return request
end

---Parses specified document request or a request within specified line and returns the request ready to be processed
---or the first request in the list if no document_request or line number is provided
---or the request in current_buffer at current line if no arguments are provided
---@param requests? DocumentRequest[]|nil Document requests
---@param document_request? DocumentRequest|nil The request to parse
---@return Request|nil -- Table containing the request data or nil if parsing fails
---@return string|nil -- Error message if parsing fails
M.parse = function(requests, document_request)
  local line_nr

  if not requests then
    DB.set_current_buffer()
    requests = DOCUMENT_PARSER.get_document()
    line_nr = PARSER_UTILS.get_current_line_number()
  end

  if not requests or #requests == 0 then return end

  local request = M.get_basic_request_data(requests, document_request, line_nr)
  if not request then return end

  DB.current_request = request

  local empty_request = false
  if not request.url then empty_request = true end -- shared blocks with no URL

  local env = set_variables(request)
  set_headers(request, env)

  request.url = encode_url(request.url, request.method)
  request.type = "rest"
  process_graphql(request)

  if empty_request then return nil, "empty" end

  if request.method == "GRPC" then
    request.type = "grpc"
  elseif request.method == "WS" or request.method == "WSS" then
    request.type = "websocket"
  else
    request.type = "rest"
  end

  DB.update().previous_request = DB.find_unique("current_request")
  DB.update().current_request = request

  -- Save this to global, so .replay() can be triggered from any buffer or window
  DB.global_update().replay = vim.deepcopy(request)
  DB.global_update().replay.url_raw = request.url
  DB.global_update().replay.show_icon_line_number = request.show_icon_line_number or request.start_line

  return request
end

M.process_variables = process_variables

return M
