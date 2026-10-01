local KULALA_CORE = require("kulala.cmd.kulala_core_bridge")
local Logger = require("kulala.logger")

local M = {}

M.clear_schema_cache = function(cache_key)
  KULALA_CORE.guard(function()
    local ok, err, res = KULALA_CORE.clear_openapi_schema(cache_key)
    if not ok then return Logger.error(err or "Failed to clear OpenAPI schema cache") end

    local cleared = (res and res.cleared) or 0
    if cleared == 0 then
      local label = cache_key or "any key"
      return Logger.info("No cached OpenAPI schema for " .. label)
    end

    if cache_key then
      Logger.info("Cleared OpenAPI schema cache for " .. cache_key)
    else
      Logger.info("Cleared all OpenAPI schema caches (" .. tostring(cleared) .. ")")
    end
  end)
end

---@param bufnr? integer
---@param line? integer
---@param column? integer
---@return table|nil openapi payload
---@return string|nil err
M.load_at_cursor = function(bufnr, line, column)
  if not KULALA_CORE.enabled() then return nil, "kulala-core is required for OpenAPI explorer" end
  return KULALA_CORE.openapi_load(bufnr, line, column)
end

return M
