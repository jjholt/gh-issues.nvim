local M = {}

local ui = require("gh-issues.ui").new()
local qf_entries = {}

vim.api.nvim_create_autocmd("CursorMoved", {
    callback = function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "qf" then
                local qf_item = vim.fn.getqflist()[vim.api.nvim_win_get_cursor(win)[1]]

                if not qf_item then
                    return
                end
                local item = qf_entries[qf_item.lnum]
                if ui:is_open() then
                    ui:update(nil, item)
                end
            end
        end
    end,
})

---@param items gh-issues.PRFile[]
function M.populate_pr_files(items)
    if #items == 0 then
        vim.notify("gh-issues: no files were modified", vim.log.levels.INFO)
        return
    end

    qf_entries = {}
    for _, item in ipairs(items) do
        -- deleted files
        if #item.hunks == 0 then
            table.insert(qf_entries, {
                filename = item.filename,
                text = string.format("[%s] (no hunks)", item.status),
                lnum = 1,
            })
        else
            for _, hunk in ipairs(item.hunks) do
                table.insert(qf_entries, {
                    filename = item.filename,
                    text = string.format("[%s] %s", item.status, hunk.header),
                    lnum = hunk.lnum,
                })
            end
        end
    end

    vim.api.nvim_exec_autocmds("QuickFixCmdPre", {})
    vim.fn.setqflist(qf_entries)
    vim.api.nvim_exec_autocmds("QuickFixCmdPost", { modeline = false })

    vim.cmd("copen")
end

---@param view gh-issues.View
---@param items gh-issues.Issue[]
function M.populate_issues(view, items)
    if #items == 0 then
        vim.notify("gh-issues: none found. Check filter settings.", vim.log.levels.INFO)
        return
    end

    qf_entries = {}
    for i, item in ipairs(items) do
        item.lnum = i
        qf_entries[i] = item
    end
    vim.api.nvim_exec_autocmds("QuickFixCmdPre", {})
    vim.fn.setqflist(qf_entries)
    vim.cmd("copen")

    local qf_buf = vim.api.nvim_get_current_buf()

    vim.keymap.set("n", "<CR>", function()
        local qf_item = vim.fn.getqflist()[vim.fn.line(".")]
        local item = qf_entries[qf_item.lnum]
        if ui:is_open() then
            view:update(ui, item)
        else
            ui:open(view)
            view:update(ui, item)
        end
    end, { buffer = qf_buf })
end

---@param reviews gh-issues.Review[]
---@param notify boolean
function M.populate_reviews(reviews, notify)
    if notify and #reviews == 0 then
        vim.notify("gh-issues: no existing reviews", vim.log.levels.INFO)
        return
    end

    qf_entries = {}

    for _, review in ipairs(reviews) do
        table.insert(qf_entries, {
            filename = review.path,
            lnum = review.line or 1,
            col = 0,
            text = string.format("%s: %s", review.user, review.body),
            valid = true,
        })
    end
    vim.api.nvim_exec_autocmds("QuickFixCmdPre", {})
    vim.fn.setqflist(qf_entries)

    vim.cmd("copen")
end

function M.clear()
    local qf_buf = vim.fn.getqflist({ qfbufnr = 0 }).qfbufnr
    if qf_buf ~= 0 and vim.api.nvim_buf_is_valid(qf_buf) then
        vim.api.nvim_buf_delete(qf_buf, { force = true })
    end
end

return M
