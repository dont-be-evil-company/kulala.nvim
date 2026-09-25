local backend_version = require("kulala.globals.versions.backend")
local fs = require("kulala.utils.fs")
local plugin_version = require("kulala.globals.versions.plugin")
local treesitter_version = require("kulala.globals.versions.treesitter")
local plugin_tmp_dir = fs.get_plugin_tmp_dir()
local M = {}

M.VERSION = plugin_version
M.BACKEND_VERSION = backend_version
M.TREESITTER_VERSION = treesitter_version
M.KULALA_CORE_BINARY_NAME = "kulala-core"
M.NAME = "kulala.nvim"
M.UI_ID = "kulala://ui"
M.SCRATCHPAD_ID = "kulala://scratchpad"
M.OPENAPI_EXPLORER_ID = "kulala://openapi-explorer"
M.OPENAPI_EDIT_ID = "kulala://openapi-edit"
M.HEADERS_FILE = plugin_tmp_dir .. "/headers.txt"
M.BODY_FILE = plugin_tmp_dir .. "/body.txt"
M.COOKIES_JAR_FILE = plugin_tmp_dir .. "/cookies.txt"
M.SETTINGS_FILE = vim.fn.stdpath("state") .. "/kulala.nvim/settings.json"
M.TREESITTER_REPO_URL = "https://github.com/dont-be-evil-company/tree-sitter-kulala-http"

return M
