local M = {}
---
---@class gh-issues.Review: gh-issues.Comment
---@field state string

---@class gh-issues.PullRequest: gh-issues.Issue
---@field reviews gh-issues.Review[]|nil


---@param owner string
---@param repo string
---@return string
function M.url(owner, repo)
    return string.format("https://api.github.com/repos/%s/%s/pulls", owner, repo)
end

---@param owner string
---@param repo string
---@param number number
---@return string
function M.comments_url(owner, repo, number)
    return string.format("https://api.github.com/repos/%s/%s/pulls/%s/comments", owner, repo, number)
end


local cache = require("gh-issues.cache")
---@param remote string
---@return gh-issues.PullRequest[]|nil
M.list_all = function(remote)
    local gh = require("gh-issues.git")
    local alias, owner, repo = gh.get_repo(remote)
    if not repo then return nil end


    assert(type(owner) == "string")
    assert(type(repo) == "string")
    local key = cache.make_key(owner, repo, "pulls")

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
        local issue = require("gh-issues.issue").from_api(datum)
        cache.set(key, issue.number, issue)
        table.insert(issues, issue)
    end
    return issues
end
return M
