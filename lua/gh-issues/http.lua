local M = {}
M.issue = {}
M.pr = {}

---@param url string
---@param token string
---@return table|nil
function M.get(url, token)
    local out = vim.system({
        "curl", "-L",
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



return M
