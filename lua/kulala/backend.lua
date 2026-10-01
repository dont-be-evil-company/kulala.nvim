local Api = require("kulala.api")
local Globals = require("kulala.globals")
local Logger = require("kulala.logger")
local Notify = require("kulala.ui.notify")
local Parser = require("kulala.config.parser")
local M = {}

local function platform()
  local system = vim.uv.os_uname().sysname
  local arch = vim.uv.os_uname().machine

  local os_name
  if system == "Darwin" then
    os_name = "darwin"
  elseif system == "Windows_NT" then
    os_name = "windows"
  else
    os_name = "linux"
  end

  -- Normalize architecture names to match release binary names
  local arch_name = arch
  if arch == "x86_64" or arch == "AMD64" then
    arch_name = "x86_64"
  elseif arch == "aarch64" or arch == "ARM64" then
    -- macOS uses "arm64" while Linux uses "aarch64"
    arch_name = os_name == "macos" and "arm64" or "aarch64"
  end

  return os_name .. "-" .. arch_name
end

local PATH_SEP = package.config:sub(1, 1)
local IS_WINDOWS = platform():match("windows")

local join_paths = function(...)
  return table.concat({ ... }, PATH_SEP)
end

M.get_bin_dir = function()
  local data = vim.fn.stdpath("data")
  return join_paths(data, Globals.NAME, "bin")
end

M.get_release_bin_name = function()
  local bin_name = Globals.KULALA_CORE_BINARY_NAME .. "-" .. platform()
  if IS_WINDOWS then bin_name = bin_name .. ".exe" end
  return bin_name
end

M.get_bin_name = function()
  local bin_name = Globals.KULALA_CORE_BINARY_NAME
  if IS_WINDOWS then bin_name = bin_name .. ".exe" end
  return bin_name
end

M.get_bin_path = function()
  local config = require("kulala.config").get()
  if config.kulala_core.path and config.kulala_core.path ~= "" then return config.kulala_core.path end
  return join_paths(M.get_bin_dir(), M.get_bin_name())
end

local function make_executable(path)
  if not IS_WINDOWS then vim.fn.system { "chmod", "+x", path } end
end

local VERSION_PROBE_TIMEOUT_MS = 15000

local function version_probe_ok(result)
  if not result or result.code ~= 0 then return false end
  return vim.trim(result.stdout or "") ~= ""
end

---Run `kulala-core --version`. On macOS, clear quarantine once and retry.
---@param bin_path string
---@param on_done fun(ok: boolean)
local function probe_installed_binary(bin_path, on_done)
  local function run(after)
    vim.system({ bin_path, "--version" }, { text = true, timeout = VERSION_PROBE_TIMEOUT_MS }, function(result)
      vim.schedule(function()
        after(result)
      end)
    end)
  end

  run(function(result)
    if version_probe_ok(result) then
      on_done(true)
      return
    end
    if vim.uv.os_uname().sysname ~= "Darwin" then
      on_done(false)
      return
    end
    vim.system({ "xattr", "-d", "com.apple.quarantine", bin_path }, { text = true }, function()
      run(function(retry)
        on_done(version_probe_ok(retry))
      end)
    end)
  end)
end

local function report_launch_failure(bin_path)
  if vim.fn.filereadable(bin_path) == 1 then vim.fn.delete(bin_path) end
  if vim.uv.os_uname().sysname == "Darwin" then
    Logger.error(
      "macOS refused to start kulala-core. The downloaded binary is signed incorrectly or blocked by Gatekeeper."
    )
  else
    Logger.error("kulala-core --version failed. The downloaded binary did not start.")
  end
end

---Kulala Core data directory. Matches `kulala_core_bridge.effective_data_dir`.
---The token lives here so a plugin or client update does not throw it away.
local function kulala_core_data_dir()
  return require("kulala.cmd.kulala_core_bridge").effective_data_dir()
end

local function license_token_path()
  return join_paths(kulala_core_data_dir(), "license-token")
end

---Previous config-directory location, kept so an already entered token is reused.
local function legacy_license_token_path()
  local sys = vim.uv.os_uname().sysname
  if sys == "Windows_NT" then
    local appdata = vim.env.APPDATA or join_paths(vim.env.USERPROFILE or "", "AppData", "Roaming")
    return join_paths(appdata, "kulala", "license-token")
  elseif sys == "Darwin" then
    return join_paths(vim.env.HOME, "Library", "Application Support", "kulala", "license-token")
  end
  local xdg = vim.env.XDG_CONFIG_HOME
  if xdg and xdg ~= "" then return join_paths(xdg, "kulala", "license-token") end
  return join_paths(vim.env.HOME, ".config", "kulala", "license-token")
end

local function read_token_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local token = vim.trim(f:read("*a") or "")
  f:close()
  if token == "" then return nil end
  return token
end

local function save_license_token(token)
  local path = license_token_path()
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = io.open(path, "w")
  if not f then
    Logger.error("Could not save the Kulala license token")
    return
  end
  f:write(token)
  f:close()
  if not IS_WINDOWS then vim.fn.setfperm(path, "rw-------") end
end

local function read_saved_license_token()
  local saved = read_token_file(license_token_path())
  if saved then return saved end
  local legacy = read_token_file(legacy_license_token_path())
  if not legacy then return nil end
  save_license_token(legacy)
  return legacy
end

---Remove the saved token. Call only after the download server rejects it.
local function delete_saved_license_token()
  for _, path in ipairs { license_token_path(), legacy_license_token_path() } do
    if vim.fn.filereadable(path) == 1 then vim.fn.delete(path) end
  end
end

---Prompt for a license token and save it. Returns nil when the user cancels.
local function prompt_license_token()
  local token = vim.trim(vim.fn.inputsecret("Kulala license token: ") or "")
  if token == "" then
    Logger.error("No license token entered. Set KULALA_CORE_LICENSE_TOKEN to download kulala-core.")
    return nil
  end
  save_license_token(token)
  return token
end

---Resolve the download token. Does not prompt.
---@return string|nil token
---@return string|nil source "env" or "file"
local function resolve_license_token()
  local from_env = vim.env.KULALA_CORE_LICENSE_TOKEN
  if from_env and vim.trim(from_env) ~= "" then return vim.trim(from_env), "env" end
  local saved = read_saved_license_token()
  if saved then return saved, "file" end
  return nil, nil
end

local function read_http_status(header_path)
  local f = io.open(header_path, "r")
  if not f then return nil end
  local status = nil
  for line in f:lines() do
    local code = line:match("^HTTP/%S+%s+(%d+)")
    if code then status = tonumber(code) end
  end
  f:close()
  os.remove(header_path)
  return status
end

local get_version_path = function()
  return join_paths(M.get_bin_dir(), "version.txt")
end

M.get_installed_version = function()
  local version_file = get_version_path()
  local f = io.open(version_file, "r")
  if not f then return nil end
  local v = f:read("*l")
  f:close()
  return v
end

local set_installed_version = function(version)
  local version_file = get_version_path()
  local f = io.open(version_file, "w")
  if not f then error("Could not open version file for writing: " .. version_file) end
  f:write(version)
  f:close()
end

---Download a file using wget with progress parsing
---@param url string URL to download from
---@param output_path string Path to save the file to
---@param progress_callback function|nil Optional callback for progress updates: {progress: number, message: string}
---@param callback function|nil Optional callback after download completes: {success: boolean, http_code: integer|nil}
local function download_via_wget(url, output_path, progress_callback, callback, token)
  local config = require("kulala.config").get()
  local http_code = nil
  local cmd = {
    config.kulala_core.download_tool,
    "--quiet",
    "--server-response",
    "--show-progress",
    "--progress=dot:giga",
    "--header=Authorization: Bearer " .. token,
    "-O",
    output_path,
    url,
  }
  vim.fn.jobstart(cmd, {
    env = vim.fn.environ(),
    on_stdout = vim.schedule_wrap(function(_, data, _)
      -- Parse wget progress output from stdout
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= "" then
            -- Look for lines like " 12% [=====>                                   ] 1.23M 1.23MB/s"
            local percent = line:match("%s+(%d+)%%")
            local speed = line:match("%s+([%d%.]+[KMG]B/s)")
            if percent and speed then
              local progress = tonumber(percent) or 0
              local message = string.format("Downloading backend... %d%% (%s)", progress, speed)
              if progress_callback then progress_callback { progress = progress, message = message } end
            end
          end
        end
      end
    end),
    on_stderr = vim.schedule_wrap(function(_, data, _)
      if not data then return end
      for _, line in ipairs(data) do
        local code = line:match("HTTP/%S+%s+(%d+)")
        if code then http_code = tonumber(code) end
      end
    end),
    on_exit = vim.schedule_wrap(function(_, exit_code, _)
      if exit_code ~= 0 then
        Logger.error("Download failed with exit code: " .. tostring(exit_code))
        -- Clean up partial download if it exists
        if vim.fn.filereadable(output_path) == 1 then vim.fn.delete(output_path) end
        if callback then callback(false, http_code) end
        return
      end

      -- Verify the file was actually downloaded
      local f = io.open(output_path, "r")
      if not f then
        Logger.error("Downloaded file not found at: " .. output_path)
        if callback then callback(false, http_code) end
        return
      end
      f:close()
      make_executable(output_path)
      if progress_callback then progress_callback { progress = 100, message = "Download completed!" } end
      Logger.notify(Globals.KULALA_CORE_BINARY_NAME .. " backend downloaded successfully!", Logger.LoggerLogLevels.info)
      if callback then callback(true) end
    end),
    stdout_buffered = false,
    stderr_buffered = false,
  })
end

---Download a file using curl with progress parsing
---@param url string URL to download from
---@param output_path string Path to save the file to
---@param progress_callback function|nil Optional callback for progress updates: {progress: number, message: string}
---@param callback function|nil Optional callback to run after download completes (receives success: boolean)
local function download_via_curl(url, output_path, progress_callback, callback, token)
  local config = require("kulala.config").get()
  local header_path = output_path .. ".headers"
  -- Use curl with simple progress bar (#) that outputs to stderr
  -- Format: %{url_effective}\n%{size_download}\n%{size_total}\n%{speed_download}\n%{time_total}
  -- We'll parse this to show percentage
  local cmd = {
    config.kulala_core.download_tool,
    "-fL",
    "-#", -- Simple progress bar (easier to parse than --progress-bar)
    "-H",
    "Authorization: Bearer " .. token,
    "-D",
    header_path,
    "--write-out",
    "%{url_effective}\n%{size_download}\n%{size_total}\n%{speed_download}\n%{time_total}\n",
    "-o",
    output_path,
    url,
  }

  local last_progress = 0
  local max_progress_shown = 0 -- Track the highest progress we've actually shown to user
  local download_completed = false
  local final_stats = nil
  local progress_100_reported = false
  local debounce_timer = nil
  local pending_progress = nil
  local last_stderr_progress = 0
  local first_progress_shown = false
  local last_update_time = 0

  -- Throttled progress callback (max once every 3 seconds, but show first immediately)
  local function report_progress(progress_data)
    -- Immediately stop processing if we've already completed
    if download_completed or progress_100_reported then return end

    -- Ignore any progress lower than what we've already shown (prevents showing stale low values)
    if progress_data.progress and progress_data.progress < max_progress_shown then return end

    -- If this is 100%, mark as completed immediately to prevent further updates
    if progress_data.progress and progress_data.progress >= 100 then
      download_completed = true
      progress_100_reported = true
      max_progress_shown = 100
      -- Report immediately, no throttle for completion
      if progress_callback then progress_callback(progress_data) end
      -- Stop any pending timer
      if debounce_timer then
        vim.fn.timer_stop(debounce_timer)
        debounce_timer = nil
      end
      pending_progress = nil
      return
    end

    -- Show first progress update immediately
    if not first_progress_shown then
      if progress_callback then
        progress_callback(progress_data)
        max_progress_shown = progress_data.progress or 0
        first_progress_shown = true
        last_update_time = vim.fn.reltime()
      end
      return
    end

    -- For subsequent updates, check if 3 seconds have passed
    local current_time = vim.fn.reltime()
    local elapsed = vim.fn.reltimefloat(vim.fn.reltime(last_update_time, current_time))

    if elapsed >= 3.0 then
      -- 3 seconds have passed, show update immediately
      if progress_callback then
        progress_callback(progress_data)
        max_progress_shown = math.max(max_progress_shown, progress_data.progress or 0)
        last_update_time = current_time
      end
      -- Clear any pending timer
      if debounce_timer then
        vim.fn.timer_stop(debounce_timer)
        debounce_timer = nil
      end
      pending_progress = nil
    else
      -- Less than 3 seconds, queue for later
      pending_progress = progress_data
      -- Clear existing timer
      if debounce_timer then vim.fn.timer_stop(debounce_timer) end
      -- Set timer to report after remaining time (or at least 3 seconds total)
      local remaining_time = math.ceil((3.0 - elapsed) * 1000)
      debounce_timer = vim.fn.timer_start(remaining_time, function()
        -- Double-check we haven't completed while timer was waiting
        if download_completed or progress_100_reported then
          pending_progress = nil
          return
        end
        -- Double-check the progress is still valid (not stale)
        if pending_progress and pending_progress.progress and pending_progress.progress >= max_progress_shown then
          if progress_callback then
            progress_callback(pending_progress)
            max_progress_shown = math.max(max_progress_shown, pending_progress.progress)
            last_update_time = vim.fn.reltime()
          end
        end
        pending_progress = nil
      end)
    end
  end

  local job_id = vim.fn.jobstart(cmd, {
    env = vim.fn.environ(),
    on_stdout = vim.schedule_wrap(function(_, data, _)
      -- Stop processing if we've already completed
      if download_completed or progress_100_reported then return end

      -- Parse the write-out data from stdout (only available at the end)
      if data and #data > 0 then
        local lines = {}
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(lines, line) end
        end
        if #lines >= 5 then
          local size_download = tonumber(lines[2]) or 0
          local size_total = tonumber(lines[3]) or 0
          local speed = tonumber(lines[4]) or 0

          -- Store final stats for use in on_exit
          final_stats = {
            size_download = size_download,
            size_total = size_total,
            speed = speed,
          }

          -- Only report if we haven't completed yet and have valid data
          if size_total > 0 and not download_completed and not progress_100_reported then
            local progress = math.floor((size_download / size_total) * 100)
            -- Only report if progress increased and is higher than what we've shown
            -- This prevents showing stale low values
            if progress > last_progress and progress >= max_progress_shown then
              -- Cap at 99% to avoid showing 100% multiple times (let on_exit handle final 100%)
              progress = math.min(99, progress)
              local speed_mb = speed / 1024 / 1024
              local message = string.format("Downloading backend... %d%% (%.2f MB/s)", progress, speed_mb)
              report_progress { progress = progress, message = message }
              last_progress = progress
            end
          end
        end
      end
    end),
    on_stderr = vim.schedule_wrap(function(_, data, _)
      -- Parse curl's -# progress bar from stderr for real-time updates
      -- Format: "##..." where each # represents ~2% progress (50 # = 100%)
      -- Note: curl uses \r (carriage return) to overwrite the same line, so we need to
      -- extract the last progress state after splitting by \r
      -- Stop processing if we've already completed
      if download_completed or progress_100_reported then return end

      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= "" then
            -- First, check if line contains 100% (completion indicator)
            if line:match("100%.?0?%%") then
              -- This is 100%, report it immediately
              if not download_completed and not progress_100_reported then
                report_progress {
                  progress = 100,
                  message = "Downloading backend... 100%",
                }
              end
              return
            end

            -- Split by carriage return to get the last progress state
            -- curl overwrites the same line with \r, so the last segment is current state
            local segments = vim.split(line, "\r", { trimempty = true })
            local last_segment = segments[#segments] or line

            -- Count # characters in the last segment only (current progress state)
            local hash_count = 0
            for _ in last_segment:gmatch("#") do
              hash_count = hash_count + 1
            end

            -- Simple progress bar has ~50 # characters for 100%
            if hash_count > 0 then
              local estimated_progress = math.min(99, math.floor((hash_count / 50) * 100))
              -- Only update if progress increased (not decreased) and is higher than what we've shown
              -- This prevents showing stale low percentages after we've shown high progress
              if
                estimated_progress > last_stderr_progress
                and estimated_progress >= max_progress_shown
                and estimated_progress < 100
              then
                -- Double-check we haven't completed
                if not download_completed and not progress_100_reported then
                  report_progress {
                    progress = estimated_progress,
                    message = string.format("Downloading backend... %d%%", estimated_progress),
                  }
                  last_stderr_progress = estimated_progress
                end
              end
            end
          end
        end
      end
    end),
    on_exit = vim.schedule_wrap(function(_, exit_code, _)
      -- Mark as completed immediately to prevent any further progress updates
      download_completed = true

      -- Stop any pending debounce timer
      if debounce_timer then
        vim.fn.timer_stop(debounce_timer)
        debounce_timer = nil
      end
      -- Don't flush pending progress - it might be stale (low values from stderr)
      -- Just clear it
      pending_progress = nil
      local http_code = read_http_status(header_path)

      if exit_code ~= 0 then
        Logger.error("Download failed with exit code: " .. tostring(exit_code))
        -- Clean up partial download if it exists
        if vim.fn.filereadable(output_path) == 1 then vim.fn.delete(output_path) end
        if callback then callback(false, http_code) end
        return
      end

      -- Verify the file was actually downloaded
      local f = io.open(output_path, "r")
      if not f then
        Logger.error("Downloaded file not found at: " .. output_path)
        if callback then callback(false, http_code) end
        return
      end
      f:close()
      make_executable(output_path)
      -- Report completion only if we haven't already reported 100%
      if progress_callback and not progress_100_reported then
        if final_stats and final_stats.size_total > 0 then
          local speed_mb = (final_stats.speed or 0) / 1024 / 1024
          progress_callback { progress = 100, message = string.format("Download completed! (%.2f MB/s)", speed_mb) }
        else
          progress_callback { progress = 100, message = "Download completed!" }
        end
        progress_100_reported = true
      end
      Logger.notify(Globals.KULALA_CORE_BINARY_NAME .. " backend downloaded successfully!", Logger.LoggerLogLevels.info)
      if callback then callback(true) end
    end),
    stdout_buffered = false,
    stderr_buffered = false,
  })

  if job_id <= 0 then
    Logger.error("Failed to start download process")
    if callback then callback(false) end
  end
end

---Download a file asynchronously with progress display
---@param url string URL to download from
---@param output_path string Path to save the file to
---@param progress_callback function|nil Optional callback for progress updates: {progress: number, message: string}
---@param callback function|nil Optional callback to run after download completes (receives success: boolean)
local function download_file_async(url, output_path, progress_callback, callback, token)
  if not token or token == "" then
    Logger.error("KULALA_CORE_LICENSE_TOKEN is not set. Set it to download kulala-core.")
    if callback then callback(false) end
    return
  end

  local config = require("kulala.config").get()
  local download_tool = config.kulala_core.download_tool or "curl"
  -- check if download_tool has "curl" or "wget" in it
  local downloader
  if download_tool:match("curl") and vim.fn.executable(download_tool) == 1 then
    downloader = "curl"
  else
    if download_tool:match("wget") and vim.fn.executable(download_tool) == 1 then
      downloader = "wget"
    else
      Logger.error("Neither curl nor wget is available. Please install one of these tools to download the backend.")
      if callback then callback(false) end
      return
    end
  end

  if downloader == "curl" then
    download_via_curl(url, output_path, progress_callback, callback, token)
  else
    download_via_wget(url, output_path, progress_callback, callback, token)
  end
end

---Check if binary exists
---@return boolean exists Whether the binary file exists
local function binary_exists()
  local bin_path = M.get_bin_path()
  local f = io.open(bin_path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

---Get the required backend version tag (without "v" prefix)
---@return string version_tag Version tag like "1.0.0"
local function get_required_version()
  return Globals.BACKEND_VERSION
end

---Check if the installed version matches the required version
---@return boolean matches True if versions match, false otherwise
local function version_matches()
  local config = require("kulala.config").get()
  if config.kulala_core.path and config.kulala_core.path ~= "" then return true end

  local installed = M.get_installed_version()
  if not installed then return false end
  local required = get_required_version()
  return installed == required
end

---Manually install the backend binary
---@param version string|nil Version tag to install (e.g., "v1.0.0"), defaults to "latest"
---@param callback function|nil Optional callback to run after installation
M.install = function(version, callback)
  version = version or get_required_version()
  if version == "latest" then version = get_required_version() end
  version = version:gsub("^v", "")
  local download_url = require("kulala.config").get().kulala_core.download_url
  local url = string.format(download_url, version, M.get_release_bin_name())
  Logger.info("Downloading backend from URL: " .. url)

  local token, token_source = resolve_license_token()
  if not token then token = prompt_license_token() end
  if not token then
    if callback then callback(false) end
    return
  end

  local bin_dir = M.get_bin_dir()
  vim.fn.mkdir(bin_dir, "p")

  -- Download to temporary archive file
  local download_file_path = join_paths(bin_dir, M.get_release_bin_name() .. ".download")

  -- Start timing from the beginning of download
  local start_time = vim.fn.reltime()

  -- Create progress handlers for download and extraction
  local download_progress, download_finish =
    Notify.create_progress_handler(Globals.KULALA_CORE_BINARY_NAME .. ": Downloading")

  local retried = false
  local function on_download(download_success, http_code)
    -- Keep a saved token across updates. Drop it only when the server rejects it.
    if not download_success and (http_code == 401 or http_code == 403) and not retried then
      retried = true
      if token_source ~= "env" then delete_saved_license_token() end
      local next_token = prompt_license_token()
      if not next_token then
        download_finish("Download failed")
        Logger.error("Kulala Core license token was rejected. Set KULALA_CORE_LICENSE_TOKEN to download kulala-core.")
        if callback then callback(false) end
        return
      end
      token = next_token
      token_source = "prompt"
      download_file_async(url, download_file_path, download_progress, on_download, token)
      return
    end

    -- Only proceed with extraction if download succeeded
    if not download_success then
      download_finish("Download failed")
      Logger.error("Download failed. Cannot proceed with installation.")
      if callback then callback() end
      return
    end

    download_finish("Download completed")

    -- Calculate total elapsed time
    local elapsed = vim.fn.reltime(start_time)
    local elapsed_seconds = vim.fn.reltimefloat(elapsed)
    local minutes = math.floor(elapsed_seconds / 60)
    local seconds = math.floor(elapsed_seconds % 60)
    local milliseconds = math.floor((elapsed_seconds % 1) * 1000)

    local time_str
    if minutes > 0 then
      time_str = string.format("%dm %d.%03ds", minutes, seconds, milliseconds)
    else
      time_str = string.format("%d.%03ds", seconds, milliseconds)
    end

    local bin_path = join_paths(bin_dir, M.get_bin_name())
    if vim.fn.filereadable(download_file_path) == 1 then
      -- make it executable
      if not IS_WINDOWS then vim.fn.system { "chmod", "+x", download_file_path } end
      -- Rename the downloaded file
      vim.fn.rename(download_file_path, bin_path)
    else
      Logger.error("Downloaded file not found at expected location: " .. download_file_path)
      if callback then callback(false) end
      return
    end

    probe_installed_binary(bin_path, function(ok)
      if not ok then
        report_launch_failure(bin_path)
        if callback then callback(false) end
        return
      end

      Logger.notify(string.format("Backend installed successfully in %s!", time_str), Logger.LoggerLogLevels.info)
      -- Set the installed version after the binary has actually started.
      set_installed_version(version)
      require("kulala.config").set_autocomands()
      require("kulala.cmd.lsp").restart_all()
      if callback then callback() end
    end)
  end

  download_file_async(url, download_file_path, download_progress, on_download, token)
end

M.is_up_to_date = function()
  return binary_exists() and version_matches()
end

local install_inflight = false
local install_waiters = {}

local function finish_install(callback)
  install_inflight = false
  local waiters = install_waiters
  install_waiters = {}

  if binary_exists() and version_matches() then
    if Parser.is_up_to_date() then Api.trigger("ready") end
  else
    Logger.error("Backend installation failed or binary is not accessible")
  end

  if callback then callback() end
  for _, waiter in ipairs(waiters) do
    waiter()
  end
end

---Ensure the backend binary is installed and up-to-date
---If development mode is enabled, skip the check (assumes running from source)
---If binary is not found or version doesn't match, download the required version
---Concurrent callers share one download and one license prompt.
---@param callback function|nil Optional callback to run after installation
M.ensure_installed = function(callback)
  local required_version = get_required_version()

  -- Check if binary exists and version matches
  if binary_exists() and version_matches() then
    if callback then callback() end
    return
  end

  if install_inflight then
    if callback then table.insert(install_waiters, callback) end
    return
  end

  install_inflight = true

  -- Determine reason for download
  local reason
  if not binary_exists() then
    reason = "Backend not found"
  else
    local installed = M.get_installed_version() or "unknown"
    reason = string.format("Version mismatch (installed: %s, required: %s)", installed, required_version)
  end

  Logger.notify(string.format("%s. Downloading %s...", reason, required_version), Logger.LoggerLogLevels.info)
  M.install(required_version, function()
    finish_install(callback)
  end)
end

return M
