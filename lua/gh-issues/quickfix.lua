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

        vim.keymap.set("n", "q", function()
            ui:close()
        end, { buffer = true })

        vim.api.nvim_create_autocmd("CursorMoved", {
            buffer = 0,
            callback = function()
                local qf_item = vim.fn.getqflist()[vim.fn.line(".")]
                local item = stored_items[qf_item.lnum]
                if ui:is_open() then
                    ui:update(item)
                end
            end,
        })
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
