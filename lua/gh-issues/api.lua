local M = {}

local config = require("gh-issues").config

---@param remote? string defaults to config.repository if not provided
M.open_issues = function(remote)
    local issue = require("gh-issues.issue");
    local data = issue.fetch(remote ~= "" and remote or config.repository)
    if not data then return end
    require("gh-issues.quickfix").populate_issues(data)
end
---@param remote? string defaults to config.repository if not provided
M.open_pull_request = function(remote)
    local pull_request = require("gh-issues.pull_request")
    local data = pull_request.fetch(remote ~= "" and remote or config.repository)
    if not data then return end
    require("gh-issues.quickfix").populate_issues(data)
end

M.clear_markers = function()
    require("gh-issues.ui.diagnostics").clear()
    vim.notify("Markers cleaned", vim.log.levels.INFO)
end

return M
