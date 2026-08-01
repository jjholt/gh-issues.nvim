local M = {}
local ns = vim.api.nvim_create_namespace("gh-issues-diagnostics")

---@param reviews gh-issues.Review[]
function M.set(reviews)
    local by_file = {}
    for _, review in ipairs(reviews) do
        if review.path and review.line then
            if not by_file[review.path] then
                by_file[review.path] = {}
            end
            table.insert(by_file[review.path], review)
        end
    end

    for path, file_reviews in pairs(by_file) do
        local full_path = vim.fn.getcwd() .. "/" .. path
        local bufnr = vim.fn.bufadd(full_path)
        vim.fn.bufload(bufnr)

        local diagnostics = {}
        for _, review in ipairs(file_reviews) do
            table.insert(diagnostics, {
                lnum = review.line - 1,
                col = 0,
                message = string.format("%s: %s", review.user, review.body),
                severity = vim.diagnostic.severity.INFO,
                source = "gh-issues",
            })
        end

        vim.diagnostic.set(ns, bufnr, diagnostics)
    end
end

---@param branch string
---@param hunks_by_file table<string, number[][]>
function M.set_diff(branch, hunks_by_file)
    for path, hunks in pairs(hunks_by_file) do
        local full_path = vim.fn.getcwd() .. "/" .. path
        local bufnr = vim.fn.bufadd(full_path)
        vim.fn.bufload(bufnr)

        local diagnostics = {}
        for _, hunk in ipairs(hunks) do
            table.insert(diagnostics, {
                lnum = hunk[1] - 1, -- 0-indexed
                col = 0,
                message = string.format("modified by branch %s", branch),
                severity = vim.diagnostic.severity.WARN,
                source = "gh-issues",
            })
        end

        vim.diagnostic.set(ns, bufnr, diagnostics)
    end
end

function M.clear()
    vim.diagnostic.reset(ns)
end

return M
