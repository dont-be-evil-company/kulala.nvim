-- require KULALA_CORE_LICENSE_TOKEN env var
if not vim.env.KULALA_CORE_LICENSE_TOKEN then
  print("KULALA_CORE_LICENSE_TOKEN env var is not set, exiting...")
  vim.cmd("cquit 1")
end

local data_dir = vim.env.XDG_DATA_HOME .. "/nvim/site"
vim.o.termguicolors = true
vim.opt.swapfile = false
vim.opt.shada = ""
vim.opt.undofile = false

vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.opt.rtp = {
  vim.env.VIMRUNTIME,
  data_dir,
  vim.fn.getcwd(),
}

_G.TEST = true

local function log(msg)
  vim.schedule(function()
    print(msg .. "\n")
  end)
end

local function get_plugins()
  local plugins = {}
  for _, plugin in ipairs(vim.split(vim.env.PLUGINS, " ")) do
    local repo, name = unpack(vim.split(plugin, ";"))
    table.insert(plugins, { repo = repo, name = name })
  end
  return plugins
end

local get_plugin_path = function(plugin)
  return data_dir .. "/pack/plugins/start/" .. plugin.name
end

local plugins_count = 0
local plugins_total = 0

local function setup_plugin(plugin, count, total, callback)
  local package_path = data_dir .. "/pack/plugins/start/" .. plugin.name
  vim.opt.rtp:append(package_path)
  local ok, mod = pcall(require, plugin.name)
  if ok and type(mod.setup) == "function" then
    mod.setup()
    log("    - Setup completed for plugin: " .. plugin.name)
  elseif not ok then
    log("    - Error loading plugin: " .. plugin.name .. " - " .. mod)
  else
    log("    - No setup function for plugin: " .. plugin.name)
  end
  plugins_count = plugins_count + 1
  if count == total - 1 and callback and type(callback) == "function" and ok then callback() end
end

local function ensure_plugins_installed(callback)
  local plugins = get_plugins()
  plugins_total = #plugins
  log("Installing plugins...")
  for _, plugin in ipairs(plugins) do
    log("  - " .. plugin.name)
    local package_path = data_dir .. "/pack/plugins/start/" .. plugin.name
    if vim.fn.isdirectory(package_path) == 0 then
      if vim.startswith(plugin.repo, "file://") then
        log("    - Copying from local path: " .. plugin.repo)
        local source_path = plugin.repo:sub(8)
        vim.fn.mkdir(package_path, "p")
        vim.fn.system { "rsync", "-a", "--exclude=node_modules", "--exclude=.git", source_path .. "/", package_path }
        setup_plugin(plugin, plugins_count, plugins_total, callback)
      else
        log("    - Cloning from remote repository: " .. plugin.repo)
        vim.system({
          "git",
          "clone",
          "--depth",
          "1",
          plugin.repo,
          package_path,
        }, function(obj)
          if obj.code == 0 then
            vim.schedule(function()
              setup_plugin(plugin, plugins_count, plugins_total, callback)
            end)
          end
        end)
      end
    else
      log("    - Already installed, skipping: " .. plugin.name)
      setup_plugin(plugin, plugins_count, plugins_total, callback)
    end
  end
end

ensure_plugins_installed(function()
  vim.schedule(function()
    log("Running tests... waiting for Kulala to fire 'ready' event")
    local Api = require("kulala.api")
    local function run_tests()
      log("Kulala is ready, running tests...")
      local kulala_plugin_path = get_plugin_path { name = "kulala" }
      local tests_dir = kulala_plugin_path .. "/tests"
      package.path = tests_dir .. "/?.lua;" .. tests_dir .. "/?/?.lua;" .. package.path

      local function find_test_files()
        local files = vim.fn.globpath(tests_dir, "**/*_spec.lua", true, true)
        for _, file in ipairs(vim.fn.globpath(tests_dir, "**/test_*.lua", true, true)) do
          if not file:find("/test_helper/") then table.insert(files, file) end
        end
        local filter = vim.env.KULALA_TEST_FILTER
        if filter and filter ~= "" then
          files = vim.tbl_filter(function(f)
            return f:find(filter, 1, true) ~= nil
          end, files)
        end
        return files
      end

      require("kulala.test_helper.globals").install()

      local MiniTest = require("mini.test")
      local reporter = MiniTest.gen_reporter.stdout { progress = "dot" }
      MiniTest.setup {
        collect = { emulate_busted = true },
        execute = { reporter = reporter },
      }
      MiniTest.run {
        collect = { find_files = find_test_files },
        execute = { reporter = reporter },
      }
      vim.wait(600000, function()
        return not MiniTest.is_executing()
      end, 50)

      local n_fail = 0
      for _, case in ipairs(MiniTest.current.all_cases or {}) do
        if case.exec and case.exec.state and case.exec.state:find("Fail") then
          n_fail = n_fail + 1
          for _, msg in ipairs(case.exec.fails or {}) do
            io.write(("[FAIL] %s\n%s\n"):format(table.concat(case.desc or {}, " | "), msg))
          end
        end
      end
      require("kulala.test_helper.globals").uninstall()
      if n_fail > 0 then
        io.write(string.format("\n%d test(s) failed\n", n_fail))
        vim.cmd("cquit 1")
      end
      vim.cmd("qa!")
    end
    Api.on("ready", run_tests)
    -- Startup no longer downloads kulala-core until an HTTP buffer needs it.
    -- This runner never opens one, so install here or `ready` never fires.
    if not Api.has_triggered_ready() then
      local Backend = require("kulala.backend")
      if not Backend.is_up_to_date() then
        log("kulala-core is missing, installing it so tests can start...")
        Backend.ensure_installed()
      end
    end
  end)
end)
