local Json = require("kulala.utils.json")
local Logger = require("kulala.logger")

local M = {}

M.get_current_buffer = function()
  return require("kulala.db").get_current_buffer()
end

---Get the OS
---@return "windows" | "mac" | "unix" | "unknown"
M.get_os = function()
  if vim.fn.has("unix") == 1 then return "unix" end
  if vim.fn.has("mac") == 1 then return "mac" end
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") then return "windows" end

  return "unknown"
end

---The OS
---@type "windows" | "mac" | "unix" | "unknown"
M.os = M.get_os()

---Get the path separator for the current OS
---@return "\\" | "/"
M.get_path_separator = function()
  if M.os == "windows" then return "\\" end
  return "/"
end

---Path separator
---@type "\\" | "/"
M.ps = M.os == "windows" and "\\" or "/"

M.normalize_path = function(path)
  path = vim.fs.normalize(path)
  if M.os ~= "windows" then return path end

  path = path:gsub("/", "\\")
  return path
end

---Join paths -- similar to os.path.join in python
M.join_paths = function(...)
  local parts = { ... }
  local replace_ps = M.os == "windows" and "/" or "\\"

  for i, part in ipairs(parts) do
    parts[i] = part:gsub(replace_ps, M.ps)
  end

  return table.concat(parts, M.ps)
end

---Returns true if the path is absolute, false otherwise
M.is_absolute_path = function(path)
  -- Unix: /path, Windows: C:\ or C:/ (when shellslash is set)
  return path:match("^/") or path:match("^%a:\\") or path:match("^%a:/")
end

---Either returns the absolute path if the path is already absolute or
---joins the path with the current buffer directory
---@param path string
---@param root string|nil -- root directory
M.get_file_path = function(path, root)
  local ex_path = vim.fn.expand(path, true)
  path = ex_path ~= "" and ex_path or path
  root = root and vim.fn.fnamemodify(root, ":h")

  if M.is_absolute_path(path) then return path end
  if path:sub(1, 2) == "./" or path:sub(1, 2) == ".\\" then path = path:sub(3) end

  return M.join_paths(root or M.get_current_buffer_dir(), path)
end

-- This is mainly used for determining if the current buffer is a non-http file
-- and therefore maybe we need to parse a fenced code block
M.is_non_http_file = function()
  local buf = M.get_current_buffer()

  local extensions = { "http", "rest" }
  local ft = vim.bo[buf].filetype
  local ext = vim.fn.fnamemodify(M.get_current_buffer_path(), ":e")

  return vim.iter(extensions):all(function(e)
    return ext ~= e and ft ~= e
  end)
end

---Check if the buffer file name ends with
---.http.js or .http.ts or .http.lua
---@param ft string filetype
---@param buf? number buffer to check; defaults to kulala current buffer
---@return boolean
M.is_http_script_file = function(ft, buf)
  local script_filetypes = { "javascript", "typescript", "lua" }
  if not vim.tbl_contains(script_filetypes, ft) then return false end
  local path = buf and vim.api.nvim_buf_get_name(buf) or M.get_current_buffer_path()
  local extensions = { "js", "ts", "lua" }
  local ext = vim.fn.fnamemodify(path, ":e")
  local base = vim.fn.fnamemodify(path, ":t:r")
  local enforce_external_script_naming_convention =
    require("kulala.config").get().lsp.enforce_external_script_naming_convention
  if not enforce_external_script_naming_convention then return true end
  for _, e in ipairs(extensions) do
    if ext == e and base:match("%.http$") then return true end
  end
  return false
end

-- find nearest file in parent directories, starting from the current buffer file path
--- @param filename string|function
--- @return string|nil
--- @usage local p = fs.find_file_in_parent_dirs('Makefile')
M.find_file_in_parent_dirs = function(filename)
  return vim.fs.find(filename, {
    upward = true,
    limit = 1,
    path = M.get_current_buffer_dir(),
  })[1]
end

--- find all files with given name in parent directories, starting from the current buffer file path
--- @param filename string
--- @param root string|nil -- root marker, default {".git", ".gitignore"}
--- @return string[]
M.find_files_in_parent_dirs = function(filename, root)
  local cwd = M.get_current_buffer_dir()
  root = root or vim.fs.root(cwd, { ".git", ".gitignore" })
  root = root and (root .. "/..") or "/"

  return vim.fs.find(filename, {
    path = cwd,
    upward = true,
    type = "file",
    limit = math.huge,
    stop = root,
  })
end

M.copy_file = function(source, destination)
  return vim.uv.fs_copyfile(source, destination, 0)
end

---Get the current buffer directory or current working dir if path is not valid
---@return string
M.get_current_buffer_dir = function()
  -- Get the full path of the current buffer
  local buf_path = M.get_current_buffer_path()
  buf_path = vim.fn.filereadable(buf_path) ~= 0 and buf_path or vim.uv.cwd()

  -- Extract the directory part from the buffer path
  return vim.fn.fnamemodify(buf_path, ":p:h")
end

M.get_current_buffer_path = function()
  local buf = M.get_current_buffer()
  return buf and vim.api.nvim_buf_get_name(buf)
end

---Get UUID
---@return string
---@usage local p = fs.get_uuid()
M.get_uuid = function()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  local res = string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format("%x", v)
  end)

  return res
end

---Get the directory of a file path
---@param filepath string
---@return string
M.get_dir_by_filepath = function(filepath)
  return vim.fn.fnamemodify(filepath, ":h")
end

---Get all http and rest files in given path or current buffer directory
--- @param path string|nil
M.find_all_http_files = function(path)
  path = vim.fn.isdirectory(path) == 1 and path or M.get_current_buffer_dir()

  return vim.fs.find(function(name)
    return name:match("%.http$") or name:match("%.rest$")
  end, { path = path, type = "file", limit = 1000 })
end

-- Writes string to file
--- @param filename string
--- @param content string
--- @param append boolean|nil
--- @param binary boolean|nil
--- @usage fs.write_file('Makefile', 'all: \n\t@echo "Hello World"')
--- @usage fs.write_file('Makefile', 'all: \n\t@echo "Hello World"', true)
--- @return boolean
--- @usage local p = fs.write_file('Makefile', 'all: \n\t@echo "Hello World"')
M.write_file = function(filename, content, append, binary)
  local f, mode

  mode = append and "a" or "w"
  mode = binary and mode .. "b" or mode

  filename = M.get_file_path(filename)

  f = io.open(filename, mode)
  if not f then return false end

  f:write(content)
  f:close()

  return true
end

-- Delete a file
--- @param filename string
--- @return boolean
--- @usage local p = fs.delete_file('Makefile')
M.delete_file = function(filename)
  return vim.fn.delete(filename) ~= 0
end

-- Check if a file exists
--- @param filename string
--- @return boolean
--- @usage local p = fs.file_exists('Makefile')
M.file_exists = function(filename)
  return vim.fn.filereadable(filename) == 1
end

-- Check if a directory exists
--- @param dir string
--- @return boolean
--- @usage local p = fs.dir_exists('.cache')
M.dir_exists = function(dir)
  return vim.fn.isdirectory(dir) == 1
end

-- INFO:
-- We're using robocopy for Windows,
-- since it should work on all modern Windows versions (7, 8, 8.1, 10, and 11)
-- and is optimized for copying directories with many files and subdirectories.
-- What do the flags do?
-- /E copies all subdirectories (including empty ones)
-- /R:0 and /W:0 skip retries for locked files so Neovim doesn't hang
-- We're not passing /MIR or /PURGE to avoid accidentally deleting files in
-- the destination that don't exist in the source

M.copy_dir = function(source, destination)
  if M.os == "unix" or M.os == "mac" then
    vim.system({ "cp", "-r", source .. M.ps .. ".", destination }):wait()
  elseif M.os == "windows" then
    vim.system({ "robocopy", source, destination, "/E", "/R:0", "/W:0" }):wait()
  end
end

M.copy_dir_contents = function(source, destination)
  if M.os == "unix" or M.os == "mac" then
    vim.system({ "cp", "-r", source .. M.ps .. ".", destination }):wait()
  elseif M.os == "windows" then
    vim.system({ "robocopy", source, destination, "/E", "/R:0", "/W:0" }):wait()
  end
end

M.ensure_dir_exists = function(dir)
  if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
end

-- Get plugin tmp directory
--- @return string
--- @usage local p = fs.get_plugin_tmp_dir()
M.get_plugin_tmp_dir = function()
  local cache = vim.fn.stdpath("cache")
  ---@cast cache string
  local dir = M.join_paths(cache, "kulala")

  M.ensure_dir_exists(dir)
  return dir
end

M.get_scripts_dir = function()
  local dir = M.join_paths(M.get_plugin_root_dir(), "parser", "scripts")
  return dir
end

---Delete all files in a directory, except hidden files (starting with .)
---@param dir string
---@param skip_files? string[]
---@return string[] deleted_files
M.delete_files_in_directory = function(dir, skip_files)
  local deleted_files = {}
  local scandir = vim.uv.fs_scandir(dir)

  if not scandir then
    Logger.error("Error opening directory: " .. dir)
    return {}
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(scandir)

    if not name then break end

    if type == "file" and not name:match("^%.") and not vim.tbl_contains(skip_files or {}, name) then
      local filepath = M.join_paths(dir, name)
      local success, err = vim.uv.fs_unlink(filepath)

      if not success then
        Logger.error("Error deleting file: " .. filepath .. ": " .. err)
      else
        table.insert(deleted_files, filepath)
      end
    end
  end

  return deleted_files
end

-- Check if a command is available
--- @param cmd string
--- @return boolean
--- @usage local p = fs.command_exists('ls')
M.command_exists = function(cmd)
  return vim.fn.executable(cmd) == 1
end

M.make_executable = function(file)
  return M.os ~= "windows" and os.execute("chmod +x " .. file)
end

M.command_path = function(cmd)
  return vim.fn.exepath(cmd)
end

M.get_plugin_root_dir = function()
  local source = debug.getinfo(1).source
  local dir_path = source:match("@(.*/)") or source:match("@(.*\\)")

  if not dir_path then return end

  return vim.fs.normalize(dir_path .. "..")
end

---Gets a directory path for the plugin
---@param paths string[]
---@return string
M.get_plugin_path = function(paths)
  local root = M.get_plugin_root_dir()
  root = paths and #paths > 0 and (root .. M.ps .. table.concat(paths, M.ps)) or root

  return vim.fs.normalize(root)
end

---Read a file with path absolute or relative to buffer dir
---@param filename string path absolute or relative to buffer dir
---@param is_binary boolean|nil
---@return string|nil
---@usage local p = fs.read_file('Makefile')
M.read_file = function(filename, is_binary)
  if not filename then return end
  local read_mode = is_binary and "rb" or "r"

  filename = M.get_file_path(filename)
  local f = io.open(filename, read_mode)

  if not f then return end

  local content = f:read("*a")
  if not content then return end

  content = is_binary and content or content:gsub("\r\n", "\n")
  f:close()

  return content
end

---Read JSON from file
---@param filename string path absolute or relative to buffer dir
---@param opts? table<{ verbose: boolean, luanil: table<{object: boolean, array: boolean }> }> -- verbose: log errors
M.read_json = function(filename, opts)
  local content = M.read_file(filename)
  content = content == "" and "{}" or content
  return content and Json.parse(content, opts, filename)
end

---Write JSON to file
---@param filename string
---@param data table
---@param format_opts table|boolean|nil -- {verbose|escape|sort}
M.write_json = function(filename, data, format_opts)
  data = next(data) and data or { _ = "" }

  format_opts = format_opts and format_opts == true and {}
  format_opts = format_opts and vim.tbl_extend("keep", format_opts, { escape = false })

  local content = vim.json.encode(data)
  if not content then return end

  if format_opts then
    local response_format = require("kulala.config").get().response_format or {}
    local KULALA_CORE = require("kulala.cmd.kulala_core_bridge")
    if KULALA_CORE.enabled() then
      local expand_tabs = format_opts.expand_tabs
      if type(expand_tabs) ~= "boolean" then expand_tabs = response_format.expand_tabs end
      local formatted = KULALA_CORE.format_json(data, {
        indent = format_opts.indent or response_format.indent,
        expand_tabs = expand_tabs,
        sort_keys = format_opts.sort or format_opts.sort_keys or response_format.sort_keys,
      })
      if type(formatted) == "string" then content = formatted end
    end
  end

  return M.write_file(filename, content)
end

---@param content string
---@param binary? boolean|nil
---@return string|nil path to the temp file
M.get_temp_file = function(content, binary)
  local tmp_file = vim.fn.tempname()
  local mode = binary and "wb" or "w"
  local f = io.open(tmp_file, mode)

  if not f then return end

  f:write(content)
  f:close()

  return tmp_file
end

M.get_binary_temp_file = function(content)
  return M.get_temp_file(content, true)
end

---Read file lines
---@param filename string
---@return string[]
M.read_file_lines = function(filename)
  local f = io.open(filename, "r")
  local lines = {}

  if not f then return {} end

  for line in f:lines() do
    table.insert(lines, line)
  end

  f:close()

  return lines
end

---Includes contents of path into the file
---@param file file* handle to file to append to
---@param path string path of file to include
M.include_file = function(file, path)
  path = M.get_file_path(path)

  local status = true
  local BUFSIZE = 2 ^ 13 -- 8K

  local file_to_include = io.open(path, "rb")
  if not file_to_include then return end

  while true do
    local chunk = file_to_include:read(BUFSIZE)
    if not chunk then break end
    ---@diagnostic disable-next-line: cast-local-type
    status = status and file:write(chunk)
  end

  return status and file_to_include:close()
end

---Deletes cached files: request.json and script output
M.delete_cached_files = function(silent) -- .cache/nvim/kulala
  local tmp_dir = M.get_plugin_tmp_dir()
  local skip_files = { "cookies.txt" }
  local deleted_files = M.delete_files_in_directory(tmp_dir, skip_files)

  if silent then return end

  local list = vim.iter(deleted_files):fold("", function(acc, file)
    return acc .. "- " .. file .. "\n"
  end)

  Logger.info("Deleted files:\n" .. list)
end

return M
