local Issue = require("gh-issues.issue")
---@class gh-issues.PullRequest: gh-issues.Issue
---@field reviews gh-issues.Review[]|nil
local PullRequest = setmetatable({}, { __index = Issue})
PullRequest.__index = PullRequest

---@class gh-issues.Review: gh-issues.Comment
---@field state string


---@param raw table
---@param repository gh-issues.Repository
---@class gh-issues.PullRequest
function PullRequest.new(raw, repository)
    local self = Issue.new(raw, repository)
    setmetatable(self, PullRequest)
    ---@cast self gh-issues.PullRequest
    self.reviews = nil
    return self
end


---@param remote string
---@return gh-issues.PullRequest[]|nil
PullRequest.fetch = function(remote)
    local repository = require("gh-issues.git").new(remote)
    if not repository then return nil end

    local url = repository:url_pr()
    local token = repository:get_token()
    if not token then return nil end

    local data = require("gh-issues.http").get(url, token)
    if not data then return nil end

    local issues = {}
    for _, datum in ipairs(data) do
        local issue = PullRequest.new(datum, repository)
        table.insert(issues, issue)
    end
    return issues
end
return PullRequest
