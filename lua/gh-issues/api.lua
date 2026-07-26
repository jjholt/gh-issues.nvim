local M = {}

local config = require("gh-issues").config

---@param repository? string defaults to config.repository if not provided
M.open_issues = function(repository)
    local issue = require("gh-issues.issue")
    issue.list_all(repository ~= "" and repository or config.repository)
end
---@param repository? string defaults to config.repository if not provided
M.open_pull_request = function(repository)
    local pull_request = require("gh-issues.pull_request")
    pull_request.list_all(repository ~= "" and repository or config.repository)
end

M.clean_cache = function()
    require("gh-issues.cache").invalidate_all()
    vim.notify("Cleaning cache", vim.log.levels.INFO)
end

return M
