local Issue = {}
Issue.__index = Issue
--- Class Definitions
---@class gh-issues.Issue
---@field number number
---@field title string
---@field body string
---@field state string "open" or "closed"
---@field created_at string
---@field updated_at string
---@field user gh-issues.User
---@field labels gh-issues.Label[]
---@field comments gh-issues.Comment[]|nil
---@field url string
---@field repository gh-issues.Repository
---@field fetch_comments fun(self: gh-issues.Issue): gh-issues.Comment[]|nil
---@field text string
---@field lnum number
---@field bufnr number 
---@field valid boolean

---@class gh-issues.Comment
---@field user string
---@field body string
---@field created_at string

---@class gh-issues.User
---@field login string
---@field avatar_url string

---@class gh-issues.Label
---@field name string
---@field color string

--- End of class definitions

---@return gh-issues.Comment[]|nil
function Issue:fetch_comments()
    if self.comments then
        return self.comments
    end


    local token = self.repository:get_token()
    if not token then return nil end

    local id = self.number
    local url = self.url .. string.format("issues/%d/comments", id)
    local data = require("gh-issues.http").get(url, token)
    if not data then return nil end

    local comments = {}
    for _, raw in ipairs(data) do
        table.insert(comments, {
            user = raw.user.login,
            body = raw.body,
            created_at = raw.created_at,
        })
    end

    self.comments = comments

    return comments
end

---@param raw table
---@param repository gh-issues.Repository
---@param url string
---@return gh-issues.Issue
function Issue.new(raw, repository, url)
    local self = setmetatable({}, Issue)
    self.number = raw.number
    self.title = raw.title
    self.body = raw.body
    self.state = raw.state
    self.created_at = raw.created_at
    self.updated_at = raw.updated_at
    self.user = raw.user.login
    self.labels = vim.tbl_map(function(l) return l.name end, raw.labels)
    self.comments = nil
    self.url = url
    self.repository = repository


    -- Fields for quickfix
    self.text = string.format("%d [%s] %s: %s", raw.number, raw.state, raw.user.login, raw.title)
    self.lnum = 0
    self.bufnr = 0
    self.valid = true

    return self
end

---@param remote string
---@return gh-issues.Issue[]|nil
Issue.fetch = function(remote)
    local repository = require("gh-issues.git").new(remote)
    if not repository then return nil end

    local url = repository:url()
    local token = repository:get_token()
    if not token then return nil end

    local data = require("gh-issues.http").get(url .. "issues", token)
    if not data then return nil end

    local issues = {}
    for _, datum in ipairs(data) do
        if not datum.pull_request then
            local issue = Issue.new(datum, repository, url)
            table.insert(issues, issue)
        end
    end

    return issues
end



return Issue
