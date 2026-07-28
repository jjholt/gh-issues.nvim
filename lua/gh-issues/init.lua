---@class gh-issues.Keybinds
---@field issues string
---@field pull_request string
---@field clear_markers string
---@field add_to_quickfix string
---@field nav_review_comments string[]

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
        clear_markers = "<leader>gc",
        add_to_quickfix = "<C-a>",
        nav_review_comments = {"]c", "[c"},
    },
    repository = "origin",
    accounts = nil
}

M.config = default_config

---@param opts? gh-issues.Config
M.setup = function(opts)
    M.config = vim.tbl_deep_extend("force", default_config, opts or {})

    local kb = M.config.keybinds
    local api = require("gh-issues.api")
    vim.keymap.set("n", kb.issues, api.open_issues, {desc = "Populate issues into quickfix list"})
    vim.keymap.set("n", kb.pull_request, api.open_pull_request, {desc = "Populate pull requests into quickfix list"})
    vim.keymap.set("n", kb.clear_markers, api.clear_markers, {desc = "Clear all diagnostic markers from source"})
end

return M
