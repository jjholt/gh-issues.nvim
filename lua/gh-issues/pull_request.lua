local Issue = require("gh-issues.issue")
---@class gh-issues.PullRequest: gh-issues.Issue
---@field reviews gh-issues.Review[]|nil
local PullRequest = setmetatable({}, { __index = Issue })
PullRequest.__index = PullRequest

---@class gh-issues.Review: gh-issues.Comment
---@field path string relative path to the file e.g. "lua/gh-issues/issue.lua"
---@field line number|nil line number in the file the comment applies to
---@field start_line number|nil first line for multi-line comments
---@field side string "LEFT" or "RIGHT" side of the diff
---@field state string e.g. "APPROVED", "CHANGES_REQUESTED", "COMMENTED"
---@field diff_hunk string the diff context the comment was made on
---@field html_url string link to the comment on GitHub
---@field in_reply_to_id number|nil id of the parent comment if this is a reply
---@field id number needed so other comments can reference this as in_reply_to_id
---@field fetch_reviews fun(self: gh-issues.Issue): gh-issues.Review[]|nil

---@param raw table
---@param repository gh-issues.Repository
---@param url string
---@class gh-issues.PullRequest
function PullRequest.new(raw, repository, url)
    local self = Issue.new(raw, repository, url)
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

    local url = repository:url()
    local token = repository:get_token()
    if not token then return nil end

    local data = require("gh-issues.http").get(url .. "pulls", token)
    if not data then return nil end

    local issues = {}
    for _, datum in ipairs(data) do
        local issue = PullRequest.new(datum, repository, url)
        table.insert(issues, issue)
    end
    return issues
end

---@return gh-issues.Comment[]|nil
function PullRequest:fetch_reviews()
    if self.reviews then
        return self.reviews
    end


    local token = self.repository:get_token()
    if not token then return nil end

    local id = self.number
    local url = self.url .. string.format("pulls/%d/comments", id)
    local data = require("gh-issues.http").get(url, token)
    if not data then return nil end

    local reviews = {}
    for _, raw in ipairs(data) do
        table.insert(reviews, {
            user = raw.user.login,
            body = raw.body,
            created_at = raw.created_at,
            path = raw.path,
            line = raw.line,
            start_line = raw.start_line,
            side = raw.side,
            state = raw.state,
            diff_hunk = raw.diff_hunk,
            html_url = raw.html_url,
            in_reply_to_id = raw.in_reply_to_id,
            id = raw.id,
        })
    end

    self.reviews = reviews

    return reviews
end

return PullRequest
