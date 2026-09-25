return {
  "dont-be-evil-company/kulala.nvim",
  ft = { "http", "rest" },
  -- Load before session save/restore so VimLeavePre and SessionLoadPost hooks are registered.
  event = { "SessionLoadPost", "VimLeavePre" },
  opts = {},
}
