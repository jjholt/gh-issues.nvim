local M = {}

local ui = require("gh-issues.ui").new()
local qf_entries = {}

vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    once = true,
    callback = function()
        vim.keymap.set("n", "<CR>", function()
            local qf_item = vim.fn.getqflist()[vim.fn.line(".")]
            local item = qf_entries[qf_item.lnum]
            ui:open(item)
        end, { buffer = true })

        vim.api.nvim_create_autocmd("CursorMoved", {
            callback = function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "qf" then
                        local qf_item = vim.fn.getqflist()[vim.api.nvim_win_get_cursor(win)[1]]

                        if qf_item then
                            local item = qf_entries[qf_item.lnum]
                            if ui:is_open() then
                                ui:update(item)
                            end
                        end
                    end
                end
            end,
        })
        --
    end,
})

---@param items gh-issues.Issue[]
function M.populate_issues(items)
    if #items == 0 then
        vim.notify("gh-issues: none found", vim.log.levels.INFO)
        return
    end

    qf_entries = {}
    for i, item in ipairs(items) do
        item.lnum = i
        qf_entries[i] = item
    end
    vim.api.nvim_exec_autocmds("QuickFixCmdPre", {})
    vim.fn.setqflist(qf_entries)
    vim.api.nvim_exec_autocmds("QuickFixCmdPost", {})
    vim.cmd("copen")
end

---@param reviews gh-issues.Review[]
function M.populate_reviews(reviews)
    if #reviews == 0 then
        vim.notify("gh-issues: none found", vim.log.levels.INFO)
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
    vim.fn.setqflist({}, "r")
    vim.api.nvim_exec_autocmds("QuickFixCmdPre", {})
    vim.fn.setqflist(qf_entries)
    vim.cmd("copen")
    vim.api.nvim_exec_autocmds("QuickFixCmdPost", {})
    local qf_buf = vim.fn.getqflist({ qfbufnr = 0 }).qfbufnr
    vim.keymap.set("n", "<CR>", function()
        vim.cmd("cc " .. vim.fn.line("."))
    end, { buffer = qf_buf })
end

return M
