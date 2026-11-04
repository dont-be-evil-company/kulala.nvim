local Bridge = require("kulala.cmd.kulala_core_bridge")
local Config = require("kulala.config")
local Diagnostics = require("kulala.cmd.diagnostics")
local Export = require("kulala.cmd.export")
local Fs = require("kulala.utils.fs")
local Globals = require("kulala.globals")
local Kulala = require("kulala")
local Logger = require("kulala.logger")
local Ui = require("kulala.ui")

local M = {}
M.name = "kulala-core-lsp"

local trigger_chars = { "@", "#", "-", ":", "{", "$", ">", "<", ".", "(", '"', "'" }

local state = {
  current_buffer = 0,
  current_line = 0, -- 1-based line number
  current_ft = nil,
}

local function code_actions_http()
  return {
    { group = "cURL", title = "Copy as cURL", command = "copy_as_curl", fn = Kulala.copy },
    {
      group = "cURL",
      title = "Paste from curl",
      command = "paste_from_curl",
      fn = Kulala.from_curl,
    },
    { group = "Request", title = "Inspect current request", command = "inspect_current_request", fn = Kulala.inspect },
    { group = "Request", title = "Open Cookies Jar", command = "open_cookie_jar", fn = Kulala.open_cookies_jar },
    {
      group = "Environment",
      title = "Select environment",
      command = "select_environment",
      fn = function()
        Kulala.set_selected_env()
      end,
    },
    {
      group = "Authentication",
      title = "Manage Auth Config",
      command = "manage_auth_config",
      fn = require("kulala.ui.auth_manager").open_auth_config,
    },
    { group = "Request", title = "Replay last request", command = "replay_last request", fn = Kulala.replay },
    {
      group = "GraphQL",
      title = "Download GraphQL schema",
      command = "download_graphql_schema",
      fn = Kulala.download_graphql_schema,
    },
    {
      group = "GraphQL",
      title = "Clear GraphQL schema cache",
      command = "clear_graphql_schema_cache",
      fn = function()
        Kulala.clear_graphql_schema_cache()
      end,
    },
    {
      group = "GraphQL",
      title = "Open GraphQL explorer",
      command = "open_graphql_explorer",
      fn = Kulala.open_graphql_explorer,
    },
    {
      group = "OpenAPI",
      title = "Open OpenAPI explorer",
      command = "open_openapi_explorer",
      fn = Kulala.open_openapi_explorer,
    },
    {
      group = "OpenAPI",
      title = "Clear OpenAPI schema cache",
      command = "clear_openapi_schema_cache",
      fn = function()
        Kulala.clear_openapi_schema_cache()
      end,
    },
    {
      group = "Environment",
      title = "Clear globals",
      command = "clear_globals",
      fn = function()
        Kulala.scripts_clear_global()
      end,
    },
    {
      group = "Environment",
      title = "Clear cached files",
      command = "clear_cached_files",
      fn = Kulala.clear_cached_files,
    },
    { group = "Request", title = "Send request", command = "run_request", fn = Ui.open },
    {
      group = "Request",
      title = "Send all requests",
      command = "run_request_all",
      fn = function()
        Ui.open_all()
      end,
    },
    {
      group = "Request",
      title = "Export file",
      command = "export_file",
      fn = Export.export_requests,
    },
    {
      group = "Request",
      title = "Export folder",
      command = "export_folder",
      fn = Export.export_requests,
    },
  }
end

local function code_actions()
  if state.current_ft == "http" or state.current_ft == "rest" then return code_actions_http() end
  return {}
end

local function get_symbols()
  -- handled asynchronously in srv.request
  return {}
end

local function get_hover(_)
  -- handled asynchronously in srv.request
  return { contents = { language = "plaintext", value = "" } }
end

M.foldtext = function()
  vim.api.nvim_set_option_value(
    "foldtext",
    "v:lua.require'kulala.cmd.lsp'.foldtext()",
    { win = vim.api.nvim_get_current_win() }
  )

  local line = vim.fn.getline(vim.v.foldstart)
  return "▶ " .. line .. " [" .. (vim.v.foldend - vim.v.foldstart + 1) .. " lines]"
end

local function folding()
  if not vim.api.nvim_buf_is_loaded(state.current_buffer) then return {} end

  local status, parser = pcall(vim.treesitter.get_parser, state.current_buffer, "kulala_http")
  if not (status and parser) then return {} end

  local tree = parser:parse()[1]
  local root = tree:root()

  local ranges = {}

  local function traverse(node)
    for child in node:iter_children() do
      local start_row, _, end_row, _ = child:range()

      local type = child:type()
      local kind = type == "comment" and type or "region"

      if type == "request_separator" then
        start_row = start_row + 1
        end_row = select(3, child:parent():range())
      end

      if end_row > start_row and child:type() ~= "section" then
        table.insert(ranges, {
          startLine = start_row,
          endLine = end_row - 1,
          kind = kind,
          type = child:type(),
        })
      end

      traverse(child)
    end
  end

  traverse(root)

  return ranges
end

local function initialize(attached_buf)
  return function(params)
    local ft = params.rootPath:sub(2)
    local capabilities

    if Fs.is_http_script_file(ft, attached_buf) then
      capabilities = {
        inlayHintProvider = true,
        completionProvider = { triggerCharacters = trigger_chars },
        hoverProvider = true,
      }
    elseif ft == "http" or ft == "rest" then
      capabilities = {
        inlayHintProvider = true,
        codeActionProvider = true,
        documentSymbolProvider = true,
        hoverProvider = true,
        completionProvider = { triggerCharacters = trigger_chars },
        foldingRangeProvider = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      }
    else
      capabilities = {}
    end

    return {
      serverInfo = { name = M.name, version = Globals.BACKEND_VERSION },
      capabilities = capabilities,
    }
  end
end

local function handlers_for(attached_buf)
  return {
    ["initialize"] = initialize(attached_buf),
    ["textDocument/completion"] = function()
      -- handled asynchronously in srv.request
      return { isIncomplete = false, items = {} }
    end,
    ["textDocument/documentSymbol"] = get_symbols,
    ["textDocument/hover"] = get_hover,
    ["textDocument/codeAction"] = code_actions,
    ["textDocument/foldingRange"] = folding,
    ["shutdown"] = function() end,
  }
end

local function set_current_buf(params)
  if not (params and params.textDocument and params.textDocument.uri) then return end

  local buf = vim.uri_to_bufnr(params.textDocument.uri)
  local buf_valid = vim.api.nvim_buf_is_valid(buf)

  state.current_buffer = buf_valid and buf or 0
  state.current_ft = buf_valid and vim.api.nvim_get_option_value("filetype", { buf = buf }) or nil

  local win = buf_valid and vim.fn.win_findbuf(buf)[1] or 0
  state.current_line = vim.api.nvim_win_get_cursor(win)[1]
end

local function new_server(attached_buf)
  local handlers = handlers_for(attached_buf)

  local function server(dispatchers)
    local closing = false
    local request_seq = 0
    local srv = {}

    function srv.request(method, params, handler, notify_reply_callback)
      request_seq = request_seq + 1
      local request_id = request_seq

      -- documentSymbol/hover/completion reply asynchronously (via kulala-core), after this
      -- function returns. Request-tracking consumers (e.g. snacks/aerial symbol pickers)
      -- need a request_id to correlate that late reply with the pending request, so
      -- allocate one and signal completion through notify_reply_callback.
      local responded = false
      local orig_handler = handler
      handler = function(err, result)
        if responded then return end -- the error path below may also respond
        responded = true
        orig_handler(err, result)
        if notify_reply_callback then notify_reply_callback(request_id) end
      end

      local status, error = xpcall(function()
        set_current_buf(params)
        if method == "textDocument/completion" then
          local buf = vim.uri_to_bufnr(params.textDocument.uri)
          Bridge.lsp_completion_async(buf, params, function(res, err)
            if not res then
              Logger.debug("kulala-core lsp_completion failed: " .. tostring(err))
              res = { isIncomplete = false, items = {} }
            elseif type(res.items) == "table" and params.position then
              Bridge.apply_completion_text_edits(res.items, buf, params.position)
            end
            handler(nil, res)
          end)
          return
        end

        if method == "textDocument/hover" then
          Bridge.lsp_hover_async(state.current_buffer, function(res, err)
            if not res then
              Logger.debug("kulala-core lsp_hover failed: " .. tostring(err))
              res = { contents = { language = "plaintext", value = tostring(err or "kulala-core hover failed") } }
            end
            handler(nil, res)
          end)
          return
        end

        if method == "textDocument/documentSymbol" then
          Bridge.lsp_symbols_async(state.current_buffer, function(res, err)
            if not res then
              Logger.debug("kulala-core lsp_symbols failed: " .. tostring(err))
              res = {}
            end
            handler(nil, res)
          end)
          return
        end

        if method == "textDocument/inlayHint" then
          Bridge.lsp_inlay_hints_async(state.current_buffer, params, function(res, err)
            if not res then
              Logger.debug("kulala-core lsp_inlay_hints failed: " .. tostring(err))
              res = {}
            end
            handler(nil, res)
          end)
          return
        end

        if handlers[method] then handler(nil, handlers[method](params)) end
      end, debug.traceback)

      if not status then
        require("kulala.logger").error("Errors in Kulala LSP:\n" .. (error or ""), 2, { report = true })
        handler(error, nil) -- complete the request so the consumer isn't left waiting
      end

      return true, request_id
    end

    function srv.notify(method, _)
      if method == "exit" then dispatchers.on_exit(0, 15) end
    end

    function srv.is_closing()
      return closing
    end

    function srv.terminate()
      closing = true
    end

    return srv
  end

  return server
end

M.start = function(buf, ft)
  M.start_lsp(buf, ft)
end

M.restart_all = function()
  local clients = vim.lsp.get_clients { name = M.name }
  for _, client in ipairs(clients) do
    client:stop()
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
      if Config.options.lsp.filetypes and vim.tbl_contains(Config.options.lsp.filetypes, ft) then
        M.start_lsp(buf, ft)
      end
    end
  end
end

function M.start_lsp(buf, ft)
  local server = new_server(buf)

  local dispatchers = {
    on_exit = function(code, signal)
      Logger.error("Server exited with code " .. code .. " and signal " .. signal)
    end,
  }

  local actions = code_actions_http()

  local client_id = vim.lsp.start({
    name = M.name,
    cmd = server,
    root_dir = ft,
    bufnr = buf,
    on_attach = function(client, bufnr)
      if ft == "http" or ft == "rest" then Diagnostics.setup(bufnr) end
      if Config.options.lsp.on_attach then Config.options.lsp.on_attach(client, bufnr) end
    end,
    commands = vim.iter(actions):fold({}, function(acc, action)
      acc[action.command] = action.fn
      return acc
    end),
  }, dispatchers)

  return client_id
end

return M
