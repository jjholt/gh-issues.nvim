---@class gh-issues.Keybinds
---@field issues string
---@field pull_request string
---@field clean_cache string
---@field add_to_quickfix string

---@class gh-issues.Config
---@field keybinds gh-issues.Keybinds
---@field repository string
---@field accounts table<string, string>|nil -- ssh alias = github username

---@class gh-issues
---@field config gh-issues.Config
---@field setup fun(opts?: gh-issues.Config)
local M = {}

---@type gh-issues.Config
local default_config = {
    keybinds = {
        issues = "<leader>gi",
        pull_request = "<leader>gpr",
        clean_cache = "<leader>gc",
        add_to_quickfix = "<C-a>",
    },
    repository = "origin",
    accounts = nil
}

M.config = default_config

---@param opts? gh-issues.Config
M.setup = function(opts)
    M.config = vim.tbl_deep_extend("force", default_config, opts or {})
end

return M
