local M = {}

---@param url string
---@param token string
---@return table|nil
function M.get(url, token)
    local out = vim.system({
        "curl", "--request", "GET",
        "--header", "Accept: application/vnd.github+json",
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



---@param owner string
---@param repo string
---@return string
function M.url_pr(owner, repo)
    error("not yet implemented")
    return string.format("https://api.github.com/repos/%s/%s/issues", owner, repo)
end

return M
