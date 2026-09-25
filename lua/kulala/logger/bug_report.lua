local Config = require("kulala.config")
local Db = require("kulala.db")
local Float = require("kulala.ui.float")
local Health = require("kulala.health")
local Json = require("kulala.utils.json")
local Logger = require("kulala.logger")
local Shell = require("kulala.cmd.shell_utils")

local M = {}

local kulala_repo = "dont-be-evil-company/kulala.nvim"

local template = [[

* Press `<leader>S` to open a GitHub issue with this report, `q` - to close this window.

## Title: [BUG] %s

## Description

*Describe the bug*

## Steps to Reproduce

*Steps to reproduce the behavior*

## Request

%s

## Error

```lua
%s
```

## Health

```checkhealth
%s
```

## User Config

```lua
%s
```
]]

local function get_health()
  local health = setmetatable({ out = "" }, {
    __index = function(t, key)
      return function(msg)
        key = key == "start" and "\n"
          or (key == "ok" and "✔ " or (key == "error" and "✘ " or (key == "warn" and "⚠ " or "ℹ ")))
        t.out = t.out .. key .. msg .. "\n"
      end
    end,
  })

  Health.check(health)

  return health.out
end

M.create_issue = function(title, body, labels, type)
  if vim.fn.executable("gh") == 0 then return Logger.warn("Please install GitHub CLI to create issues.") end

  title = title or ""
  body = body or ""

  if #title == 0 or #body == 0 then return end

  title = "title=" .. title
  body = "body=" .. body
  labels = "labels[]=" .. table.concat(labels or {}, ",")
  type = "type=" .. (type or "")

  local endpoint = "/repos/" .. kulala_repo .. "/issues"
  local cmd = { "gh", "api", "-X", "POST", endpoint, "-f", title, "-f", body, "-f", labels, "-f", type }

  local result = Shell.run(cmd, {
    sync = true,
    verbose = false,
    abort_on_stderr = true,
    on_error = function(system)
      local msg
      if system.stderr:find("gh auth login") then
        msg = "GitHub CLI is not authenticated. Please run `gh auth login` "
          .. "to authenticate or set GH_TOKEN environment variable.\n"
      else
        msg = "Failed to create issue, code: " .. system.code .. ", " .. system.stderr
      end
      Logger.error(msg, 2)
    end,
  })

  if not result or result.stderr ~= "" then return end
  result = Json.parse(result.stdout)

  local link = result and result.html_url
  if link then Logger.info("Issue created successfully: " .. link) end

  return true
end

local function get_current_request()
  local request, buf = Db.current_request, Db.current_buffer
  if not request or not buf then return end

  local status, result = pcall(function()
    return vim.fn.join(vim.api.nvim_buf_get_lines(buf, request.start_line - 2, request.end_line, false), "\n")
  end)

  return status and "```http\n" .. result .. "\n```" or ""
end

M.generate_bug_report = function(error)
  error = error or ""

  local title = vim.split(error, "\n")[1]
  local request = get_current_request()
  local health = get_health()
  local user_config = vim.inspect(Config.user_config)
  local report = vim.split(template:format(title, request, error, health, user_config), "\n")

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)

  local float = Float.create(report, {
    title = "Kulala Bug Report",
    name = "kulala://bug_report",
    ft = "markdown",
    focusable = true,
    border = "single",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    close_keymaps = { "q" },
    wo = { signcolumn = "yes:1", wrap = true },
  })

  vim.keymap.set("n", "<leader>S", function()
    report = vim.api.nvim_buf_get_lines(float.buf, 0, -1, false)

    local title_lnum
    for i, line in ipairs(report) do
      if line:match("^## Title:") then
        title_lnum = i
        break
      end
    end

    title = title_lnum and (report[title_lnum] or ""):gsub("^## Title: ", "")

    local body = table.concat(report, "\n", title_lnum + 2 or 4)
    local labels, type = { "automated" }, "bug"

    M.create_issue(title, body, labels, type)
  end, { buffer = float.buf, noremap = true, silent = true })
end

return M
