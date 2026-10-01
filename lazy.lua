return {
  "dont-be-evil-company/kulala.nvim",
  ft = { "http", "rest" },
  -- Load when a session is restored so the SessionLoadPost hook can run.
  -- VimLeavePre is not a load trigger: the save hook is an autocmd registered
  -- from setup, and loading the plugin on exit would run grammar git commands
  -- against whatever GIT_DIR the parent process set.
  event = { "SessionLoadPost" },
  opts = {},
}
