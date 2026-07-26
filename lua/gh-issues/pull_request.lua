---@class gh-issues.Review: gh-issues.Comment
---@field state string

---@class gh-issues.PullRequest: gh-issues.Issue
---@field reviews gh-issues.Review[]|nil

local M = {}
---@param remote string
M.list_all = function(remote)
    print "PR"
end
return M
