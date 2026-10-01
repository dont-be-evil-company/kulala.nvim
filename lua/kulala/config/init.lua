local Backend = require("kulala.backend")
local Parser = require("kulala.config.parser")
local defaults = require("kulala.config.defaults")
local keymaps = require("kulala.config.keymaps")

local M = {}

M.defaults = defaults

M.default_contenttype = {
  ft = "text",
  pathresolver = nil,
}

M.options = M.defaults

local function set_signcolumn_icons()
  vim.fn.sign_define {
    { name = "kulala.done", text = M.options.icons.inlay.done, texthl = M.options.ui.icons.doneHighlight },
    { name = "kulala.error", text = M.options.icons.inlay.error, texthl = M.options.ui.icons.errorHighlight },
    { name = "kulala.loading", text = M.options.icons.inlay.loading, texthl = M.options.ui.icons.loadingHighlight },
    { name = "kulala.space", text = " " },
  }
end

local function set_legacy_options()
  M.options = vim.tbl_deep_extend("keep", M.options, M.options.ui)
end

local function buffer_needs_backend(buf, ft)
  if ft == "http" or ft == "rest" then return true end
  local script_fts = { javascript = true, typescript = true, lua = true }
  if not script_fts[ft] then return false end
  return require("kulala.utils.fs").is_http_script_file(ft, buf)
end

local function start_lsp_if_ready(buf, ft)
  if not (Parser.is_up_to_date() and Backend.is_up_to_date() and M.options.lsp.enable) then return end
  if not vim.api.nvim_buf_is_valid(buf) then return end
  require("kulala.cmd.lsp").start(buf, ft)
end

---Install kulala-core for an HTTP buffer, then start LSP.
---Ordinary script buffers and a configured `kulala_core.path` do not download.
---Skipped while Neovim is exiting so quit cannot block on the license prompt.
---@param buf integer
---@param ft? string
function M.prepare_backend_for_buffer(buf, ft)
  if vim.v.exiting ~= vim.NIL then return end
  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then return end
  ft = ft or vim.api.nvim_get_option_value("filetype", { buf = buf })
  if not M.options.lsp.enable or not buffer_needs_backend(buf, ft) then return end

  if Backend.is_up_to_date() then
    start_lsp_if_ready(buf, ft)
    return
  end

  local path = M.options.kulala_core.path
  if type(path) == "string" and vim.trim(path) ~= "" then return end

  Backend.ensure_installed(function()
    start_lsp_if_ready(buf, ft)
  end)
end

M.set_autocomands = function()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("Kulala filetype setup", { clear = true }),
    pattern = M.options.lsp.filetypes,
    callback = function(ev)
      M.prepare_backend_for_buffer(ev.buf, ev.match)
    end,
  })
end

local function set_syntax_hl()
  vim.iter(M.options.ui.syntax_hl or {}):each(function(hl, group)
    group = type(group) == "string" and { link = group } or group
    vim.api.nvim_set_hl(0, hl, group)
  end)
end

M.setup = function(config)
  M.user_config = config or {}
  -- Copy defaults so repeated setup() calls do not accumulate into the shared defaults table.
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), M.user_config)

  set_legacy_options()
  Parser.setup()
  set_syntax_hl()
  M.set_autocomands()

  if M.options.show_icons == "signcolumn" then pcall(set_signcolumn_icons) end
  M.options.global_keymaps, M.options.ft_keymaps = keymaps.setup_global_keymaps()

  require("kulala.vim-sessions").setup()

  M.options.initialized = true

  return M.options
end

M.set = function(config)
  M.options = vim.tbl_deep_extend("force", M.options, config or {})
end

---@return KulalaDefaultConfig
M.get = function()
  return M.options
end

return M
