local M = {}

local ui = require("gh-issues.ui").new()
local stored_items = {}

vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    once = true,
    callback = function()
        vim.keymap.set("n", "<CR>", function()
            local qf_item = vim.fn.getqflist()[vim.fn.line(".")]
            local item = stored_items[qf_item.lnum]
            ui:open(item)
        end, { buffer = true })

        vim.api.nvim_create_autocmd("CursorMoved", {
            callback = function()
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "qf" then
                        local qf_item = vim.fn.getqflist()[vim.api.nvim_win_get_cursor(win)[1]]

                        if qf_item then
                            local item = stored_items[qf_item.lnum]
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
function M.populate(items)
    stored_items = {}
    for _, item in ipairs(items) do
        stored_items[item.number] = item
    end
    vim.fn.setqflist(items)
    vim.cmd("copen")
end

return M
