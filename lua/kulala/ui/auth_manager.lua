local has_telescope = pcall(require, "telescope")
local has_snacks, snacks_picker = pcall(require, "snacks.picker")

local Config = require("kulala.config")
local DB = require("kulala.db")
local Env = require("kulala.parser.env")
local Fs = require("kulala.utils.fs")
local Logger = require("kulala.logger")
local Oauth = require("kulala.cmd.oauth")
local Table = require("kulala.utils.table")

local M = {}

local template = {
  ["$schema"] = "https://kulala.app/http-client.env.schema.json",
  ["$kulalaShared"] = {
    ["$kulalaDefaultHeaders"] = {},
  },
  dev = {
    Security = { Auth = {} },
  },
  prod = {},
}

local function create_env_file(name)
  name = name or "http-client.env.json"

  local path = Fs.find_file_in_parent_dirs(name)
  if path or vim.fn.confirm("Create " .. name .. "?", "&Yes\n&No") == 2 then return path end

  path = Fs.get_current_buffer_dir() .. "/" .. name
  Fs.write_json(path, template)
  Logger.info("Created env file: " .. path)

  return path
end

local function get_env(create)
  if create then create_env_file() end
  DB.set_current_buffer(vim.fn.bufnr())

  local cur_env = Env.get_current_env()
  local env = DB.find_unique("http_client_env") or (Env.get_env() and DB.find_unique("http_client_env")) or {}

  local auth = vim.tbl_get(env, cur_env, "Security", "Auth")
    or Table.set_at(env, { cur_env, "Security", "Auth" }, {})[cur_env].Security.Auth

  return auth, cur_env
end

local function update_auth_config(name, value)
  local file_name = "http-client.env.json"
  local public_env_path = Fs.find_file_in_parent_dirs(file_name)

  local cur_env = Env.get_current_env()
  local public_env = Fs.read_json(public_env_path) or {}

  Table.set_at(public_env, { cur_env, "Security", "Auth", name }, value)

  Fs.write_json(public_env_path, public_env, true)
  Env.get_env()
end

local function add_new_config()
  local name = vim.fn.input("Enter new config name: ")
  if name and name ~= "" then
    update_auth_config(name, Oauth.auth_template())
    Logger.info("Added new Auth config: " .. name)
  end
end

local function remove_config(value)
  local confirm = vim.fn.confirm("Are you sure you want to remove " .. value .. "?", "&Yes\n&No")
  if confirm == 1 then
    update_auth_config(value, nil)
    Logger.info("Removed Auth config: " .. value)
  end
end

local get_env_file = function(name)
  local file = name or "http-client.env.json"
  return Fs.find_file_in_parent_dirs(file) or create_env_file(name)
end

local function edit_env_file(config, picker, name)
  local file = get_env_file(name)
  if not config or not file then return end

  picker:close()
  vim.cmd(('edit +/"%s": %s'):format(config:gsub(" ", "\\ "), file))

  return true
end

local function edit_private_env_file(config, picker)
  return edit_env_file(config, picker, "http-client.private.env.json")
end

local function set_buffer(buf, content)
  if not content then return end
  content = vim.split(vim.inspect(content), "\n")

  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_set_option_value("filetype", "lua", { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

local commands = {
  a = { add_new_config, "Add new Auth configuration" },
  e = { edit_env_file, "Edit Auth configuration" },
  p = { edit_private_env_file, "Edit private Auth configuration" },
  m = { remove_config, "Remove Auth configuration" },
  g = { Oauth.acquire_token_manually, "Get new token" },
  f = { Oauth.refresh_token_manually, "Refresh token" },
  r = { Oauth.revoke_token, "Revoke token" },
}

local keys_hint = " a:Add e:Edit p:Edit private m:Remove g:Get new f:Refresh r:Revoke"

local function open_auth_telescope()
  local actions = require("telescope.actions")

  local env = get_env(true)
  local config_names = vim.tbl_keys(env)

  local action_state = require("telescope.actions.state")
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")
  local previewers = require("telescope.previewers")
  local config = require("telescope.config").values

  pickers
    .new({}, {
      results_title = "Auth Configurations",
      prompt_title = keys_hint,
      finder = finders.new_table {
        results = config_names,
      },

      attach_mappings = function(prompt_bufnr, map)
        local function run_cmd(cmd)
          local selection = action_state.get_selected_entry() or {}

          local picker = {
            close = function()
              actions.close(prompt_bufnr)
            end,
          }

          if commands[cmd][1](selection.value, picker) == true then return end

          actions.close(prompt_bufnr)
          M.open_auth_config()
        end

        actions.select_default:replace(function()
          run_cmd("e")
        end)

        vim.iter(commands):each(function(key)
          map("n", key, function()
            run_cmd(key)
          end, { desc = commands[key][2] })
        end)

        return true
      end,

      previewer = previewers.new_buffer_previewer {
        title = "Configuration Details",
        define_preview = function(self, entry)
          set_buffer(self.state.bufnr, env[entry.value])
        end,
      },

      sorter = config.generic_sorter {},
    })
    :find()
end

local function open_auth_snacks()
  local env, cur_env = get_env(true)
  local config_names = vim.tbl_keys(env)

  local items = vim.iter(config_names):fold({}, function(acc, name)
    local config_data = env[name]
    table.insert(acc, {
      text = name,
      label = name,
      data = config_data,
      file = get_env_file(),
      content = config_data,
    })
    return acc
  end)

  table.sort(items, function(a, b)
    return a.text:lower() > b.text:lower()
  end)

  local run_cmd = function(key, ctx, item)
    item = item or {}
    if commands[key][1](item.text, ctx) == true then return end
    ctx:close()
    M.open_auth_config()
  end

  local _actions = {}
  local keys = {}

  vim.iter(commands):each(function(key)
    _actions[key] = function(ctx, item)
      run_cmd(key, ctx, item)
    end
    keys[key] = { key, mode = { "n" }, desc = commands[key][2] }
  end)

  local env_file_path = get_env_file()
  if not env_file_path then return Logger.warn("http-client.env.json not found") end

  snacks_picker {
    title = "Auth Configurations",
    items = items,
    actions = _actions,
    layout = Config.options.ui.pickers.snacks.layout,
    show_empty = true,

    preview = function(ctx)
      set_buffer(ctx.picker.layout.wins.preview.buf, ctx.item.content)
      return true
    end,

    win = {
      preview = {
        title = "Configuration Details",
        wo = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
          winbar = (" "):rep(5) .. keys_hint,
          wrap = false,
          sidescrolloff = 1,
        },
      },

      input = { keys = keys },

      list = {
        title = "Auth Configurations",
        wo = {
          winbar = (" "):rep(5) .. env_file_path .. " (Current env: " .. cur_env .. ")",
        },
      },
    },
    confirm = function(picker, item)
      run_cmd("e", picker, item)
    end,
  }
end

M.open_auth_config = function()
  if has_snacks then
    open_auth_snacks()
  elseif has_telescope then
    open_auth_telescope()
  else
    Logger.warn("Telescope or Snacks is required for auth token management")
  end
end

M.get_env = get_env

return M
