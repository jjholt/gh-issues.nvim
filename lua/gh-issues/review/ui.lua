local M = {}
---@param context { bufnr: integer, start_line: integer, end_line: integer, path: string }
---@param callback fun(body: string)
function M.new(context, callback)
    local width = math.floor(vim.o.columns * 0.6)
    local float = require("gh-issues.helpers").create_floating_window({
        width = width,
        height = 1,
        relative = "editor",
        row = context.end_line - 1,
        col = 1,
    })

    vim.api.nvim_buf_set_name(float.buf, "gh-issues://review-comment")
    vim.bo[float.buf].filetype = "markdown"
    vim.bo[float.buf].bufhidden = "wipe"
    vim.bo[float.buf].buftype = "acwrite"

    -- Binds wq to w so it doesn't close nvim
    vim.api.nvim_buf_set_keymap(float.buf, "c", "wq", "w", { noremap = true })
    vim.keymap.set("n", "ZZ", function()
        vim.cmd("write")
    end, { buffer = float.buf, noremap = true })

    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = float.buf,
        callback = function()
            local lines = vim.api.nvim_buf_get_lines(float.buf, 0, -1, false)
            local body = vim.trim(table.concat(lines, "\n"))

            if body == "" then
                vim.notify("gh-issues: empty comment discarded", vim.log.levels.WARN)
                vim.api.nvim_win_close(float.win, true)
                return
            end

            vim.api.nvim_win_close(float.win, true)
            callback(body)
        end,
    })

    vim.api.nvim_create_autocmd("TextChangedI", {
        buffer = float.buf,
        callback = function()
            local line_count = vim.api.nvim_buf_line_count(float.buf)
            vim.api.nvim_win_set_height(float.win, math.max(1, line_count))
        end,
    })
    vim.cmd("startinsert")
end

return M
