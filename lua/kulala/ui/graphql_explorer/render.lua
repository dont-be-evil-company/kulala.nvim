local M = {}

local DESC_MAX = 240

---@param text string
---@return string
local function truncate_desc(text)
  text = text:gsub("\r\n", " "):gsub("\n", " "):gsub("^%s+", ""):gsub("%s+$", "")
  if #text <= DESC_MAX then return text end
  return text:sub(1, DESC_MAX - 1) .. "…"
end

---@param node table
---@param depth integer
---@param lines string[]
---@param line_map table[]
local function append_description(node, depth, lines, line_map)
  if type(node.description) ~= "string" or node.description == "" then return end
  local indent = string.rep("  ", depth + 1)
  table.insert(lines, indent .. truncate_desc(node.description))
  table.insert(line_map, { kind = "text", id = node.id .. ":desc", parentId = node.id })
end

---@param nodes table[]
---@param folds table<string, boolean>
---@param filter string
---@param depth integer
---@param lines string[]
---@param line_map table[]
---@param signs table
local function walk(nodes, folds, filter, depth, lines, line_map, signs)
  for _, node in ipairs(nodes or {}) do
    local has_children = (node.children and #node.children > 0) or node.pending ~= nil
    local folded = filter == "" and folds[node.id] == true
    local sign = " "
    if has_children then sign = folded and signs.folded or signs.expanded end
    local indent = string.rep("  ", depth)
    local line
    if node.kind == "root" then
      line = indent .. sign .. " " .. node.name
    elseif node.kind == "arg" then
      local box = node.checked and "[x]" or "[ ]"
      local value = ""
      if node.checked and type(node.value) == "string" and node.value ~= "" then value = " = " .. node.value end
      local badge = " ARG"
      if node.required then badge = badge .. " required" end
      line = indent .. sign .. " " .. box .. " " .. node.name .. " [" .. (node.type or "") .. "]" .. badge .. value
    elseif node.kind == "fragment" then
      local box = node.checked and "[x]" or "[ ]"
      line = indent .. sign .. " " .. box .. " " .. node.name
    else
      local box = node.checked and "[x]" or "[ ]"
      line = indent .. sign .. " " .. box .. " " .. node.name .. " [" .. (node.type or "") .. "]"
    end
    table.insert(lines, (line:gsub("[\r\n]+", " ")))
    table.insert(line_map, node)
    if not folded then
      append_description(node, depth, lines, line_map)
      if has_children then walk(node.children, folds, filter, depth + 1, lines, line_map, signs) end
    end
  end
end

---@param tree table[]
---@param folds table<string, boolean>
---@param filter string|nil
---@param header table|nil
---@param signs table|nil
---@return string[]
---@return table[]
function M.build_lines(tree, folds, filter, header, signs)
  signs = signs or { folded = ">", expanded = "v" }
  filter = filter or ""
  header = header or {}
  local lines = {}
  local line_map = {}
  local search = filter ~= "" and ("Search: " .. filter) or "Search: / to filter"
  table.insert(lines, search)
  table.insert(line_map, { kind = "header", id = "search" })
  if type(header.endpoint) == "string" and header.endpoint ~= "" then
    table.insert(lines, header.endpoint)
    table.insert(line_map, { kind = "header", id = "endpoint" })
  end
  if header.patchable == false and type(header.reason) == "string" and header.reason ~= "" then
    table.insert(lines, header.reason)
    table.insert(line_map, { kind = "header", id = "reason" })
  end
  if #lines > 0 then
    table.insert(lines, "")
    table.insert(line_map, { kind = "header", id = "blank" })
  end
  local before = #lines
  walk(tree, folds, filter, 0, lines, line_map, signs)
  if #lines == before then
    table.insert(lines, "No GraphQL fields")
    table.insert(line_map, { kind = "header", id = "empty" })
  end
  return lines, line_map
end

return M
