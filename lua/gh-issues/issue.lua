local M = {}

local cache = require("gh-issues.cache")
-- local ui = require("gh-issues.ui")


---@param remote string
M.list_all = function(remote)
    local gh = require("gh-issues.git")
    local alias, owner, repo = gh.get_repo(remote)
    if not repo then return end
    local token = gh.get_token(alias)

    local key = owner .. "/" .. repo .. "/issues"
    local cached_data = cache.get(key)

    if cached_data then
        print("Data is cached")
        -- ui.render(data)
        return
    end

    vim.system({
        "curl", "--request", "GET",
        "--header", "Accept: application/vnd.github+json",
        "--header", "Authorization: Bearer " .. token,
        "--url", "https://api.github.com/repos/" .. owner .. "/" .. repo .. "/issues"
    }, {}, function (out)

        local issues = vim.json.decode(out.stdout)
        cache.set(key, issues)
        print("Caching data")
        -- ui.render(issues)
    end)

end

return M
