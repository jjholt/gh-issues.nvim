local M = {}
local ns = vim.api.nvim_create_namespace("gh-issues")

---@param reviews gh-issues.Review[]
function M.set(reviews)
    -- group by file
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
        local bufnr = vim.fn.bufadd(path)
        vim.fn.bufload(bufnr)

        local diagnostics = {}
        for _, review in ipairs(file_reviews) do
            table.insert(diagnostics, {
                lnum = review.line - 1,  -- diagnostics are 0-indexed
                col = 0,
                message = string.format("[%s] %s: %s", review.state, review.user, review.body),
                severity = vim.diagnostic.severity.INFO,
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
