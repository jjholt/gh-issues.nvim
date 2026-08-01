local M = {}

---@param current gh-issues.PullRequest
---@param all_prs gh-issues.PullRequest[]
---@param callback fun(conflicting: gh-issues.PullRequest[])
function M.find(current, all_prs, callback)
    local PullRequest = require("gh-issues.pull_request")

    -- fetch current PR's files first, everything depends on this
    current:fetch_files(function(current_files)
        vim.notify(string.format("gh-issues: current PR has %d files", current_files and #current_files or -1), vim.log.levels.INFO)
        if not current_files then
            vim.notify("gh-issues: failed to fetch files for current PR", vim.log.levels.ERROR)
            callback({})
            return
        end

        -- filter out the current PR from the list
        local others = {}
        for _, pr in ipairs(all_prs) do
            if pr.number ~= current.number then
                table.insert(others, pr)
            end
        end

        if #others == 0 then
            callback({})
            return
        end

        local conflicting = {}
        local remaining = #others

        for _, pr in ipairs(others) do
            pr:fetch_files(function(pr_files)
                vim.schedule(function()
                    vim.notify(string.format("gh-issues: PR #%d has %d files", pr.number, pr_files and #pr_files or -1), vim.log.levels.INFO)
                    if pr_files then
                        local overlapping = PullRequest.find_overlapping_files(current_files, pr_files)
                        vim.notify(string.format("gh-issues: PR #%d has %d overlapping files", pr.number, #overlapping), vim.log.levels.INFO)
                        if #overlapping > 0 then
                            pr.conflicting_files = overlapping
                            table.insert(conflicting, pr)
                        end
                    end

                    remaining = remaining - 1
                    if remaining == 0 then
                        callback(conflicting)
                    end
                end)
            end)
        end
    end)
end

return M
