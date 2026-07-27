local M = {}

local config = require("gh-issues").config

---@param remote? string defaults to config.repository if not provided
M.open_issues = function(remote)
    local issue = require("gh-issues.issue");
    local data = issue.fetch(remote ~= "" and remote or config.repository)
    if not data then return end
    require("gh-issues.quickfix").populate(data)
end
---@param remote? string defaults to config.repository if not provided
M.open_pull_request = function(remote)
    local pull_request = require("gh-issues.pull_request")
    local data = pull_request.fetch(remote ~= "" and remote or config.repository)
    if not data then return end
    require("gh-issues.quickfix").populate(data)
end

M.clean_cache = function()
    require("gh-issues.cache").invalidate_all()
    vim.notify("Cleaning cache", vim.log.levels.INFO)
end

return M
