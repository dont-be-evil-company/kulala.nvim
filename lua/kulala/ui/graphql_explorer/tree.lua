local M = {}

---@param list any
---@return table<string, boolean>
local function string_set(list)
  local set = {}
  if type(list) ~= "table" then return set end
  for _, value in ipairs(list) do
    if type(value) == "string" then set[value] = true end
  end
  return set
end

---@param path string[]
---@return string[]
local function copy_path(path)
  local out = {}
  for i, segment in ipairs(path) do
    out[i] = segment
  end
  return out
end

---@param ancestors table<string, boolean>
---@param type_name string|nil
---@return table<string, boolean>
local function with_type(ancestors, type_name)
  local next_ancestors = {}
  for name, seen in pairs(ancestors) do
    next_ancestors[name] = seen
  end
  if type(type_name) == "string" and type_name ~= "" then next_ancestors[type_name] = true end
  return next_ancestors
end

---@param path string[]
---@param segment string
---@return string[]
local function push_path(path, segment)
  local out = copy_path(path)
  out[#out + 1] = segment
  return out
end

---@param graphql table|nil
---@return table<string, boolean>
---@return table<string, boolean>
---@return table<string, string>
local function selection(graphql)
  graphql = graphql or {}
  return string_set(graphql.checkedFields),
    string_set(graphql.checkedArgs),
    type(graphql.argValues) == "table" and graphql.argValues or {}
end

---@param arg table
---@param field_path string[]
---@param arg_key string
---@param operation string
---@param checked_args table<string, boolean>
---@param arg_values table<string, string>
---@return table
local function arg_node(arg, field_path, arg_key, operation, checked_args, arg_values)
  return {
    kind = "arg",
    id = "arg:" .. arg_key,
    path = field_path,
    name = arg.name,
    argName = arg.name,
    type = arg.type,
    typeName = arg.typeName,
    description = arg.description,
    required = arg.required == true,
    options = arg.options,
    checked = checked_args[arg_key] == true,
    value = arg_values[arg_key],
    operation = operation,
  }
end

---@param possible_name string
---@param field_path string[]
---@param ancestors table<string, boolean>
---@param operation string
---@param checked_fields table<string, boolean>
---@return table
local function fragment_node(possible_name, field_path, ancestors, operation, checked_fields)
  local fragment_path = push_path(field_path, "on:" .. possible_name)
  local fragment_key = table.concat(fragment_path, ".")
  return {
    kind = "fragment",
    id = fragment_key,
    path = fragment_path,
    name = "... on " .. possible_name,
    typeName = possible_name,
    checked = checked_fields[fragment_key] == true,
    operation = operation,
    children = {},
    pending = {
      typeName = possible_name,
      path = fragment_path,
      ancestors = ancestors,
      operation = operation,
    },
  }
end

---One level of a type: its fields and their arguments.
---A nested return type or inline fragment is only a pending flag until that row is opened.
---@param schema table
---@param type_name string
---@param path string[]
---@param ancestors table<string, boolean>
---@param operation string
---@param checked_fields table<string, boolean>
---@param checked_args table<string, boolean>
---@param arg_values table<string, string>
---@return table[]
local function fields_of(schema, type_name, path, ancestors, operation, checked_fields, checked_args, arg_values)
  if type(type_name) ~= "string" or type_name == "" or ancestors[type_name] then return {} end
  local types = schema.types or {}
  local type_def = types[type_name]
  if type(type_def) ~= "table" or type(type_def.fields) ~= "table" then return {} end

  local child_ancestors = with_type(ancestors, type_name)
  local nodes = {}
  for _, field in ipairs(type_def.fields) do
    if type(field) == "table" and type(field.name) == "string" and field.name ~= "__typename" then
      local field_path = push_path(path, field.name)
      local key = table.concat(field_path, ".")
      local children = {}
      for _, arg in ipairs(field.args or {}) do
        if type(arg) == "table" and type(arg.name) == "string" then
          children[#children + 1] =
            arg_node(arg, field_path, key .. "." .. arg.name, operation, checked_args, arg_values)
        end
      end
      local pending = nil
      local return_name = field.typeName
      if
        field.isLeaf ~= true
        and type(return_name) == "string"
        and return_name ~= ""
        and not child_ancestors[return_name]
      then
        local return_type = types[return_name]
        pending = {
          typeName = return_name,
          path = field_path,
          ancestors = child_ancestors,
          operation = operation,
          possibleTypes = type(return_type) == "table" and return_type.possibleTypes or nil,
        }
      end
      nodes[#nodes + 1] = {
        kind = "field",
        id = key,
        path = field_path,
        name = field.name,
        type = field.type,
        typeName = field.typeName,
        description = field.description,
        isLeaf = field.isLeaf == true,
        checked = checked_fields[key] == true,
        operation = operation,
        children = children,
        pending = pending,
      }
    end
  end
  return nodes
end

---@param node table|nil
---@return boolean
function M.foldable(node)
  return type(node) == "table" and (node.pending ~= nil or (node.children and #node.children > 0))
end

---Fill a pending row with the next type's fields. Ancestors already on this path stay collapsed.
---@param node table
---@param schema table|nil
---@param graphql table|nil
function M.expand(node, schema, graphql)
  if type(node) ~= "table" or type(node.pending) ~= "table" then return end
  local pending = node.pending
  node.pending = nil
  schema = schema or {}
  local checked_fields, checked_args, arg_values = selection(graphql)
  local nested = fields_of(
    schema,
    pending.typeName,
    pending.path or {},
    pending.ancestors or {},
    pending.operation,
    checked_fields,
    checked_args,
    arg_values
  )
  node.children = node.children or {}
  for _, child in ipairs(nested) do
    node.children[#node.children + 1] = child
  end
  if type(pending.possibleTypes) == "table" then
    for _, possible_name in ipairs(pending.possibleTypes) do
      if type(possible_name) == "string" and possible_name ~= "" then
        node.children[#node.children + 1] =
          fragment_node(possible_name, pending.path or {}, pending.ancestors or {}, pending.operation, checked_fields)
      end
    end
  end
end

---Load every level the user has already unfolded, and nothing deeper.
---@param nodes table[]
---@param old_folds table<string, boolean>|nil
---@param schema table|nil
---@param graphql table|nil
function M.materialize_open(nodes, old_folds, schema, graphql)
  for _, node in ipairs(nodes or {}) do
    if node.pending and old_folds and old_folds[node.id] == false then M.expand(node, schema, graphql) end
    if node.children then M.materialize_open(node.children, old_folds, schema, graphql) end
  end
end

---@param filter string
---@param node table
---@return boolean
local function node_matches(filter, node)
  if filter == "" then return true end
  local needle = filter:lower()
  local function has(text)
    return type(text) == "string" and text:lower():find(needle, 1, true) ~= nil
  end
  return has(node.name) or has(node.description) or has(node.type)
end

---@param field table
---@param filter string
---@return boolean
local function field_matches(filter, field)
  if node_matches(filter, field) then return true end
  for _, arg in ipairs(field.args or {}) do
    if type(arg) == "table" and node_matches(filter, arg) then return true end
  end
  return false
end

---First path from a root to each type that contains a match. Each type is entered once.
---@param schema table
---@param filter string
---@return table<string, table>
---@return table<string, boolean>
local function first_paths(schema, filter)
  local types = schema.types or {}
  local visited = {}
  local parent = {}
  local queue = {}
  local head = 1
  for _, root_name in ipairs { schema.queryType, schema.mutationType, schema.subscriptionType } do
    if type(root_name) == "string" and root_name ~= "" and not visited[root_name] then
      visited[root_name] = true
      queue[#queue + 1] = root_name
    end
  end
  local matching = {}
  while head <= #queue do
    local type_name = queue[head]
    head = head + 1
    local type_def = types[type_name]
    if type(type_def) == "table" and type(type_def.fields) == "table" then
      for _, field in ipairs(type_def.fields) do
        if type(field) == "table" and type(field.name) == "string" and field.name ~= "__typename" then
          if field_matches(filter, field) then matching[type_name] = true end
          if field.isLeaf ~= true and type(field.typeName) == "string" and field.typeName ~= "" then
            if not visited[field.typeName] then
              visited[field.typeName] = true
              parent[field.typeName] = { from = type_name, field = field.name }
              queue[#queue + 1] = field.typeName
            end
            local return_type = types[field.typeName]
            local possible = type(return_type) == "table" and return_type.possibleTypes or nil
            if type(possible) == "table" then
              for _, possible_name in ipairs(possible) do
                if type(possible_name) == "string" and possible_name ~= "" and not visited[possible_name] then
                  visited[possible_name] = true
                  parent[possible_name] = { from = type_name, field = field.name, fragment = possible_name }
                  queue[#queue + 1] = possible_name
                end
              end
            end
          end
        end
      end
    end
  end
  local keep = {}
  for type_name in pairs(matching) do
    local current = type_name
    local guard = 0
    while type(current) == "string" and current ~= "" and not keep[current] and guard < 10000 do
      keep[current] = true
      local edge = parent[current]
      current = edge and edge.from
      guard = guard + 1
    end
  end
  return parent, keep
end

---@param schema table
---@param type_name string
---@param path string[]
---@param ancestors table<string, boolean>
---@param operation string
---@param checked_fields table<string, boolean>
---@param checked_args table<string, boolean>
---@param arg_values table<string, string>
---@param filter string
---@param parent table<string, table>
---@param keep table<string, boolean>
---@return table[]
local function search_fields(
  schema,
  type_name,
  path,
  ancestors,
  operation,
  checked_fields,
  checked_args,
  arg_values,
  filter,
  parent,
  keep
)
  if type(type_name) ~= "string" or type_name == "" or ancestors[type_name] then return {} end
  local types = schema.types or {}
  local type_def = types[type_name]
  if type(type_def) ~= "table" or type(type_def.fields) ~= "table" then return {} end

  local child_ancestors = with_type(ancestors, type_name)
  local nodes = {}
  for _, field in ipairs(type_def.fields) do
    if type(field) == "table" and type(field.name) == "string" and field.name ~= "__typename" then
      local field_path = push_path(path, field.name)
      local key = table.concat(field_path, ".")
      local show = field_matches(filter, field)
      local return_name = field.typeName
      local edge_type = false
      if type(return_name) == "string" and return_name ~= "" and keep[return_name] then
        local edge = parent[return_name]
        if edge and not edge.fragment and edge.from == type_name and edge.field == field.name then
          edge_type = true
          show = true
        end
      end
      local fragments = {}
      local return_type = type(return_name) == "string" and types[return_name] or nil
      local possible = type(return_type) == "table" and return_type.possibleTypes or nil
      if type(possible) == "table" then
        for _, possible_name in ipairs(possible) do
          local edge = type(possible_name) == "string" and parent[possible_name] or nil
          if
            edge
            and edge.fragment == possible_name
            and edge.from == type_name
            and edge.field == field.name
            and keep[possible_name]
          then
            fragments[#fragments + 1] = possible_name
            show = true
          end
        end
      end
      if show then
        local children = {}
        for _, arg in ipairs(field.args or {}) do
          if type(arg) == "table" and type(arg.name) == "string" and node_matches(filter, arg) then
            children[#children + 1] =
              arg_node(arg, field_path, key .. "." .. arg.name, operation, checked_args, arg_values)
          end
        end
        if edge_type and not child_ancestors[return_name] then
          local nested = search_fields(
            schema,
            return_name,
            field_path,
            child_ancestors,
            operation,
            checked_fields,
            checked_args,
            arg_values,
            filter,
            parent,
            keep
          )
          for _, child in ipairs(nested) do
            children[#children + 1] = child
          end
        end
        for _, possible_name in ipairs(fragments) do
          local fragment = fragment_node(possible_name, field_path, child_ancestors, operation, checked_fields)
          fragment.pending = nil
          fragment.children = search_fields(
            schema,
            possible_name,
            fragment.path,
            child_ancestors,
            operation,
            checked_fields,
            checked_args,
            arg_values,
            filter,
            parent,
            keep
          )
          children[#children + 1] = fragment
        end
        nodes[#nodes + 1] = {
          kind = "field",
          id = key,
          path = field_path,
          name = field.name,
          type = field.type,
          typeName = field.typeName,
          description = field.description,
          isLeaf = field.isLeaf == true,
          checked = checked_fields[key] == true,
          operation = operation,
          children = children,
        }
      end
    end
  end
  return nodes
end

---@param schema table|nil
---@param graphql table|nil
---@param filter string|nil
---@return table[]
function M.build(schema, graphql, filter)
  if type(schema) ~= "table" then return {} end
  graphql = graphql or {}
  filter = filter or ""
  local checked_fields, checked_args, arg_values = selection(graphql)
  local roots = {
    { operation = "query", type_name = schema.queryType, title = "Query" },
    { operation = "mutation", type_name = schema.mutationType, title = "Mutation" },
    { operation = "subscription", type_name = schema.subscriptionType, title = "Subscription" },
  }
  local parent, keep
  if filter ~= "" then
    parent, keep = first_paths(schema, filter)
  end
  local nodes = {}
  for _, root in ipairs(roots) do
    if type(root.type_name) == "string" and root.type_name ~= "" then
      local children
      if filter ~= "" then
        children = search_fields(
          schema,
          root.type_name,
          {},
          {},
          root.operation,
          checked_fields,
          checked_args,
          arg_values,
          filter,
          parent,
          keep
        )
      else
        children = fields_of(schema, root.type_name, {}, {}, root.operation, checked_fields, checked_args, arg_values)
      end
      if filter == "" or #children > 0 then
        nodes[#nodes + 1] = {
          kind = "root",
          id = "root:" .. root.operation,
          name = root.title,
          operation = root.operation,
          typeName = root.type_name,
          children = children,
        }
      end
    end
  end
  return nodes
end

---@param tree table[]
---@return table<string, boolean>
function M.default_folds(tree)
  local folds = {}
  local function walk(nodes)
    for _, node in ipairs(nodes or {}) do
      if node.kind ~= "root" and M.foldable(node) then folds[node.id] = true end
      if node.children then walk(node.children) end
    end
  end
  walk(tree)
  return folds
end

---@param old_folds table<string, boolean>|nil
---@param tree table[]
---@return table<string, boolean>
function M.merge_folds(old_folds, tree)
  local merged = M.default_folds(tree)
  for id, folded in pairs(old_folds or {}) do
    if merged[id] ~= nil then merged[id] = folded end
  end
  return merged
end

return M
