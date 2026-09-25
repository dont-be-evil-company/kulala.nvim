-- luacheck: ignore 631
-- Ignores lines too long

---Win open options for Kulala UI, plus optional buffer/window option bags.
---@class kulala.ui.win_config
---@field relative? string
---@field width? number
---@field height? number
---@field row? number
---@field col? number
---@field split? string|fun():string
---@field win? integer
---@field title? string
---@field title_pos? string
---@field border? string
---@field style? string
---@field zindex? integer
---@field bo? table<string, any> Buffer options
---@field wo? table<string, any> Window options

---@class KulalaDefaultConfigKulalaCore
---@field path string|nil Path to kulala-core executable
---@field timeout number|nil Timeout in milliseconds for the kulala-core sub-process; nil disables the timeout
---@field data_dir string|nil Override for kulala-core data dir
---@field download_url string|"https://github.com/dont-be-evil-company/kulala-core/releases/download/%s/%s" Override for download url
---@field download_tool "curl"|"wget"|string curl or wget or full path to the download curl or wget

---@class KulalaDefaultConfigSession
---@field restore boolean Restore request history and UI after sourcing a vim session

---@class KulalaDefaultConfigResponseFormat
---@field indent number Indentation
---@field expand_tabs boolean False, if you want to use tabs instead of spaces
---@field sort_keys boolean False, if you want to preserve the original key order

---@class KulalaDefaultConfigUiIconsInlay
---@field loading string
---@field done string
---@field error string

---@class KulalaDefaultConfigUiIcons
---@field inlay KulalaDefaultConfigUiIconsInlay
---@field lualine string
---@field textHighlight string Highlight group for request elapsed time
---@field loadingHighlight string
---@field doneHighlight string
---@field errorHighlight string

---@class KulalaDefaultConfigUiReport
---@field show_script_output boolean|"on_error"
---@field show_asserts_output boolean|"on_error"|"failed_only"
---@field show_summary boolean|"on_error"
---@field headersHighlight string
---@field successHighlight string
---@field errorHighlight string

---@class KulalaDefaultConfigUiPickersSnacks
---@field layout fun(): table

---@class KulalaDefaultConfigUiPickers
---@field snacks KulalaDefaultConfigUiPickersSnacks

---@alias KulalaWinbarPane "body"|"headers"|"headers_body"|"script_output"|"stats"|"verbose"|"report"|"help"

---@class KulalaDefaultConfigUi
---@field display_mode "split"|"float"
---@field split_direction "above"|"right"|"below"|"left"|"vertical"|"horizontal"|fun(): "above"|"right"|"below"|"left"
---@field win_opts kulala.ui.win_config
---@field default_view "body"|"headers"|"headers_body"|"verbose"|"report"|fun(response: Response)
---@field winbar boolean
---@field default_winbar_panes KulalaWinbarPane[]
---@field winbar_labels table<KulalaWinbarPane, string>
---@field winbar_labels_keymaps boolean
---@field show_variable_info_text false|"float"
---@field show_icons "signcolumn"|"on_request"|"above_request"|"below_request"|nil
---@field icons KulalaDefaultConfigUiIcons
---@field syntax_hl table<string, string|vim.api.keyset.highlight>
---@field show_request_summary boolean
---@field max_response_size number
---@field max_request_size number
---@field show_images boolean
---@field report KulalaDefaultConfigUiReport
---@field scratchpad_default_contents string[]
---@field pickers KulalaDefaultConfigUiPickers

---@class KulalaDefaultConfigLsp
---@field enable boolean
---@field filetypes string[]
---@field enforce_external_script_naming_convention boolean
---@field keymaps boolean|table
---@field on_attach fun(client: table, buf: number)|nil

---@class KulalaScriptConsoleNotifyConfig
---@field enabled? boolean When false, script console output is not forwarded to vim.notify
---@field title? string Notify title (default: "kulala")
---@field notify? fun(message: string, level: integer, opts: table, entry: table) Custom notify handler

---@class KulalaDefaultConfig
---@field kulala_core KulalaDefaultConfigKulalaCore
---@field session KulalaDefaultConfigSession
---@field default_env string Default environment name
---@field environment_scope "b"|"g" Scope of variables. *g*lobal can leak into other *b*uffers
---@field vscode_rest_client_environmentvars boolean Read vscode rest-client environment variables
---@field response_format KulalaDefaultConfigResponseFormat
---@field ui KulalaDefaultConfigUi
---@field lsp KulalaDefaultConfigLsp
---@field debug number
---@field generate_bug_report boolean
---@field global_keymaps boolean|table
---@field global_keymaps_prefix string
---@field kulala_keymaps boolean|table
---@field kulala_keymaps_prefix string
---@field openapi_panel_keymaps boolean|table
---@field script_console_notify boolean|KulalaScriptConsoleNotifyConfig
---@field openapi_panel? table
---@field initialized? boolean
---@field halt_on_error? boolean
---@field before_request? boolean|fun(request: DocumentRequest): boolean
---@field icons? table Legacy flattened icons (merged from ui via set_legacy_options)
---@field display_mode? "split"|"float" Legacy flattened UI option
---@field split_direction? "above"|"right"|"below"|"left"|"vertical"|"horizontal"|fun(): "above"|"right"|"below"|"left" Legacy flattened UI option
---@field default_view? "body"|"headers"|"headers_body"|"verbose"|fun(response: Response) Legacy flattened UI option
---@field winbar? boolean Legacy flattened UI option
---@field default_winbar_panes? string[] Legacy flattened UI option
---@field win_opts? kulala.ui.win_config Legacy flattened UI option
---@field show_icons? string|nil Legacy flattened UI option
---@field show_request_summary? boolean Legacy flattened UI option
---@field max_response_size? number Legacy flattened UI option
---@field report? table Legacy flattened UI option
---@field scratchpad_default_contents? string[] Legacy flattened UI option
---@field pickers? table Legacy flattened UI option
---@field syntax_hl? table Legacy flattened UI option
---@field show_variable_info_text? false|"float" Legacy flattened UI option
---@field winbar_labels? table Legacy flattened UI option
---@field winbar_labels_keymaps? boolean Legacy flattened UI option
---@field max_request_size? number Legacy flattened UI option
