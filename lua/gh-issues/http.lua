local M = {}

---@param url string
---@param token string
---@return table|nil
function M.get(url, token)
    local out = vim.system({
        "curl", "-L",
        "--header", "Accept: application/vnd.github+json",
        "--header", "X-GitHub-Api-Version: 2026-03-10",
        "--header", "Authorization: Bearer " .. token,
        "--url", url,
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

---@param raw_headers string
---@return string|nil
local function parse_next_link(raw_headers)
    -- Link: <https://api.github.com/...?page=2>; rel="next", <...>; rel="last"
    for entry in raw_headers:gmatch("[^,]+") do
        local url, rel = entry:match("<(.-)>%s*;%s*rel=\"(.-)\"")
        if rel == "next" then
            return url
        end
    end
    return nil
end

---@param stdout string
---@return string headers, string body 
local function split_response(stdout)
    -- curl -i gives headers and body separated by \r\n\r\n
    local headers, body = stdout:match("^(.-)\r\n\r\n(.*)$")
    return headers or "", body or stdout
end

---@param url string
---@param token string
---@param accumulated table
---@param callback fun(data: table|nil)
local function fetch_page(url, token, accumulated, callback)
    vim.system({
        "curl", "-i", "-L",
        "--header", "Accept: application/vnd.github+json",
        "--header", "X-GitHub-Api-Version: 2026-03-10",
        "--header", "Authorization: Bearer " .. token,
        "--url", url,
    }, {}, function(out)
        if out.code ~= 0 then
            vim.schedule(function()
                vim.notify("gh-issues: request failed: " .. out.stderr, vim.log.levels.ERROR)
                callback(nil)
            end)
            return
        end

        local headers, body = split_response(out.stdout)

        local ok, data = pcall(vim.json.decode, body)
        if not ok then
            vim.schedule(function()
                vim.notify("gh-issues: failed to decode response", vim.log.levels.ERROR)
                callback(nil)
            end)
            return
        end

        -- accumulate
        if type(data) == "table" and vim.islist(data) then
            for _, item in ipairs(data) do
                table.insert(accumulated, item)
            end
        end

        local next_url = parse_next_link(headers)
        if next_url then
            fetch_page(next_url, token, accumulated, callback)
        else
            vim.schedule(function()
                callback(accumulated)
            end)
        end
    end)
end

---@param url string
---@param token string
---@param callback fun(data: table|nil)
function M.async_get(url, token, callback)
    fetch_page(url, token, {}, callback)
end


return M
