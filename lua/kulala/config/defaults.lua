require("kulala.types")

---@type KulalaDefaultConfig
local M = {
  kulala_core = {
    -- Optional path to the kulala-core executable
    -- (https://github.com/dont-be-evil-company/kulala-core).
    -- When set, this path is used exclusively.
    -- When nil (default), auto-download and
    -- use kulala-core from GitHub releases based on the user's OS and architecture.
    path = nil,
    -- Subprocess timeout (ms) for kulala-core.
    -- Default is 60000 (1 minute).
    -- 0 disables the vim.system timeout.
    timeout = 60000,
    -- Optional override for kulala-core persistence
    -- (cookies, OAuth, prompts).
    -- Default matches kulala-core CLI:
    -- - Linux: ~/.local/share/kulala-core
    --   or $XDG_DATA_HOME/kulala-core
    -- - macOS: ~/Library/Application
    --   or Support/kulala-core
    -- - Windows: %APPDATA%\kulala-core
    data_dir = nil,
    -- Optional override for download url
    download_url = "https://github.com/dont-be-evil-company/kulala-core/releases/download/%s/%s",
    download_tool = "curl", -- or "wget"
  },
  -- Restore request history and UI after sourcing a vim session (:h 'sessionoptions' globals).
  session = {
    restore = true,
  },

  treesitter = {
    -- enable/disable kulala.nvim own
    -- handling of tree-sitter parser and queries for HTTP scripts
    -- like downloading, building, and installing the parser and queries.
    enable = true,
    -- path to tree-sitter CLI, if not in PATH
    -- if enable is false, this is not used
    cli_path = "tree-sitter",
  },

  -- dev, test, prod, can be anything
  -- see: https://learn.microsoft.com/en-us/aspnet/core/test/http-files?view=aspnetcore-8.0#environment-files
  default_env = "default",
  -- `"b"` = per-buffer env (default), `"g"` = global
  environment_scope = "b",
  -- enable reading vscode rest client environment variables
  vscode_rest_client_environmentvars = false,

  -- Response body pretty-printing is handled by kulala-core (see `response_format`).
  response_format = {
    indent = 2,
    expand_tabs = true,
    sort_keys = false,
  },

  ui = {
    -- display mode: possible values: "split", "float"
    display_mode = "split",
    -- split direction: possible values: "above", "right", "below", "left", fun(): "above"|"right"|"below"|"left"
    split_direction = "right",
    -- window options to override win_config: width/height/split/vertical.., buffer/window options
    win_opts = { bo = {}, wo = {} }, ---@type kulala.ui.win_config
    -- default view: "body" or "headers" or "headers_body" or "verbose" or fun(response: Response)
    default_view = "body", ---@type "body"|"headers"|"headers_body"|"verbose"|fun(response: Response)
    -- enable winbar
    winbar = true,
    -- Specify the panes to be displayed by default
    -- Available panes are { "body", "headers", "headers_body", "script_output", "stats", "verbose", "report", "help" },
    default_winbar_panes = { "body", "headers", "verbose", "script_output", "report" },
    -- Winbar labels
    winbar_labels = {
      body = "Body",
      headers = "Headers",
      headers_body = "All",
      verbose = "Verbose",
      script_output = "Script Output",
      stats = "Stats",
      report = "Report",
      help = "Help",
    },
    -- show/hide winbar keymaps in labels
    winbar_labels_keymaps = true,
    -- enable/disable variable info text
    -- this will show the variable name and value as float
    -- possible values: false, "float"
    show_variable_info_text = false,
    -- icons position: "signcolumn"|"on_request"|"above_request"|"below_request" or nil to disable
    show_icons = "on_request",
    -- default icons
    icons = {
      inlay = {
        loading = "⏳",
        done = "✔",
        error = "✘",
      },
      lualine = "🐼",
      textHighlight = "WarningMsg", -- highlight group for request elapsed time
      loadingHighlight = "Normal",
      doneHighlight = "String",
      errorHighlight = "ErrorMsg",
    },

    -- highlight groups for http syntax highlighting
    ---@type table<string, string|vim.api.keyset.highlight>
    syntax_hl = {
      ["@punctuation.bracket.kulala_http"] = "Number",
      ["@character.special.kulala_http"] = "Special",
      ["@operator.kulala_http"] = "Special",
      ["@variable.kulala_http"] = "String",
      ["@redirect_path.kulala_http"] = "Number",
      ["@external_body_path.kulala_http"] = "String",
      ["@query_param.name.kulala_http"] = "Number",
      ["@query_param.value.kulala_http"] = "String",
      ["@form_param_name.kulala_http"] = "Number",
      ["@form_param_value.kulala_http"] = "String",
    },

    -- enable/disable request summary in the output window
    show_request_summary = true,

    -- do not show responses over maximum size, in bytes
    max_response_size = 32768,

    -- used by `Copy as Curl` command to determine whether to inline request body
    max_request_size = 2048,

    -- Display image response bodies inline via Kitty graphics / iTerm2 protocols
    show_images = true,

    report = {
      -- possible values: true | false | "on_error"
      show_script_output = true,
      -- possible values: true | false | "on_error" | "failed_only"
      show_asserts_output = true,
      -- possible values: true | false | "on_error"
      show_summary = true,

      headersHighlight = "Special",
      successHighlight = "String",
      errorHighlight = "Error",
    },

    -- scratchpad default contents
    scratchpad_default_contents = {
      "@MY_TOKEN_NAME=my_token_value",
      "",
      "# @name scratchpad",
      "POST https://echo.kulala.app/post HTTP/1.1",
      "accept: application/json",
      "content-type: application/json",
      "",
      "{",
      '  "foo": "bar"',
      "}",
    },

    -- Settings for pickers used for Environment, Authentication and Requests Managers
    pickers = {
      snacks = {
        layout = function()
          local has_snacks, snacks_picker = pcall(require, "snacks.picker")
          return not has_snacks and {}
            or vim.tbl_deep_extend("force", snacks_picker.config.layout("telescope"), {
              reverse = true,
              layout = {
                { { win = "list" }, { height = 1, win = "input" }, box = "vertical" },
                { win = "preview", width = 0.6 },
                box = "horizontal",
                width = 0.8,
              },
            })
        end,
      },
    },
  },

  lsp = {
    ---enable/disable built-in LSP server
    ---@type boolean
    enable = true,

    ---filetypes to attach Kulala LSP to
    ---@type string[]
    filetypes = {
      "http",
      "rest",
      "javascript",
      "typescript",
      "lua",
    },

    ---Only scripts ending in *.http.js, *.http.ts and *.http.lua will be treated as HTTP scripts and
    ---have LSP capabilities, unless `enforce_external_script_naming_convention` is set to false.
    ---This allows users to have non-HTTP scripts with the same filetypes without LSP interference.
    ---@type boolean
    enforce_external_script_naming_convention = true,

    --enable/disable/customize  LSP keymaps
    ---@type boolean|table
    keymaps = false, -- disabled by default, as Kulala relies on default Neovim LSP keymaps

    on_attach = nil, -- function called when Kulala LSP attaches to the buffer
  },

  -- enable/disable debug mode
  debug = 3,
  -- enable/disable bug reports on all errors
  generate_bug_report = false,

  -- set to true to enable default keymaps
  -- (see docs or lua/kulala/config/keymaps.lua)
  -- or override default keymaps as shown in the example below.
  ---@type boolean|table
  global_keymaps = false,
  --[[
    {
      ["Send request"] = { -- sets global mapping
        "<leader>Rs",
        function() require("kulala").run() end,
        mode = { "n", "v" }, -- optional mode, default is n
        desc = "Send request" -- optional description, otherwise inferred from the key
      },
      ["Send all requests"] = {
        "<leader>Ra",
        function() require("kulala").run_all() end,
        mode = { "n", "v" },
        ft = "http", -- sets mapping for *.http files only
      },
      ["Replay the last request"] = {
        "<leader>Rr",
        function() require("kulala").replay() end,
        ft = { "http", "rest" }, -- sets mapping for specified file types
      },
    ["Find request"] = false -- set to false to disable
    },
  ]]

  -- Prefix for global keymaps
  global_keymaps_prefix = "<leader>R",

  -- Kulala UI keymaps; override with custom keymaps as required
  -- (see docs or lua/kulala/config/keymaps.lua)
  ---@type boolean|table
  kulala_keymaps = true,
  --[[
    {
      ["Show headers"] = { "H", function() require("kulala.ui").show_headers() end, },
    }
  ]]

  kulala_keymaps_prefix = "",

  -- OpenAPI explorer panel keymaps; override with custom keymaps as required
  -- (see docs or lua/kulala/config/keymaps.lua)
  ---@type boolean|table
  openapi_panel_keymaps = true,
  --[[
    {
      ["Run"] = { "<CR>", function() require("kulala.ui.openapi_panel").run() end, },
    }
  ]]

  -- Forward script console output (`console.*`, `client.log`) to vim.notify.
  -- Set to false to disable. Use a table to customize title or handler.
  ---@type boolean|KulalaScriptConsoleNotifyConfig
  script_console_notify = true,
  --[[
    {
      enabled = true,
      title = "kulala",
      notify = function(message, level, opts, entry)
        vim.notify(message, level, opts)
      end,
    }
  ]]

  openapi_panel = {
    --- Split placement for the explorer buffer (same values as `split_direction`).
    split = "right",
    signs = { folded = ">", expanded = "v" },
    highlights = {
      section = "Title",
      operation = "Function",
      parameter = "Identifier",
      response = "Number",
      schema = "Type",
      try_it_out = "String",
      description = "Comment",
      badge = "Comment",
      sign = "Special",
      value = "Constant",
    },
  },
}

return M
