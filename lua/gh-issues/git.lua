---@class gh-issues.Repository
---@field owner string
---@field repo string
---@field alias string
---@field get_token fun(self: gh-issues.Repository): string|nil
---@field url_pr fun(self: gh-issues.Repository): string
---@field url_issue fun(self: gh-issues.Repository): string
local Repository = {}
Repository.__index = Repository

---@param remote string
---@return string|nil
local function get_remote_url(remote)
    local res = vim.system({ "git", "remote", "get-url", remote }):wait()
    if res.code ~= 0 then
        vim.notify("gh-issues: could not find remote " .. remote, vim.log.levels.ERROR)
        return nil
    end

    local url = res.stdout:gsub("%.git", ""):gsub("%s+$", "")
    return url
end

---@param url string
---@return string|nil owner, string|nil repo
local function parse_remote_url(url)
    local owner, repo = url:match(":([^/]+)/([^/]+)$")
    if owner and repo then return owner, repo end

    return nil, nil
end

---@param url string
---@return string|nil
local function get_ssh_alias(url)
    if url:match("^git@") then return nil end
    if url:match("^https?://") then return nil end
    return url:match("^([^:]+):")
end

--- Returns the owner and repo for a given remote name
---@param remote string e.g. "origin", "upstream", "personal"
---@return gh-issues.Repository|nil
function Repository.new(remote)
    local url = get_remote_url(remote)
    if not url then
        return nil
    end
    local alias = get_ssh_alias(url)
    local owner, repo = parse_remote_url(url)

    if not alias or not owner or not repo then return nil end

    local self = setmetatable({}, Repository)
    self.alias = alias
    self.owner = owner
    self.repo = repo

    return self
end

---@return string|nil
function Repository:get_token()
    local config = require("gh-issues").config
    local alias = self.alias

    -- Single account
    if not config.accounts then
        local res = vim.system({"gh", "auth", "token"}):wait()
        if res.code ~= 0 then
            return nil
        end
        local token = res.stdout:gsub("%s+$", "")
        return token
    end

    -- Multi account
    local username = config.accounts[alias]
    if not username then
        vim.notify("gh-issues: no account mapped for alias" .. alias, vim.log.levels.ERROR)
        return nil
    end

    local res = vim.system({ "gh", "auth", "token", "--user", username }):wait()
    if res.code ~= 0 then
        vim.notify("gh-issues: not logged in as " .. username .. ". Run `gh auth login`", vim.log.levels.ERROR)
        return nil
    end

    local token = res.stdout:gsub("%s+$", "")
    return token
end

---@return string
function Repository:url()
    return string.format("https://api.github.com/repos/%s/%s/", self.owner, self.repo)
end

return Repository
