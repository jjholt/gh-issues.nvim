local M = {}

local ui = require("gh-issues.filter.ui")
require("gh-issues.filter.filter")

---@param data gh-issues.PullRequest|gh-issues.Issue
---@return gh-issues.PullRequest|gh-issues.Issue
function M.filter(data)
    vim.print("Filtering loaded")
    -- Open UI
    ui:open(data)
    --
    return data
end
return M
