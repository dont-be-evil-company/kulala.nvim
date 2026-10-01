local Logger = require("kulala.logger")

local M = {}
local ready_triggered = false

M.events = {
  ["ready"] = {},
  ["after_next_request"] = {},
  ["after_request"] = {},
}

M.has_triggered_ready = function()
  return ready_triggered
end

M.on = function(name, callback)
  if not M.events[name] then return Logger.error("Invalid event name: " .. name) end
  -- `ready` is one-shot. A listener added after it fired still runs.
  if name == "ready" and ready_triggered then
    callback()
    return
  end
  table.insert(M.events[name], callback)
end

M.trigger = function(name)
  local db = require("kulala.db")
  local responses = db.global_find_unique("responses")
  local response = responses and responses[#responses] or {}
  local events = M.events[name]

  if not events then return Logger.error("Invalid event name: " .. name) end
  -- Make sure "ready" is only triggered once
  if name == "ready" and ready_triggered then return end

  for event_name, callback in ipairs(events) do
    if event_name ~= "ready" then
      callback { headers = response.headers, body = response.body, response = response }
    else
      callback()
    end
  end

  -- Set flag to prevent "ready" from being triggered multiple times
  if name == "ready" then ready_triggered = true end
  -- Clear "after_next_request" callbacks after triggering
  if name == "after_next_request" then M.events[name] = {} end
end

return M
