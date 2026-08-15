local M = {}

local config = require("gh-issues").config

---@param remote? string defaults to config.repository if not provided
M.open_issues = function(remote)
    local issue = require("gh-issues.issue");
    local data = issue.fetch(remote ~= "" and remote or config.repository)
    if not data then return end
    local view = require("gh-issues.ui.views.issues").new()
    require("gh-issues.quickfix").populate_issues(view, data)
end
---@param remote? string defaults to config.repository if not provided
M.open_pull_request = function(remote)
    local pull_request = require("gh-issues.pull_request")
    local data = pull_request.fetch(remote ~= "" and remote or config.repository)
    if not data or next(data) == nil then
        vim.notify("gh-issues: No open pull requests", vim.log.levels.INFO)
        return
    end
    local username = data[1].repository:get_username()
    if not username then return end
    local filtered = require("gh-issues.filter").filter(data, username)
    local view = require("gh-issues.ui.views.pullrequests").new()
    require("gh-issues.quickfix").populate_issues(view, filtered)
    -- require("gh-issues.quickfix").populate_issues(data)
end

M.clear_markers = function()
    require("gh-issues.ui.diagnostics").clear()
    vim.notify("Markers cleaned", vim.log.levels.INFO)
end

M.new_review_comment = function(args)
    require("gh-issues.review").new(args)
end
M.submit_review = function ()
    local review = require("gh-issues.review")
    review.confirm(review.get_pending())
end

return M
