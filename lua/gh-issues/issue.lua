local M = {}
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

---@param raw table
---@return gh-issues.Issue
local function from_api(raw)
    return {
        number = raw.number,
        title = raw.title,
        body = raw.body,
        state = raw.state,
        created_at = raw.created_at,
        updated_at = raw.updated_at,
        user = raw.user.login,
        labels = vim.tbl_map(function(l) return l.name end, raw.labels),
        comments = nil,

        -- Fields for quickfix
        text = string.format("%d [%s] %s: %s", raw.number, raw.state, raw.user.login, raw.title),
        lnum = 0,
        bufnr = 0,
        valid = true,
    }
end


---@param owner string
---@param repo string
---@return string
function M.url(owner, repo)
    return string.format("https://api.github.com/repos/%s/%s/issues", owner, repo)
end

---@param owner string
---@param repo string
---@param number number
---@return string
function M.comments_url(owner, repo, number)
    return string.format("https://api.github.com/repos/%s/%s/issues/%s/comments", owner, repo, number)
end

local cache = require("gh-issues.cache")
-- local ui = require("gh-issues.ui")


---@param remote string
---@return gh-issues.Issue[]|nil
M.list_all = function(remote)
    local gh = require("gh-issues.git")
    local alias, owner, repo = gh.get_repo(remote)
    if not repo then return nil end


    assert(type(owner) == "string")
    assert(type(repo) == "string")
    local key = cache.make_key(owner, repo, "issues")

    local cached = cache.get_all(key)
    if cached then
        vim.print("we're cached")
        return
    end

    local http = require("gh-issues.http")
    local url = M.url(owner, repo)
    local token = gh.get_token(alias)
    assert(type(token) == "string")
    local data = http.get(url, token)
    if not data then return nil end

    local issues = {}
    for _, datum in ipairs(data) do
        local issue = from_api(datum)
        cache.set(key, issue.number, issue)
        table.insert(issues, issue)
    end
    return issues
end

---@param owner string
---@param repo string
---@param alias string|nil
---@param number number
---@return gh-issues.Comment[]|nil
M.get_comments = function(owner, repo, alias, number)
    local gh = require("gh-issues.git")
    local token = gh.get_token(alias)
    if not token then return nil end

    local http = require("gh-issues.http")
    local data = http.get(M.comments_url(owner, repo, number), token)
    if not data then return nil end

    local comments = {}
    for _, raw in ipairs(data) do
        table.insert(comments, {
            user = raw.user.login,
            body = raw.body,
            created_at = raw.created_at,
        })
    end

    return comments
end


return M
