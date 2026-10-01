local M = {}

---Git location variables override `cwd`. Grammar fetch must use the directory
---we pass in, even when Neovim was started with `GIT_DIR` set (for example yadm).
local GIT_ENV_KEYS = {
  "GIT_DIR",
  "GIT_WORK_TREE",
  "GIT_INDEX_FILE",
  "GIT_OBJECT_DIRECTORY",
  "GIT_COMMON_DIR",
  "GIT_PREFIX",
}

local function git_env()
  local env = vim.fn.environ()
  for _, key in ipairs(GIT_ENV_KEYS) do
    env[key] = nil
  end
  return env
end

M.git = function(cwd, args, on_exit)
  -- `env` replaces the process environment, so start from the current one.
  vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, env = git_env() }, function(res)
    vim.schedule(function()
      on_exit(res)
    end)
  end)
end

return M
