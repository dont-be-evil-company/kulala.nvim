local M = {}

M.default_global_keymaps = {
  ["Open scratchpad"] = {
    "b",
    function()
      require("kulala").scratchpad()
    end,
  },
  ["Open kulala"] = {
    "o",
    function()
      require("kulala").open()
    end,
  },
  ["Close window"] = {
    "q",
    function()
      require("kulala").close()
    end,
    ft = { "http", "rest" },
  },
  ["Copy as cURL"] = {
    "c",
    function()
      require("kulala").copy()
    end,
    ft = { "http", "rest" },
  },
  ["Paste from curl"] = {
    "C",
    function()
      require("kulala").from_curl()
    end,
    ft = { "http", "rest" },
  },
  ["Inspect current request"] = {
    "i",
    function()
      require("kulala").inspect()
    end,
    ft = { "http", "rest" },
  },
  ["Open cookies jar"] = {
    "j",
    function()
      require("kulala").open_cookies_jar()
    end,
    ft = { "http", "rest" },
  },
  ["Select environment"] = {
    "e",
    function()
      require("kulala").set_selected_env()
    end,
    ft = { "http", "rest" },
  },
  ["Manage Auth Config"] = {
    "u",
    function()
      require("kulala.ui.auth_manager").open_auth_config()
    end,
    ft = { "http", "rest" },
  },
  ["Send request"] = {
    "s",
    function()
      require("kulala").run()
    end,
    mode = { "n", "v" },
  },
  ["Send request <cr>"] = {
    "<CR>",
    function()
      require("kulala").run()
    end,
    mode = { "n", "v" },
    ft = { "http", "rest" },
    prefix = false,
  },
  ["Send all requests"] = {
    "a",
    function()
      require("kulala").run_all()
    end,
    mode = { "n", "v" },
  },
  ["Replay the last request"] = {
    "r",
    function()
      require("kulala").replay()
    end,
  },
  ["Download GraphQL schema"] = {
    "g",
    function()
      require("kulala").download_graphql_schema()
    end,
    ft = { "http", "rest" },
  },
  ["Jump to next request"] = {
    "n",
    function()
      require("kulala").jump_next()
    end,
    ft = { "http", "rest" },
  },
  ["Jump to previous request"] = {
    "p",
    function()
      require("kulala").jump_prev()
    end,
    ft = { "http", "rest" },
  },
  ["Find request"] = {
    "f",
    function()
      require("kulala").search()
    end,
    ft = { "http", "rest" },
  },
  ["Search responses"] = {
    "H",
    function()
      require("kulala").search_responses()
    end,
    ft = { "http", "rest" },
  },
  ["Toggle headers/body"] = {
    "t",
    function()
      require("kulala").toggle_view()
    end,
    ft = { "http", "rest" },
  },
  ["Show stats"] = {
    "S",
    function()
      require("kulala").show_stats()
    end,
    ft = { "http", "rest" },
  },
  ["Clear globals"] = {
    "x",
    function()
      require("kulala").scripts_clear_global()
    end,
    ft = { "http", "rest" },
  },
  ["Clear cached files"] = {
    "X",
    function()
      require("kulala").clear_cached_files()
    end,
    ft = { "http", "rest" },
  },
}

-- Keymaps for Kulala window only
M.default_kulala_keymaps = {
  ["Previous tab"] = {
    "<c-h>",
    function()
      require("kulala.ui").show_previous_tab()
    end,
    mode = { "n" },
  },
  ["Next tab"] = {
    "<c-l>",
    function()
      require("kulala.ui").show_next_tab()
    end,
    mode = { "n" },
  },
  ["Show headers"] = {
    "H",
    function()
      require("kulala.ui").show_headers()
    end,
  },
  ["Search responses"] = {
    "s",
    function()
      require("kulala").search_responses()
    end,
  },
  ["Show body"] = {
    "B",
    function()
      require("kulala.ui").show_body()
    end,
  },
  ["Show headers and body"] = {
    "A",
    function()
      require("kulala.ui").show_headers_body()
    end,
  },
  ["Show verbose"] = {
    "V",
    function()
      require("kulala.ui").show_verbose()
    end,
  },
  ["Show script output"] = {
    "O",
    function()
      require("kulala.ui").show_script_output()
    end,
  },
  ["Show stats"] = {
    "S",
    function()
      require("kulala.ui").show_stats()
    end,
  },
  ["Show report"] = {
    "R",
    function()
      require("kulala.ui").show_report()
    end,
  },
  ["Show filter"] = {
    "F",
    function()
      require("kulala.ui").toggle_filter()
    end,
  },
  ["Next response"] = {
    "]",
    function()
      require("kulala.ui").show_next()
    end,
    prefix = false,
  },
  ["Previous response"] = {
    "[",
    function()
      require("kulala.ui").show_previous()
    end,
    prefix = false,
  },
  ["Jump to response"] = {
    "<CR>",
    function()
      require("kulala.ui").keymap_enter()
    end,
    mode = { "n", "v" },
    desc = "Jump to request",
    prefix = false,
  },
  ["Clear responses history"] = {
    "X",
    function()
      require("kulala.ui").clear_responses_history()
    end,
  },
  ["Send WS message"] = {
    "<S-CR>",
    function()
      require("kulala.ui.ws_input").on_send_keymap()
    end,
    mode = { "n", "v", "i" },
    desc = "Open WS message input (body view) / send from input overlay",
    prefix = false,
  },
  ["Interrupt requests"] = {
    "<C-c>",
    function()
      require("kulala.ui").interrupt_requests()
    end,
    desc = "also: CLose WS connection",
    prefix = false,
  },
  ["Show help"] = {
    "?",
    function()
      require("kulala.ui").show_help()
    end,
    prefix = false,
  },
  ["Show news"] = {
    "g?",
    function()
      require("kulala.ui").show_news()
    end,
    prefix = false,
  },
  ["Toggle split/float"] = {
    "|",
    function()
      require("kulala.ui").toggle_display_mode()
    end,
    prefix = false,
  },
  ["Close"] = {
    "q",
    function()
      require("kulala.ui").close_kulala_buffer()
    end,
    prefix = false,
  },
}

M.default_openapi_panel_keymaps = {
  ["Toggle fold"] = {
    "<Tab>",
    function()
      require("kulala.ui.openapi_panel").toggle_fold()
    end,
  },
  ["Toggle fold (za)"] = {
    "za",
    function()
      require("kulala.ui.openapi_panel").toggle_fold()
    end,
    prefix = false,
  },
  ["Run"] = {
    "<CR>",
    function()
      require("kulala.ui.openapi_panel").run()
    end,
    prefix = false,
  },
  ["Edit try it out"] = {
    "e",
    function()
      require("kulala.ui.openapi_panel").edit()
    end,
  },
  ["Load from file"] = {
    "f",
    function()
      require("kulala.ui.openapi_panel").load_from_file()
    end,
  },
  ["Yank as HTTP"] = {
    "Y",
    function()
      require("kulala.ui.openapi_panel").yank()
    end,
    prefix = false,
  },
  ["Refresh"] = {
    "R",
    function()
      require("kulala.ui.openapi_panel").refresh()
    end,
  },
  ["Close"] = {
    "q",
    function()
      require("kulala.ui.openapi_panel").close()
    end,
  },
}

M.default_graphql_panel_keymaps = {
  ["Toggle fold"] = {
    "<Tab>",
    function()
      require("kulala.ui.graphql_explorer").toggle_fold()
    end,
  },
  ["Toggle fold (za)"] = {
    "za",
    function()
      require("kulala.ui.graphql_explorer").toggle_fold()
    end,
    prefix = false,
  },
  ["Toggle field"] = {
    "<Space>",
    function()
      require("kulala.ui.graphql_explorer").toggle()
    end,
  },
  ["Run"] = {
    "<CR>",
    function()
      require("kulala.ui.graphql_explorer").run()
    end,
    prefix = false,
  },
  ["Edit argument"] = {
    "e",
    function()
      require("kulala.ui.graphql_explorer").edit()
    end,
  },
  ["Search"] = {
    "/",
    function()
      require("kulala.ui.graphql_explorer").search()
    end,
  },
  ["Yank as HTTP"] = {
    "Y",
    function()
      require("kulala.ui.graphql_explorer").yank()
    end,
    prefix = false,
  },
  ["Refresh"] = {
    "R",
    function()
      require("kulala.ui.graphql_explorer").refresh()
    end,
  },
  ["Close"] = {
    "q",
    function()
      require("kulala.ui.graphql_explorer").close()
    end,
  },
}

M.default_lsp_keymaps = {
  ["<leader>ls"] = { vim.lsp.buf.document_symbol, desc = "Search Symbols" },
  ["<leader>lv"] = {
    function()
      if not require("snacks") then return end
      require("snacks").picker.lsp_symbols { layout = { preset = "vscode", preview = "main" } }
    end,
    desc = "Search Symbols",
  }, -- requires snacks.nvim
  ["<leader>lt"] = { "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols outline" }, -- requires trouble.nvim
  ["<leader>lS"] = {
    function()
      require("aerial").toggle()
    end,
    desc = "Symbols outline",
  }, -- requires aerial.nvim (recommended)
  ["K"] = { vim.lsp.buf.hover, desc = "Hover" },
  ["<leader>la"] = { vim.lsp.buf.code_action, desc = "Code Action" },
  ["<leader>lf"] = { vim.lsp.buf.format, desc = "Buffer Format", mode = { "n", "v" } },
}

local function collect_global_keymaps()
  local config = require("kulala.config")
  local config_global_keymaps = config.options.global_keymaps
  local prefix = config.options.global_keymaps_prefix
  local global_keymaps, ft_keymaps = {}, {}

  if not config_global_keymaps then return global_keymaps, ft_keymaps end

  local default_keymaps = vim.deepcopy(M.default_global_keymaps)

  vim.iter(default_keymaps):each(function(name, map)
    map[1] = map.prefix == false and map[1] or prefix .. map[1]
    default_keymaps[name] = map
  end)

  config_global_keymaps = type(config_global_keymaps) == "table"
      and vim.tbl_extend("force", default_keymaps, config_global_keymaps)
    or default_keymaps

  vim.iter(config_global_keymaps):each(function(name, map)
    if not map then return end
    map.desc = map.desc or name

    if map.ft then
      vim.iter({ map.ft }):flatten():each(function(ft)
        ft_keymaps[ft] = vim.list_extend(ft_keymaps[ft] or {}, { map })
      end)
    else
      global_keymaps = vim.list_extend(global_keymaps, { map })
    end
  end)

  return global_keymaps, ft_keymaps
end

local function set_keymap(map, buf)
  vim.keymap.set(map.mode or "n", map[1], map[2], {
    buffer = buf,
    desc = map.desc,
    silent = true,
    nowait = true,
    noremap = true,
  })
end

local function create_ft_autocommand(ft, maps)
  vim.api.nvim_create_autocmd({ "BufEnter", "BufRead", "BufNewFile", "BufFilePost", "FileType" }, {
    group = vim.api.nvim_create_augroup("Kulala filetype setup for *." .. ft, { clear = true }),
    pattern = { "*." .. ft, ft },
    desc = "Kulala: setup keymaps for http filetypes",
    callback = function(ev)
      vim.iter(maps):each(function(map)
        set_keymap(map, ev.buf)
      end)
    end,
  })
end

M.get_kulala_keymaps = function()
  local config = require("kulala.config")
  local config_kulala_keymaps = config.options.kulala_keymaps

  if not config_kulala_keymaps then return end

  local default_keymaps = vim.deepcopy(M.default_kulala_keymaps)

  vim.iter(default_keymaps):each(function(name, map)
    map[1] = map.prefix == false and map[1] or config.options.kulala_keymaps_prefix .. map[1]
    default_keymaps[name] = map
  end)

  config_kulala_keymaps = type(config_kulala_keymaps) == "table"
      and vim.tbl_extend("force", default_keymaps, config_kulala_keymaps)
    or default_keymaps

  return config_kulala_keymaps
end

M.get_lsp_keymaps = function()
  local config = require("kulala.config")
  local config_lsp_keymaps = config.options.lsp.keymaps

  if not config_lsp_keymaps then return {} end

  local default_keymaps = vim.deepcopy(M.default_lsp_keymaps)

  config_lsp_keymaps = type(config_lsp_keymaps) == "table"
      and vim.tbl_extend("force", default_keymaps, config_lsp_keymaps)
    or default_keymaps

  config_lsp_keymaps = vim
    .iter(config_lsp_keymaps)
    :map(function(key, map)
      return { key, map[1], desc = map.desc }
    end)
    :totable()

  return config_lsp_keymaps
end

M.setup_kulala_keymaps = function(buf)
  local keymaps = M.get_kulala_keymaps() or {}

  vim.iter(keymaps):each(function(name, map)
    if map then
      map.desc = map.desc or name
      set_keymap(map, buf)
    end
  end)

  return keymaps
end

M.get_openapi_panel_keymaps = function()
  local config = require("kulala.config")
  local config_keymaps = config.options.openapi_panel_keymaps

  if config_keymaps == nil then return end
  if config_keymaps == false then return end

  local default_keymaps = vim.deepcopy(M.default_openapi_panel_keymaps)

  config_keymaps = type(config_keymaps) == "table" and vim.tbl_extend("force", default_keymaps, config_keymaps)
    or default_keymaps

  return config_keymaps
end

M.get_graphql_panel_keymaps = function()
  local config = require("kulala.config")
  local config_keymaps = config.options.graphql_panel_keymaps

  if config_keymaps == nil then return end
  if config_keymaps == false then return end

  local default_keymaps = vim.deepcopy(M.default_graphql_panel_keymaps)

  config_keymaps = type(config_keymaps) == "table" and vim.tbl_extend("force", default_keymaps, config_keymaps)
    or default_keymaps

  return config_keymaps
end

local function is_send_request_map(map)
  return type(map) == "table"
    and type(map[1]) == "string"
    and (map.desc == "Send request" or map.desc == "Send request <cr>")
end

---HTTP send-request keys, so the explorer accepts the same mapping as an .http buffer.
local function http_send_request_maps()
  local config = require("kulala.config")
  local maps = {}
  local function add(list)
    if type(list) ~= "table" then return end
    for _, map in ipairs(list) do
      if is_send_request_map(map) then maps[#maps + 1] = map end
    end
  end
  add(config.options.global_keymaps)
  local ft = config.options.ft_keymaps
  if type(ft) == "table" then add(ft.http) end
  return maps
end

M.setup_graphql_panel_keymaps = function(buf)
  local keymaps = M.get_graphql_panel_keymaps() or {}

  vim.iter(keymaps):each(function(name, map)
    if map then
      map.desc = map.desc or name
      set_keymap(map, buf)
    end
  end)

  vim.iter(http_send_request_maps()):each(function(map)
    set_keymap(map, buf)
  end)

  return keymaps
end

M.setup_openapi_panel_keymaps = function(buf)
  local keymaps = M.get_openapi_panel_keymaps() or {}

  vim.iter(keymaps):each(function(name, map)
    if map then
      map.desc = map.desc or name
      set_keymap(map, buf)
    end
  end)

  return keymaps
end

M.setup_global_keymaps = function()
  local global_keymaps, ft_keymaps = collect_global_keymaps()

  ft_keymaps.http = vim.list_extend(ft_keymaps.http or {}, M.get_lsp_keymaps())

  vim.iter(global_keymaps or {}):each(function(map)
    set_keymap(map)
  end)

  vim.iter(ft_keymaps or {}):each(function(ft, maps)
    create_ft_autocommand(ft, maps)
  end)
  return global_keymaps, ft_keymaps
end

return M
