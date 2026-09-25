<div align="center">

![Kulala Logo](logo.svg)

# kulala.nvim

[![Made with love][badge-made-with-love]][contributors]
[![Discord][badge-discord]][discord]
[![Development status][badge-development-status]][development-status]
[![Our manifesto][badge-our-manifesto]][our-manifesto]
[![Status of tests][badge-test-status]][link-test-status]
[![AI Policty][badge-ai-policy]][ai-policy]

[Install](#install) •
[Usage](https://kulala.app/usage) •
[HTTP File Spec](https://kulala.app/usage/http-file-format)

<p></p>

A fully-featured ⚡️ HTTP/GraphQL/gRPC/Websocket-client 🐼
interface 🖥️ for Neovim ❤️,
that supports the Jetbrains .http spec (with full scripting support).

Kulala is swahili for "rest" or "relax."

It allows you to make HTTP requests from within Neovim.

<p></p>

![demo][demo-image]

# Other tools 🔧 from the Kulala 🐼 family 🌈

[Kulala CLI][kulala-cli] •
[Kulala Formatter (and converter)][kulala-fmt] •
[Kulala Desktop][kulala-desktop] •
[Kulala for Visual Studio Code][kulala.vscode] •
[Kulala Core][kulala-core]
[Kulala Github Action][kulala-github-action]

---

</div>

## Features
  
- Protocols: HTTP, gRPC, GraphQL, OpenAPI/Swagger explorer, WebSocket, Streaming
- Variables: Environment, Document, Request, Dynamic, Prompt, `http-client.env` files
- `$kulalaShared` / `$kulalaDefaultHeaders` in `http-client.env.json` for shared vars and default HTTP headers
- Importing and running requests from external `*.http` files
- Importing and saving request/response data to/from external files
- JavaScript (Jetbrains compatible) Pre-request, Post-request, Conditional, Inline, External
  - TypeScript Pre-request, Post-request, Conditional, Inline, External
  - `request.skip(message?)`, `request.abort(message?)`, `request.replay()` control flow
  - `$kulala.client.global.headers` for persisted default headers (also via env files)
- Authentication: Basic, Bearer, Digest, NTLM, OAuth2, Negotiate, AWS, SSL
- Response formatting and live filtering
- Assertions, automated testing and reporting
- Built-in LSP completion
- Scratchpad: for making requests
- Compatibility with IntelliJ HTTP Client

## Install

> [!WARNING]
> Requires Neovim 0.12+, cURL, git and tree-sitter-cli .
>
> Only x86_64 and arm64 architectures on MacOS/Linux
> and only x86_64 on Windows are supported by kulala-core.
>
> cURL is required for downloading the kulala-core backend.
>
> git is required for downloading the
> kulala-http tree-sitter parser and queries.
>
> tree-sitter-cli is required for generating the parser
> from the included grammar.

Via [lazy.nvim](https://github.com/folke/lazy.nvim):

### Configuration

```lua
require("lazy").setup({
  {
    "dont-be-evil-company/kulala.nvim",
    -- Load before session save/restore so VimLeavePre and SessionLoadPost hooks are registered.
    event = { "SessionLoadPost", "VimLeavePre" },
    keys = {
      { "<leader>Rs", desc = "Send request" },
      { "<leader>Ra", desc = "Send all requests" },
      { "<leader>Rb", desc = "Open scratchpad" },
    },
    -- See opts.lsp.enforce_external_script_naming_convention
    -- to restrict LSP capabilities to *.http, *.http.js, *.http.ts and *.http.lua files.
    ft = {"http", "rest", "javascript", "lua"},
    opts = {
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
        -- "curl" or "wget" or full path to "curl" or "wget" executable.
        download_tool = "curl",
      },
      -- Restore request history and UI after sourcing a vim session.
      -- Requires `set sessionoptions+=globals` in your Neovim config.
      session = {
        restore = true,
      },
      treesitter = {
        -- enable/disable kulala.nvim own
        -- handling of tree-sitter parser and queries for HTTP scripts
        -- like downloading, building, and installing the parser and queries.
        -- disable to manage the parser and queries yourself.
        enable = true,
        -- path to tree-sitter CLI, if not in PATH
        -- if enable is false, this is not used
        -- required for building the parser from the included grammar
        cli_path = "tree-sitter",
      },
      -- dev, test, prod, can be anything
      -- see: https://learn.microsoft.com/en-us/aspnet/core/test/http-files?view=aspnetcore-8.0#environment-files
      default_env = "default",
      -- `"b"` = per-buffer env (default), `"g"` = global
      environment_scope = "b",
      -- enable reading vscode rest client environment variables
      vscode_rest_client_environmentvars = false,

      -- Response body pretty-printing
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

        -- enable/disable request summary in the output window
        show_request_summary = true,

        -- do not show responses over maximum size, in bytes
        max_response_size = 32768,

        -- used by `Copy as Curl` command to determine whether to inline request body
        max_request_size = 2048,

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

      -- Forward script console output (`console.*`, `client.log`, skip/abort messages)
      -- to vim.notify. Set to false to disable.
      script_console_notify = true,
      --[[
        {
          title = "kulala",
          notify = function(message, level, opts, entry)
            vim.notify(message, level, opts)
          end,
        }
      ]]

      -- OpenAPI explorer panel keymaps (see docs or lua/kulala/config/keymaps.lua)
      openapi_panel_keymaps = true,

      -- OpenAPI explorer split, fold signs, and highlight groups
      openapi_panel = {
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
    },
  },
})
```

> [!NOTE]
> By default global keymaps are disabled.
> Change `global_keymaps = true` to
> get a complete set of key mappings for Kulala.

See complete [configuration](#configuration) for more information.

## Honorable mentions

### rest.nvim

For getting this project started.

The actual state of [rest.nvim][rest-nvim]
as archived kicked off the development of kulala.nvim.

It's not archived anymore,
but the state of the project at the time was a great motivation

### curl.nvim

If you want a uncomplicated scratchpad for making HTTP requests,
check out [curl.nvim][curl-nvim].

Different to this project,
but also a great option if you just want to make quick
HTTP requests from within Neovim.



[restnvim-unarchived-post]: https://github.com/rest-nvim/rest.nvim/issues/398#issue-2442747909
[badge-discord]: https://the-dont-be-evil-company.com/assets/badges/discord.svg
[discord]: https://the-dont-be-evil-company.com/discord
[badge-made-with-love]: https://the-dont-be-evil-company.com/assets/badges/made-with-love.svg
[contributors]: https://github.com/dont-be-evil-company/kulala.nvim/graphs/contributors
[badge-test-status]: https://img.shields.io/github/actions/workflow/status/dont-be-evil-company/kulala.nvim/tests.yml?label=main&branch=main&style=for-the-badge
[link-test-status]: https://github.com/dont-be-evil-company/kulala.nvim/actions/workflows/tests.yml
[rest-nvim]: https://github.com/rest-nvim/rest.nvim
[curl-nvim]: https://github.com/oysandvik94/curl.nvim
[kulala-cli]: https://github.com/dont-be-evil-company/kulala-cli
[kulala-fmt]: https://github.com/dont-be-evil-company/kulala-fmt
[kulala-desktop]: https://github.com/dont-be-evil-company/kulala-desktop
[kulala.vscode]: https://github.com/dont-be-evil-company/kulala.vscode
[kulala-core]: https://github.com/dont-be-evil-company/kulala-core
[kulala-github-action]: https://github.com/dont-be-evil-company/kulala-github-action
[demo-image]: https://github.com/user-attachments/assets/a7b3b01f-0115-44dc-94d2-8abd4db6fb60
[badge-development-status]: https://the-dont-be-evil-company.com/assets/badges/development-status.svg
[development-status]: https://the-dont-be-evil-company.com/roadmap?filter=kulala.nvim
[badge-ai-policy]: https://the-dont-be-evil-company.com/assets/badges/ai-policy.svg
[ai-policy]: https://the-dont-be-evil-company.com/ai-policy
[badge-our-manifesto]: https://the-dont-be-evil-company.com/assets/badges/our-manifesto.svg
[our-manifesto]: https://the-dont-be-evil-company.com/manifesto
