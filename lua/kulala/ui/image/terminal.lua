---@class kulala.image.Env
---@field name string
---@field supported? boolean
---@field placeholders? boolean
---@field remote? boolean
---@field transform? fun(data: string): string
---@field protocol? "kitty"|"iterm2"|nil

local M = {}

local size ---@type kulala.image.Dim?

---@type kulala.image.Env[]
local environments = {
  {
    name = "kitty",
    env = { KITTY_WINDOW_ID = true, KITTY_PID = true, TERM = "xterm-kitty", TERM_PROGRAM = "kitty" },
    supported = true,
    placeholders = true,
    protocol = "kitty",
  },
  {
    name = "ghostty",
    env = {
      GHOSTTY_RESOURCES_DIR = true,
      GHOSTTY_BIN_DIR = true,
      GHOSTTY_SHELL_FEATURES = true,
      TERM = "ghostty",
      TERM_PROGRAM = "ghostty",
    },
    supported = true,
    placeholders = true,
    protocol = "kitty",
  },
  {
    name = "wezterm",
    env = { WEZTERM_EXECUTABLE = true, WEZTERM_PANE = true, TERM_PROGRAM = "wezterm" },
    supported = true,
    placeholders = false,
    protocol = "kitty",
  },
  {
    name = "iterm2",
    env = { TERM_PROGRAM = "iTerm.app", ITERM_SESSION_ID = true },
    supported = true,
    placeholders = false,
    protocol = "iterm2",
  },
  {
    name = "tmux",
    env = { TERM = "tmux", TMUX = true },
    setup = function()
      pcall(vim.fn.system, { "tmux", "set", "-p", "allow-passthrough", "all" })
    end,
    transform = function(data)
      return ("\027Ptmux;" .. data:gsub("\027", "\027\027")) .. "\027\\"
    end,
  },
  { name = "zellij", env = { TERM = "zellij", ZELLIJ = true }, supported = false },
  { name = "ssh", env = { SSH_CLIENT = true, SSH_CONNECTION = true }, remote = true },
}

M._env = nil ---@type kulala.image.Env?
M.transform = nil ---@type fun(data: string): string|nil

vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("kulala.image.terminal", { clear = true }),
  callback = function()
    size = nil
  end,
})

---@class kulala.image.Dim
---@field width number
---@field height number
---@field columns number
---@field rows number
---@field cell_width number
---@field cell_height number
---@field scale number

function M.size()
  if size then return size end
  local dw, dh = 9, 18
  size = {
    width = vim.o.columns * dw,
    height = vim.o.lines * dh,
    columns = vim.o.columns,
    rows = vim.o.lines,
    cell_width = dw,
    cell_height = dh,
    scale = dw / 8,
  }

  pcall(function()
    local ffi = require("ffi")
    ffi.cdef([[
      typedef struct {
        unsigned short row;
        unsigned short col;
        unsigned short xpixel;
        unsigned short ypixel;
      } winsize;
      int ioctl(int, int, ...);
    ]])
    local TIOCGWINSZ = vim.fn.has("linux") == 1 and 0x5413 or 0x40087468
    local sz = ffi.new("winsize")
    if ffi.C.ioctl(1, TIOCGWINSZ, sz) ~= 0 or sz.col == 0 or sz.row == 0 or sz.xpixel == 0 or sz.ypixel == 0 then
      return
    end
    size = {
      width = sz.xpixel,
      height = sz.ypixel,
      columns = sz.col,
      rows = sz.row,
      cell_width = sz.xpixel / sz.col,
      cell_height = sz.ypixel / sz.row,
      scale = math.max(1, sz.xpixel / sz.col / 8),
    }
  end)

  return size
end

function M.env()
  if M._env then return M._env end

  M._env = { name = "", env = {} }
  for _, e in ipairs(environments) do
    local override = os.getenv("KULALA_" .. e.name:upper())
    local detected = false
    if override then
      detected = override ~= "0" and override ~= "false"
    else
      for k, v in pairs(e.env or {}) do
        local val = os.getenv(k)
        if val and (v == true or val:lower():find(tostring(v):lower(), 1, true)) then
          detected = true
          break
        end
      end
    end
    if detected then
      M._env.name = M._env.name .. "/" .. e.name
      if e.supported ~= nil then M._env.supported = e.supported end
      if e.placeholders ~= nil then M._env.placeholders = e.placeholders end
      if e.protocol ~= nil then M._env.protocol = e.protocol end
      M._env.remote = e.remote or M._env.remote
      M.transform = e.transform or M.transform
      if e.setup then e.setup() end
    end
  end
  M._env.name = M._env.name:gsub("^/", "")
  return M._env
end

function M.supports()
  local env = M.env()
  return env.supported == true and (env.protocol == "kitty" or env.protocol == "iterm2")
end

function M.protocol()
  return M.env().protocol
end

---@param opts table<string, string|number>|{data?: string}
function M.request(opts)
  opts.q = opts.q ~= false and (opts.q or 2) or nil
  local msg = {}
  for k, v in pairs(opts) do
    if k ~= "data" then table.insert(msg, string.format("%s=%s", k, v)) end
  end
  local data = "\27_G" .. table.concat(msg, ",")
  if opts.data then data = data .. ";" .. tostring(opts.data) end
  data = data .. "\27\\"
  M.write(data)
end

---@param pos {[1]: number, [2]: number}
function M.set_cursor(pos)
  M.write("\27[" .. pos[1] .. ";" .. (pos[2] + 1) .. "H")
end

function M.write(data)
  data = M.transform and M.transform(data) or data
  if vim.api.nvim_ui_send then
    vim.api.nvim_ui_send(data)
  else
    io.stdout:write(data)
  end
end

---Write iTerm2 / WezTerm OSC 1337 inline image.
---@param base64 string
---@param byte_length number
function M.iterm2_image(base64, byte_length)
  M.write(
    ("\27]1337;File=inline=1;size=%d;width=auto;height=auto;preserveAspectRatio=1:%s\07"):format(byte_length, base64)
  )
end

return M
