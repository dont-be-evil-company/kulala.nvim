local DOCUMENT = require("kulala.parser.document")
local KULALA_CORE = require("kulala.cmd.kulala_core_bridge")
local Logger = require("kulala.logger")
local Parserutils = require("kulala.parser.utils")

local M = {}

---@param url string
---@return string|nil host Cache key matching kulala-core `graphqlSchemaHostFromUrl`.
local function graphql_schema_host_from_url(url)
  if type(url) ~= "string" or url == "" then return nil end
  local authority = url:match("^https?://([^/%?#]+)")
  if not authority then return nil end
  local host, port = authority:match("^([^:]+):?(.*)$")
  if not host or host == "" then return nil end
  host = host:lower()
  if port == nil or port == "" then return host end
  local n = tonumber(port)
  if n == 443 or n == 80 then return host end
  return host .. ":" .. port
end

---@return string|nil host
local function graphql_host_at_cursor()
  local requests = DOCUMENT.get_document()
  if not requests then return nil end
  local line = Parserutils.get_current_line_number()
  local at = DOCUMENT.get_request_at(requests, line)
  local req = at and at[1]
  if not req or (req.method or ""):upper() ~= "GRAPHQL" then return nil end
  return graphql_schema_host_from_url(req.url)
end

M.download_schema = function()
  KULALA_CORE.guard(function()
    local result, err = KULALA_CORE.graphql_introspect()
    if not result then return Logger.error(err or "Failed to download GraphQL schema") end
    if result.ok ~= true then return Logger.error(result.error or err or "Failed to download GraphQL schema") end

    local host = result.host or "unknown"
    if result.fromCache then
      Logger.info("GraphQL schema already cached for " .. host)
    else
      Logger.info("GraphQL schema downloaded and cached for " .. host)
    end
  end)
end

---Clear cached GraphQL introspection schema(s).
---@param host string|nil Host cache key; when omitted uses host at cursor, else clears all.
M.clear_schema_cache = function(host)
  KULALA_CORE.guard(function()
    if not host or host == "" then host = graphql_host_at_cursor() end

    local ok, err, res = KULALA_CORE.clear_graphql_schema(host)
    if not ok then return Logger.error(err or "Failed to clear GraphQL schema cache") end

    local cleared = (res and res.cleared) or 0
    if cleared == 0 then
      local label = host or "any host"
      return Logger.info("No cached GraphQL schema for " .. label)
    end

    if host then
      Logger.info("Cleared GraphQL schema cache for " .. host)
    else
      Logger.info("Cleared all GraphQL schema caches (" .. tostring(cleared) .. ")")
    end
  end)
end

return M
