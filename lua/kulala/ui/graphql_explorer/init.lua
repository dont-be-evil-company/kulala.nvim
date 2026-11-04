local CMD = require("kulala.cmd")
local CONFIG = require("kulala.config")
local DB = require("kulala.db")
local GLOBALS = require("kulala.globals")
local Highlight = require("kulala.ui.graphql_explorer.highlight")
local INLAY = require("kulala.inlay")
local KEYMAPS = require("kulala.config.keymaps")
local KULALA_CORE = require("kulala.cmd.kulala_core_bridge")
local Logger = require("kulala.logger")
local Render = require("kulala.ui.graphql_explorer.render")
local Tree = require("kulala.ui.graphql_explorer.tree")
local UI = require("kulala.ui")
local UI_utils = require("kulala.ui.utils")

local M = {}

---@class kulala.graphql_explorer.state
---@field bufnr integer
---@field winnr integer|nil
---@field http_bufnr integer
---@field parent_line integer
---@field parent_request DocumentRequest|nil
---@field graphql table
---@field folds table<string, boolean>
---@field line_map table[]
---@field tree table[]
---@field filter string
---@field applying boolean
---@field reload_token integer

local instance ---@type kulala.graphql_explorer.state|nil

local function panel_signs()
  local signs = CONFIG.get().graphql_panel and CONFIG.get().graphql_panel.signs
  if type(signs) == "table" then return signs end
  return { folded = ">", expanded = "v" }
end

local function explorer_split_direction()
  local config = CONFIG.get()
  local panel = config.graphql_panel or {}
  local split = panel.split
  if split == nil then
    local ui = config.ui or {}
    split = ui.split_direction == "vertical" and "right"
      or ui.split_direction == "horizontal" and "below"
      or ui.split_direction
  end
  if type(split) == "function" then return split() end
  return split or "right"
end

local function get_explorer_buffer()
  local buf = vim.fn.bufnr(GLOBALS.GRAPHQL_EXPLORER_ID)
  return buf > 0 and buf
end

local function get_explorer_window()
  local buf = get_explorer_buffer()
  if not buf then return nil end
  local win = vim.fn.win_findbuf(buf)[1]
  if win and win > 0 then return win end
  return nil
end

---@param bufnr integer
---@param http_bufnr integer
---@return integer
local function open_explorer_window(bufnr, http_bufnr)
  local existing = get_explorer_window()
  if existing then return existing end

  local config = CONFIG.get()
  local panel = config.graphql_panel or {}
  local request_win = vim.fn.win_findbuf(http_bufnr)[1]
  if not request_win or request_win == 0 then request_win = vim.api.nvim_get_current_win() end

  local win_opts = vim.deepcopy(panel.win_opts or config.ui.win_opts or {})
  local wo = win_opts.wo or {}
  win_opts.bo = nil
  win_opts.wo = nil

  local win = vim.api.nvim_open_win(
    bufnr,
    false,
    vim.tbl_extend("force", {
      split = explorer_split_direction(),
      win = request_win,
    }, win_opts)
  )

  wo = vim.tbl_extend("keep", wo, {
    number = false,
    relativenumber = false,
    wrap = true,
    signcolumn = "no",
    cursorline = true,
  })
  vim.iter(wo):each(function(key, value)
    pcall(vim.api.nvim_set_option_value, key, value, { win = win, scope = "local" })
  end)
  return win
end

local function active_window(state)
  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then return state.winnr end
  local win = get_explorer_window()
  if win then state.winnr = win end
  return win
end

local function rebuild(state)
  local old_folds = state.folds
  state.tree = Tree.build(state.graphql.schema, state.graphql, state.filter)
  if state.filter == "" then Tree.materialize_open(state.tree, old_folds, state.graphql.schema, state.graphql) end
  state.folds = Tree.merge_folds(old_folds, state.tree)
end

local function paint(state)
  if not vim.api.nvim_buf_is_valid(state.bufnr) then return end
  local win = active_window(state)
  local row = win and vim.api.nvim_win_get_cursor(win)[1] or 1
  local lines, line_map = Render.build_lines(state.tree, state.folds, state.filter, {
    endpoint = state.graphql.endpoint,
    patchable = state.graphql.patchable,
    reason = state.graphql.reason,
  }, panel_signs())
  state.line_map = line_map
  vim.api.nvim_set_option_value("modifiable", true, { buf = state.bufnr })
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.bufnr })
  Highlight.apply(state.bufnr, lines, line_map)
  if win and vim.api.nvim_win_is_valid(win) then
    local last = math.max(vim.api.nvim_buf_line_count(state.bufnr), 1)
    vim.api.nvim_win_set_cursor(win, { math.min(row, last), 0 })
  end
end

local function item_under_cursor(state)
  local win = active_window(state)
  if not win then return nil end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  return state.line_map[row]
end

---@param range table|nil
---@param body string|nil
local function body_lines(range, body)
  local text = body or ""
  if range and range.leadingBlank == true then text = "\n" .. text end
  local lines = vim.split(text, "\n", { plain = true })
  if text ~= "" and text:sub(-1) == "\n" then table.remove(lines) end
  return lines
end

---@param state kulala.graphql_explorer.state
---@param range table|nil
---@param body string|nil
local function apply_body(state, range, body)
  if type(range) ~= "table" or type(range.startLine) ~= "number" then return end
  if not vim.api.nvim_buf_is_valid(state.http_bufnr) then return end
  local start0 = range.startLine - 1
  local end0 = range.insert == true and start0 or (range.endLine or range.startLine)
  if start0 < 0 then return end
  state.applying = true
  vim.api.nvim_buf_set_lines(state.http_bufnr, start0, end0, false, body_lines(range, body))
  vim.schedule(function()
    if instance == state then state.applying = false end
  end)
end

---@param state kulala.graphql_explorer.state
---@param graphql table
local function apply_payload(state, graphql)
  state.graphql.schema = graphql.schema or state.graphql.schema
  state.graphql.endpoint = graphql.endpoint or state.graphql.endpoint
  state.graphql.cacheKey = graphql.cacheKey or state.graphql.cacheKey
  state.graphql.operation = graphql.operation or state.graphql.operation
  state.graphql.query = graphql.query
  state.graphql.body = graphql.body
  state.graphql.variables = graphql.variables
  state.graphql.patchable = graphql.patchable ~= false
  state.graphql.reason = graphql.reason
  state.graphql.bodyRange = graphql.bodyRange
  state.graphql.checkedFields = graphql.checkedFields or {}
  state.graphql.checkedArgs = graphql.checkedArgs or {}
  state.graphql.argValues = graphql.argValues or {}
  rebuild(state)
end

---@param state kulala.graphql_explorer.state
local function reload_from_buffer(state)
  local res, err = KULALA_CORE.graphql_explorer_load(state.http_bufnr, state.parent_line, 1)
  if not res or type(res.graphql) ~= "table" then return Logger.error(err or "Failed to reload GraphQL explorer") end
  if res.graphql.rewritten == true and res.graphql.patchable ~= false then
    apply_body(state, res.graphql.bodyRange, res.graphql.body)
  end
  apply_payload(state, res.graphql)
  paint(state)
end

local function release()
  pcall(vim.api.nvim_del_augroup_by_name, "KulalaGraphQLExplorer")
  if not instance then return end
  instance.tree = nil
  instance.line_map = nil
  instance.folds = nil
  instance.graphql = nil
  instance.winnr = nil
  instance = nil
end

local function watch_http_buffer(state)
  local group = vim.api.nvim_create_augroup("KulalaGraphQLExplorer", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = state.http_bufnr,
    desc = "Kulala: refresh GraphQL explorer after the request body changes",
    callback = function()
      if not instance or instance.applying then return end
      instance.reload_token = (instance.reload_token or 0) + 1
      local token = instance.reload_token
      vim.defer_fn(function()
        if not instance or instance.reload_token ~= token or instance.applying then return end
        if not vim.api.nvim_buf_is_valid(instance.http_bufnr) then return end
        reload_from_buffer(instance)
      end, 200)
    end,
  })
end

---@param state kulala.graphql_explorer.state
---@param edit table
---@return table|nil
---@return string|nil
local function patch(state, edit)
  if state.graphql.patchable == false then return nil, state.graphql.reason or "GraphQL body cannot be patched" end
  local res, err = KULALA_CORE.graphql_explorer_patch(state.http_bufnr, state.parent_line, 1, edit)
  if not res then return nil, err or "Failed to patch GraphQL body" end
  if res.ok ~= true then return nil, res.error or err or "Failed to patch GraphQL body" end
  if res.patchable == false then
    state.graphql.patchable = false
    state.graphql.reason = res.reason
    rebuild(state)
    paint(state)
    return nil, res.reason or "GraphQL body cannot be patched"
  end
  apply_body(state, res.bodyRange, res.body)
  apply_payload(state, res)
  paint(state)
  return res, nil
end

local function toggle_fold(state)
  local item = item_under_cursor(state)
  if not item or not item.id or not Tree.foldable(item) then return end
  state.folds[item.id] = state.folds[item.id] ~= true
  if state.folds[item.id] == false then
    Tree.expand(item, state.graphql.schema, state.graphql)
    for _, child in ipairs(item.children or {}) do
      if Tree.foldable(child) and state.folds[child.id] == nil then state.folds[child.id] = true end
    end
  end
  paint(state)
end

---@param options any
---@return string[]|nil
local function option_list(options)
  if type(options) ~= "table" then return nil end
  local list = {}
  for _, value in ipairs(options) do
    if type(value) == "string" and value ~= "" then list[#list + 1] = value end
  end
  if #list == 0 then return nil end
  return list
end

local function arg_choices(item)
  local options = option_list(item.options)
  if not options and item.typeName == "Boolean" then options = { "true", "false" } end
  return options
end

local function prompt_arg(state, item)
  local function commit(value)
    if value == nil or value == "" then return end
    local updated, err = patch(state, {
      kind = "setArg",
      path = item.path,
      name = item.argName,
      value = value,
    })
    if not updated then Logger.error(err or "Failed to update argument") end
  end
  local options = arg_choices(item)
  if options then
    vim.ui.select(options, { prompt = item.name .. ": " }, function(choice)
      if choice then commit(choice) end
    end)
    return
  end
  vim.ui.input({
    prompt = item.name .. " (GraphQL literal): ",
    default = type(item.value) == "string" and item.value or "",
  }, function(value)
    if value == nil or value == "" then return end
    commit(value)
  end)
end

local function toggle_checkbox(state)
  local item = item_under_cursor(state)
  if not item then return end
  if item.kind ~= "field" and item.kind ~= "fragment" and item.kind ~= "arg" then return end
  if item.operation and state.graphql.operation and item.operation ~= state.graphql.operation then
    local switched, err = patch(state, { kind = "setOperation", operation = item.operation })
    if not switched then return Logger.error(err or "Failed to switch GraphQL operation") end
  end
  if item.kind == "arg" and not item.checked and not arg_choices(item) then return prompt_arg(state, item) end
  local edit
  if item.kind == "arg" then
    edit = { kind = "toggleArg", path = item.path, name = item.argName }
  else
    edit = { kind = "toggleField", path = item.path }
  end
  local ok, err = patch(state, edit)
  if not ok then Logger.error(err or "Failed to update GraphQL selection") end
end

local function edit_arg(state)
  local item = item_under_cursor(state)
  if not item or item.kind ~= "arg" then return Logger.warn("Select an argument to edit") end
  prompt_arg(state, item)
end

local function search(state)
  vim.ui.input({ prompt = "GraphQL search: ", default = state.filter }, function(value)
    if value == nil then return end
    state.filter = vim.trim(value)
    rebuild(state)
    paint(state)
  end)
end

local function run_query(state)
  if not state.parent_request then return Logger.error("No parent GraphQL request") end
  local result, err = KULALA_CORE.graphql_explorer_run(state.http_bufnr, state.parent_line, 1)
  if not result then return Logger.error(err or "Failed to run GraphQL query") end
  DB.set_current_buffer(state.http_bufnr)
  local db = DB.global_update()
  local previous_response_pos = #db.responses
  db.previous_response_pos = previous_response_pos
  CMD.deliver_core_result(result, state.parent_request, function(success, duration, icon_linenr, response_id)
    local elapsed_ms = success and UI_utils.pretty_ms(duration) or nil
    INLAY.show(state.http_bufnr, success and "done" or "error", icon_linenr, elapsed_ms)
    UI.advance_to_response(response_id, previous_response_pos)
    UI.open_default_view()
  end)
end

local function yank_http(state)
  KULALA_CORE.guard(function()
    local content, err = KULALA_CORE.graphql_explorer_to_http(state.http_bufnr, state.parent_line, 1)
    if not content then return Logger.error(err or "Failed to copy GraphQL request") end
    vim.fn.setreg("+", content)
    vim.fn.setreg('"', content)
    Logger.info("Copied HTTP request")
  end)
end

local function refresh(state)
  local cache_key = state.graphql and state.graphql.cacheKey
  if type(cache_key) == "string" and cache_key ~= "" then KULALA_CORE.clear_graphql_schema(cache_key) end
  reload_from_buffer(state)
end

local function ensure_explorer_buffer()
  local bufnr = get_explorer_buffer()
  if bufnr then return bufnr end
  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, GLOBALS.GRAPHQL_EXPLORER_ID)
  vim.api.nvim_set_option_value("filetype", "kulala_graphql", { buf = bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
  return bufnr
end

---@param graphql table
---@param parent_request DocumentRequest|nil
---@param http_bufnr integer|nil
function M.open(graphql, parent_request, http_bufnr)
  Highlight.setup()
  if type(graphql) ~= "table" or type(graphql.schema) ~= "table" then
    return Logger.error("GraphQL explorer schema is empty")
  end
  http_bufnr = http_bufnr or DB.get_current_buffer() or vim.api.nvim_get_current_buf()
  local bufnr = ensure_explorer_buffer()
  local same = instance and instance.bufnr == bufnr
  if not same then
    instance = {
      bufnr = bufnr,
      winnr = nil,
      http_bufnr = http_bufnr,
      parent_line = parent_request and parent_request.start_line or vim.api.nvim_win_get_cursor(0)[1],
      parent_request = parent_request,
      graphql = graphql,
      folds = {},
      line_map = {},
      tree = {},
      filter = "",
      applying = false,
      reload_token = 0,
    }
    KEYMAPS.setup_graphql_panel_keymaps(bufnr)
    watch_http_buffer(instance)
  else
    instance.http_bufnr = http_bufnr
    instance.parent_request = parent_request
    instance.parent_line = parent_request and parent_request.start_line or instance.parent_line
    instance.graphql = graphql
    KEYMAPS.setup_graphql_panel_keymaps(bufnr)
    watch_http_buffer(instance)
  end
  if instance.graphql.rewritten == true and instance.graphql.patchable ~= false then
    apply_body(instance, instance.graphql.bodyRange, instance.graphql.body)
  end
  rebuild(instance)
  instance.winnr = open_explorer_window(bufnr, http_bufnr)
  if instance.winnr and vim.api.nvim_win_is_valid(instance.winnr) then
    vim.api.nvim_create_autocmd("WinClosed", {
      group = "KulalaGraphQLExplorer",
      pattern = tostring(instance.winnr),
      callback = function()
        release()
      end,
    })
    vim.api.nvim_set_current_win(instance.winnr)
  end
  paint(instance)
end

function M.toggle_fold()
  if instance then toggle_fold(instance) end
end

function M.toggle()
  if instance then toggle_checkbox(instance) end
end

function M.edit()
  if instance then edit_arg(instance) end
end

function M.search()
  if instance then search(instance) end
end

function M.run()
  if instance then run_query(instance) end
end

function M.yank()
  if instance then yank_http(instance) end
end

function M.refresh()
  if instance then refresh(instance) end
end

---@return integer|nil
function M.get_window()
  return get_explorer_window()
end

---True when the explorer is open and the cursor is in it, or on the request it is editing.
function M.composing()
  if not instance then return false end
  local win = get_explorer_window()
  if not win or not vim.api.nvim_win_is_valid(win) then return false end
  local current = vim.api.nvim_get_current_win()
  if current == win then return true end
  if vim.api.nvim_win_get_buf(current) ~= instance.http_bufnr then return false end
  local line = vim.api.nvim_win_get_cursor(current)[1]
  local parent = instance.parent_request
  if parent and type(parent.start_line) == "number" and type(parent.end_line) == "number" then
    return line >= parent.start_line and line <= parent.end_line
  end
  return line == instance.parent_line
end

function M.close()
  local win = instance and instance.winnr or get_explorer_window()
  release()
  if win and vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
end

return M
