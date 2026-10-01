local CMD = require("kulala.cmd")
local CONFIG = require("kulala.config")
local DB = require("kulala.db")
local GLOBALS = require("kulala.globals")
local Highlight = require("kulala.ui.openapi_panel.highlight")
local INLAY = require("kulala.inlay")
local KEYMAPS = require("kulala.config.keymaps")
local KULALA_CORE = require("kulala.cmd.kulala_core_bridge")
local Logger = require("kulala.logger")
local PanelState = require("kulala.ui.openapi_panel.state")
local PickFile = require("kulala.ui.pick_file")
local Render = require("kulala.ui.openapi_panel.render")
local UI = require("kulala.ui")
local UI_utils = require("kulala.ui.utils")

local M = {}

---@class kulala.openapi_panel.state
---@field bufnr integer
---@field winnr integer|nil
---@field http_bufnr integer
---@field parent_line integer
---@field parent_request DocumentRequest|nil
---@field openapi table
---@field folds table<string, boolean>
---@field line_map table[]
---@field tree table[]
---@field try_values table<string, table<string, string>>

local instance ---@type kulala.openapi_panel.state|nil

local function panel_signs()
  local signs = CONFIG.get().openapi_panel and CONFIG.get().openapi_panel.signs
  if type(signs) == "table" then return signs end
  return { folded = ">", expanded = "v" }
end

---Normalize JSON-decoded option lists (arrays or map-like tables).
---@param options any
---@return string[]|nil
local function option_list(options)
  if type(options) ~= "table" then return nil end
  local list = {}
  if vim.islist(options) then
    for _, v in ipairs(options) do
      if type(v) == "string" and v ~= "" then table.insert(list, v) end
    end
  else
    for _, v in pairs(options) do
      if type(v) == "string" and v ~= "" then table.insert(list, v) end
    end
    table.sort(list)
  end
  if #list == 0 then return nil end
  return list
end

---When the cursor is on a description line, resolve the parent editable node.
---@param state kulala.openapi_panel.state
---@param item table|nil
---@return table|nil
local function editable_item(state, item)
  if not item then return nil end
  if item.kind == "tryItOut" then return item end
  if item.kind == "text" and item.parentId then
    for _, node in ipairs(state.line_map) do
      if node.id == item.parentId and node.kind == "tryItOut" then return node end
    end
  end
  return nil
end

local function explorer_split_direction()
  local config = CONFIG.get()
  local panel = config.openapi_panel or {}
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
  local buf = vim.fn.bufnr(GLOBALS.OPENAPI_EXPLORER_ID)
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
---@return integer winnr
local function open_explorer_window(bufnr, http_bufnr)
  local existing = get_explorer_window()
  if existing then return existing end

  local config = CONFIG.get()
  local panel = config.openapi_panel or {}
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
    signcolumn = "yes:1",
  })

  vim.iter(wo):each(function(key, value)
    pcall(vim.api.nvim_set_option_value, key, value, { win = win, scope = "local" })
  end)

  return win
end

local function default_folds(tree)
  return PanelState.default_folds(tree)
end

local function seed_try_values(tree)
  return PanelState.seed_try_values(tree)
end

local function merge_folds(old_folds, tree)
  return PanelState.merge_folds(old_folds, tree)
end

local function merge_try_values(old_values, tree)
  return PanelState.merge_try_values(old_values, tree)
end

---@param state kulala.openapi_panel.state
---@param openapi table
local function apply_openapi_payload(state, openapi)
  local tree = openapi.tree or {}
  if #tree == 0 then return false, "OpenAPI explorer tree is empty" end
  state.openapi = openapi
  state.tree = tree
  state.folds = merge_folds(state.folds, tree)
  state.try_values = merge_try_values(state.try_values, tree)
  return true
end

local function paint(state)
  if not vim.api.nvim_buf_is_valid(state.bufnr) then return end
  local lines, line_map = Render.build_lines(state.tree, state.folds, state.try_values, panel_signs())
  state.line_map = line_map
  vim.api.nvim_set_option_value("modifiable", true, { buf = state.bufnr })
  vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.bufnr })
  Highlight.apply(state.bufnr, lines, line_map)
end

local function refresh(state)
  if not state.parent_request then return Logger.error("No parent OpenAPI request") end

  local cache_key = state.openapi and state.openapi.cacheKey
  if type(cache_key) == "string" and cache_key ~= "" then KULALA_CORE.clear_openapi_schema(cache_key) end

  local res, err = KULALA_CORE.openapi_load(state.http_bufnr, state.parent_line, 1)
  if not res or not res.openapi then return Logger.error(err or "Failed to refresh OpenAPI spec") end

  local ok, apply_err = apply_openapi_payload(state, res.openapi)
  if not ok then return Logger.error(apply_err or "Failed to refresh OpenAPI explorer") end
  paint(state)
end

local function active_window(state)
  if state.winnr and vim.api.nvim_win_is_valid(state.winnr) then return state.winnr end
  local win = get_explorer_window()
  if win then state.winnr = win end
  return win
end

local function item_under_cursor(state)
  local win = active_window(state)
  if not win then return nil end
  local row = vim.api.nvim_win_get_cursor(win)[1]
  return state.line_map[row]
end

local function toggle_fold(state)
  local item = item_under_cursor(state)
  if not item or not item.id then return end
  if item.children == nil or #item.children == 0 then return end
  state.folds[item.id] = state.folds[item.id] ~= true
  paint(state)
end

---@param state kulala.openapi_panel.state
---@param operation_key string
---@return table<string, string>|nil
local function overrides_for_operation(state, operation_key)
  local vals = state.try_values[operation_key]
  if not vals or vim.tbl_isempty(vals) then return nil end
  return vals
end

---@param parent DocumentRequest
---@param operation_key string
---@param result table
---@return DocumentRequest
local function operation_target(parent, operation_key, result)
  local target = vim.deepcopy(parent)
  local block_name
  if type(result.blockName) == "string" and result.blockName ~= "" then
    block_name = result.blockName
  else
    local safe = operation_key:gsub("[^%w]+", "_")
    block_name = (parent.name and parent.name ~= "" and (parent.name .. "::") or "") .. safe
  end
  target._kulala_block_name = block_name
  target.name = block_name
  return target
end

local function run_operation(state, operation_key)
  if not state.parent_request then return Logger.error("No parent OpenAPI request") end
  operation_key = operation_key or (item_under_cursor(state) or {}).operationKey
  if not operation_key then return Logger.warn("Select an operation to run") end

  local overrides = overrides_for_operation(state, operation_key)
  local result, err =
    KULALA_CORE.openapi_run_operation(state.http_bufnr, operation_key, state.parent_line, 1, overrides)
  if not result then return Logger.error(err or "Failed to run OpenAPI operation") end

  DB.set_current_buffer(state.http_bufnr)
  local db = DB.global_update()
  local previous_response_pos = #db.responses
  db.previous_response_pos = previous_response_pos
  local target = operation_target(state.parent_request, operation_key, result)
  CMD.deliver_core_result(result, target, function(success, duration, icon_linenr, response_id)
    local elapsed_ms = success and UI_utils.pretty_ms(duration) or nil
    INLAY.show(state.http_bufnr, success and "done" or "error", icon_linenr, elapsed_ms)
    UI.advance_to_response(response_id, previous_response_pos)
    UI.open_default_view()
  end)
end

---@param options string[]
---@param current string
---@param prompt string
---@param on_done fun(value: string)
local function edit_multi_select(options, current, prompt, on_done)
  local NONE = "(none)"
  ---@type table<string, boolean>
  local selected = {}
  for part in vim.gsplit(current or "", ",", true) do
    local trimmed = vim.trim(part)
    if trimmed ~= "" and trimmed ~= NONE then selected[trimmed] = true end
  end

  local function commit(picked)
    ---@type table<string, boolean>
    local set = {}
    local clear = false
    for _, v in ipairs(picked or {}) do
      if v == NONE then
        clear = true
      elseif type(v) == "string" and v ~= "" then
        set[v] = true
      end
    end
    -- Explicit "(none)" with no other picks → empty (optional params).
    if clear and vim.tbl_isempty(set) then
      on_done("")
      return
    end
    local list = {}
    for _, opt in ipairs(options) do
      if set[opt] then table.insert(list, opt) end
    end
    on_done(table.concat(list, ","))
  end

  -- Prefer fzf-lua native multi-select (one shot; avoids reopen/focus loss).
  -- fzf always returns the highlighted row when nothing is Tab-marked, so we
  -- expose an explicit "(none)" entry for optional empty selections.
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  if ok_fzf and type(fzf.fzf_exec) == "function" then
    local ordered = { NONE }
    for _, opt in ipairs(options) do
      if selected[opt] then table.insert(ordered, opt) end
    end
    for _, opt in ipairs(options) do
      if not selected[opt] then table.insert(ordered, opt) end
    end
    fzf.fzf_exec(ordered, {
      prompt = prompt .. " (Tab multi, Enter confirm, pick (none) for empty) ",
      fzf_opts = {
        ["--multi"] = true,
        ["--bind"] = "tab:toggle+down,shift-tab:toggle+up,ctrl-d:deselect-all",
      },
      actions = {
        ["default"] = function(sel)
          commit(sel or {})
        end,
      },
    })
    return
  end

  -- Focused float checklist: stays open while toggling (no picker reopen).
  local Float = require("kulala.ui.float")
  local lines = {
    prompt,
    "Space/Tab toggle · Enter confirm (none checked = empty) · q cancel",
    "",
  }
  for _, opt in ipairs(options) do
    table.insert(lines, (selected[opt] and "[x] " or "[ ] ") .. opt)
  end

  local float = Float.create(lines, {
    name = "kulala://openapi-multiselect",
    title = " Multi select ",
    focusable = true,
    relative = "editor",
    border = "rounded",
    width = math.min(60, vim.o.columns - 4),
    height = math.min(#lines + 2, math.max(8, vim.o.lines - 6)),
    row = math.floor((vim.o.lines - math.min(#lines + 2, math.max(8, vim.o.lines - 6))) / 2),
    col = math.floor((vim.o.columns - math.min(60, vim.o.columns - 4)) / 2),
    bo = { buftype = "nofile", bufhidden = "wipe", swapfile = false, modifiable = false },
    wo = { number = false, relativenumber = false, cursorline = true, wrap = false },
  })

  local function option_row(lnum)
    return lnum >= 4 and lnum - 3 or nil
  end

  local function redraw()
    local out = {
      prompt,
      "Space/Tab toggle · Enter confirm (none checked = empty) · q cancel",
      "",
    }
    for _, opt in ipairs(options) do
      table.insert(out, (selected[opt] and "[x] " or "[ ] ") .. opt)
    end
    vim.bo[float.buf].modifiable = true
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, out)
    vim.bo[float.buf].modifiable = false
  end

  local function toggle_at_cursor()
    local lnum = vim.api.nvim_win_get_cursor(float.win)[1]
    local idx = option_row(lnum)
    if not idx or not options[idx] then return end
    local opt = options[idx]
    selected[opt] = not selected[opt]
    redraw()
    vim.api.nvim_win_set_cursor(float.win, { lnum, 0 })
  end

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = float.buf, silent = true, nowait = true })
  end

  map("<Space>", toggle_at_cursor)
  map("<Tab>", toggle_at_cursor)
  map("<CR>", function()
    float.close()
    local list = {}
    for _, opt in ipairs(options) do
      if selected[opt] then table.insert(list, opt) end
    end
    on_done(table.concat(list, ","))
  end)
  map("q", function()
    float.close()
  end)
  map("<Esc>", function()
    float.close()
  end)

  -- Start on first option row.
  vim.api.nvim_win_set_cursor(float.win, { math.min(4, #lines), 0 })
  vim.api.nvim_set_current_win(float.win)
end

---@param s string
---@return string
local function encode_edit_name_part(s)
  return (s:gsub("[^%w._-]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

---@param item table
---@return string
local function edit_buf_name(item)
  return GLOBALS.OPENAPI_EDIT_ID
    .. "/"
    .. encode_edit_name_part(item.operationKey)
    .. "/"
    .. encode_edit_name_part(item.paramName)
end

---@param name string
---@return integer|nil
local function buf_with_name(name)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == name then return buf end
  end
end

---@param buf integer
local function show_edit_buf(buf)
  local wins = vim.fn.win_findbuf(buf)
  if wins and wins[1] then
    vim.api.nvim_set_current_win(wins[1])
    return
  end
  vim.cmd("tab sbuffer " .. buf)
end

---@param item table
---@param current string
---@return string
local function edit_filetype(item, current)
  if item.paramName == "__body__" then
    local trimmed = vim.trim(current)
    if trimmed:sub(1, 1) == "<" then return "xml" end
    return "json"
  end
  return ""
end

---@param buf integer
---@param item table
---@param current string
local function fill_edit_buf(buf, item, current)
  local lines = vim.split(current, "\n", { plain = true })
  if #lines == 0 then lines = { "" } end
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modified", false, { buf = buf })
  local ft = edit_filetype(item, current)
  if ft ~= "" then vim.api.nvim_set_option_value("filetype", ft, { buf = buf }) end
end

---@param buf integer
---@param item table
local function setup_edit_buf(buf, item)
  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
  vim.api.nvim_set_option_value("buflisted", true, { buf = buf })
  vim.b[buf].kulala_openapi_edit = {
    operation_key = item.operationKey,
    param_name = item.paramName,
  }

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    desc = "Kulala: apply OpenAPI Try it out value",
    callback = function()
      if not instance then return Logger.warn("OpenAPI explorer is not open") end
      local meta = vim.b[buf].kulala_openapi_edit
      if type(meta) ~= "table" or not meta.operation_key or not meta.param_name then return end
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local value = table.concat(lines, "\n")
      instance.try_values[meta.operation_key] = instance.try_values[meta.operation_key] or {}
      instance.try_values[meta.operation_key][meta.param_name] = value
      paint(instance)
      vim.api.nvim_set_option_value("modified", false, { buf = buf })
      Logger.info("Updated Try it out value")
    end,
  })
end

---@param item table
---@param current string
local function open_try_it_out_tab(item, current)
  local name = edit_buf_name(item)
  local existing = buf_with_name(name)
  if existing then
    if not vim.api.nvim_get_option_value("modified", { buf = existing }) then fill_edit_buf(existing, item, current) end
    show_edit_buf(existing)
    pcall(vim.api.nvim_set_option_value, "winbar", " OpenAPI · " .. (item.title or item.paramName), { win = 0 })
    return
  end

  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  pcall(vim.api.nvim_buf_set_name, buf, name)
  setup_edit_buf(buf, item)
  fill_edit_buf(buf, item, current)
  pcall(vim.api.nvim_set_option_value, "winbar", " OpenAPI · " .. (item.title or item.paramName), { win = 0 })
end

local function edit_try_it_out(state)
  local item = editable_item(state, item_under_cursor(state))
  if not item or not item.operationKey or not item.paramName then
    return Logger.warn("Select a Try it out field to edit")
  end

  state.try_values[item.operationKey] = state.try_values[item.operationKey] or {}
  local current = state.try_values[item.operationKey][item.paramName] or item.defaultValue or ""

  local prompt = item.paramName == "__body__" and "Request body (JSON): "
    or item.paramName == "__accept__" and "Accept (media type): "
    or (item.title .. ": ")

  local options = option_list(item.options)
  if options then
    local multi = item.inputType == "multiSelect"
      or (type(item.badge) == "string" and item.badge:find("array", 1, true))
    if multi then
      edit_multi_select(options, current, prompt, function(value)
        state.try_values[item.operationKey][item.paramName] = value
        paint(state)
      end)
      return
    end

    vim.ui.select(options, {
      prompt = prompt,
      format_item = function(choice)
        return choice
      end,
    }, function(choice)
      if not choice then return end
      state.try_values[item.operationKey][item.paramName] = choice
      paint(state)
    end)
    return
  end

  open_try_it_out_tab(item, current)
end

---@param bufnr integer
---@return string
local function buffer_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return vim.fn.getcwd() end
  return vim.fn.fnamemodify(name, ":p:h")
end

local function load_from_file(state)
  local item = editable_item(state, item_under_cursor(state))
  if not item or not item.operationKey or not item.paramName then
    return Logger.warn("Select a Try it out field to load a file")
  end

  local options = option_list(item.options)
  if options then return Logger.warn("Use e to pick an enum value") end

  PickFile.pick_file({
    prompt = "Load Try it out from file",
    cwd = buffer_dir(state.http_bufnr),
  }, function(path)
    if not path then return end
    local content = require("kulala.utils.fs").read_file(path)
    if not content then return Logger.error("Failed to read file: " .. path) end
    state.try_values[item.operationKey] = state.try_values[item.operationKey] or {}
    state.try_values[item.operationKey][item.paramName] = content
    paint(state)
  end)
end

---@param state kulala.openapi_panel.state
---@return string|nil
local function operation_key_under_cursor(state)
  local item = item_under_cursor(state)
  if item and type(item.operationKey) == "string" and item.operationKey ~= "" then return item.operationKey end
  if item and item.parentId then
    for _, node in ipairs(state.line_map) do
      if node.id == item.parentId and type(node.operationKey) == "string" and node.operationKey ~= "" then
        return node.operationKey
      end
    end
  end
  return nil
end

local function yank_operation(state)
  local operation_key = operation_key_under_cursor(state)
  if not operation_key then return Logger.warn("Select an operation (or Try it out field) to yank as HTTP") end

  KULALA_CORE.guard(function()
    local overrides = overrides_for_operation(state, operation_key)
    local content, err = KULALA_CORE.openapi_to_http(state.http_bufnr, operation_key, state.parent_line, 1, overrides)
    if not content then return Logger.error(err or "Failed to convert OpenAPI operation to HTTP") end

    vim.fn.setreg("+", content)
    vim.fn.setreg('"', content)
    Logger.info("Copied HTTP request")
  end)
end

local function apply_keymaps(state)
  KEYMAPS.setup_openapi_panel_keymaps(state.bufnr)
end

function M.toggle_fold()
  if instance then toggle_fold(instance) end
end

function M.run()
  if not instance then return end
  local operation_key = operation_key_under_cursor(instance)
  if not operation_key then return Logger.warn("Select an operation (or Try it out field) and press Enter to run") end
  run_operation(instance, operation_key)
end

function M.edit()
  if instance then edit_try_it_out(instance) end
end

function M.load_from_file()
  if instance then load_from_file(instance) end
end

function M.yank()
  if instance then yank_operation(instance) end
end

function M.refresh()
  if instance then refresh(instance) end
end

local function ensure_explorer_buffer()
  local bufnr = get_explorer_buffer()
  if bufnr then return bufnr end

  bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, GLOBALS.OPENAPI_EXPLORER_ID)
  vim.api.nvim_set_option_value("filetype", "kulala_openapi", { buf = bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
  return bufnr
end

---@param openapi table
---@param parent_request DocumentRequest|nil
---@param http_bufnr integer|nil
function M.open(openapi, parent_request, http_bufnr)
  Highlight.setup()
  http_bufnr = http_bufnr or DB.get_current_buffer() or vim.api.nvim_get_current_buf()
  local tree = openapi.tree or {}
  if #tree == 0 then return Logger.error("OpenAPI explorer tree is empty") end

  local bufnr = ensure_explorer_buffer()

  if not instance or instance.bufnr ~= bufnr then
    instance = {
      bufnr = bufnr,
      winnr = nil,
      http_bufnr = http_bufnr,
      parent_line = parent_request and parent_request.start_line or vim.api.nvim_win_get_cursor(0)[1],
      parent_request = parent_request,
      openapi = openapi,
      folds = default_folds(tree),
      line_map = {},
      tree = tree,
      try_values = seed_try_values(tree),
    }
    apply_keymaps(instance)
  else
    instance.openapi = openapi
    instance.tree = tree
    instance.parent_request = parent_request
    instance.http_bufnr = http_bufnr
    instance.parent_line = parent_request and parent_request.start_line or instance.parent_line
    instance.folds = merge_folds(instance.folds, tree)
    instance.try_values = merge_try_values(instance.try_values, tree)
  end

  instance.winnr = open_explorer_window(bufnr, http_bufnr)
  if instance.winnr and vim.api.nvim_win_is_valid(instance.winnr) then vim.api.nvim_set_current_win(instance.winnr) end
  paint(instance)
end

---@return integer|nil Explorer window, when the OpenAPI panel is open.
function M.get_window()
  return get_explorer_window()
end

function M.close()
  local win = instance and instance.winnr or get_explorer_window()
  if win and vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
  if instance then instance.winnr = nil end
end

return M
