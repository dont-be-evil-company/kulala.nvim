local CONFIG = require("kulala.config")

local M = {}

M.ns = vim.api.nvim_create_namespace("kulala_graphql_explorer")

function M.setup()
  local hl = CONFIG.get().graphql_panel and CONFIG.get().graphql_panel.highlights or {}
  vim.api.nvim_set_hl(0, "KulalaGraphQLRoot", { link = hl.root or "Title", default = true })
  vim.api.nvim_set_hl(0, "KulalaGraphQLField", { link = hl.field or "Function", default = true })
  vim.api.nvim_set_hl(0, "KulalaGraphQLArg", { link = hl.arg or "Identifier", default = true })
  vim.api.nvim_set_hl(0, "KulalaGraphQLType", { link = hl.type or "Type", default = true })
  vim.api.nvim_set_hl(0, "KulalaGraphQLBadge", { link = hl.badge or "Special", default = true })
  vim.api.nvim_set_hl(0, "KulalaGraphQLDescription", { link = hl.description or "Comment", default = true })
  vim.api.nvim_set_hl(0, "KulalaGraphQLChecked", { link = hl.checked or "String", default = true })
  vim.api.nvim_set_hl(0, "KulalaGraphQLHeader", { link = hl.header or "Comment", default = true })
  vim.api.nvim_set_hl(0, "KulalaGraphQLValue", { link = hl.value or "Constant", default = true })
end

---@param bufnr integer
---@param lines string[]
---@param line_map table[]
function M.apply(bufnr, lines, line_map)
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
  local set_hl = vim.fn.has("nvim-0.11") == 1 and vim.hl.range or vim.highlight.range
  for row, node in ipairs(line_map) do
    local line = lines[row] or ""
    local row0 = row - 1
    local function span(pattern, group)
      local start_col, end_col = line:find(pattern)
      if not start_col then return end
      pcall(set_hl, bufnr, M.ns, group, { row0, start_col - 1 }, { row0, end_col })
    end
    if node.kind == "header" or node.kind == "text" then
      pcall(
        set_hl,
        bufnr,
        M.ns,
        node.kind == "text" and "KulalaGraphQLDescription" or "KulalaGraphQLHeader",
        { row0, 0 },
        { row0, #line }
      )
    elseif node.kind == "root" then
      pcall(set_hl, bufnr, M.ns, "KulalaGraphQLRoot", { row0, 0 }, { row0, #line })
    else
      local _, box_end = line:find("%[[x ]%]")
      span("%[[x ]%]", "KulalaGraphQLChecked")
      if box_end then
        local type_start, type_end = line:find("%[[^%]]+%]", box_end + 1)
        if type_start then
          pcall(set_hl, bufnr, M.ns, "KulalaGraphQLType", { row0, type_start - 1 }, { row0, type_end })
        end
      end
      span(" ARG", "KulalaGraphQLBadge")
      span(" required", "KulalaGraphQLBadge")
      span(" = .+$", "KulalaGraphQLValue")
      if node.kind == "arg" then
        span(vim.pesc(node.name or ""), "KulalaGraphQLArg")
      else
        span(vim.pesc(node.name or ""), "KulalaGraphQLField")
      end
    end
  end
end

return M
