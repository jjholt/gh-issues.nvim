local M = {}
M.issue = {}
M.pr = {}

---@param url string
---@param token string
---@return table|nil
function M.get(url, token)
    local out = vim.system({
        "curl", "--request", "GET",
        "--header", "Accept: application/vnd.github+json",
        "--header", "X-GitHub-Api-Version: 2026-03-10",
        "--header", "Authorization: Bearer " .. token,
        "--url", vim.trim(url),
    }):wait()

    if out.code ~= 0 then
        vim.notify("gh-issues: request failed: " .. out.stderr, vim.log.levels.ERROR)
        return nil
    end

    local ok, data = pcall(vim.json.decode, out.stdout)
    if not ok then
        vim.notify("gh-issues: failed to decode response", vim.log.levels.ERROR)
        return nil
    end

    return data
end


-- issues
---@param owner string
---@param repo string
---@return string
function M.issue.url(owner, repo)
    return string.format("https://api.github.com/repos/%s/%s/issues", owner, repo)
end

---@param owner string
---@param repo string
---@param number number
---@return string
function M.issue.comments_url(owner, repo, number)
    return string.format("https://api.github.com/repos/%s/%s/issues/%s/comments", owner, repo, number)
end



--- pull requests
---@param owner string
---@param repo string
---@return string
function M.pr.url(owner, repo)
    return string.format("https://api.github.com/repos/%s/%s/pulls", owner, repo)
end

---@param owner string
---@param repo string
---@param number number
---@return string
function M.pr.comments_url(owner, repo, number)
    return string.format("https://api.github.com/repos/%s/%s/pulls/%s/comments", owner, repo, number)
end

return M
