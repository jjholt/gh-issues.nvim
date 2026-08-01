local M = {}

function M.create_floating_window(opts)
    opts = opts or {}
    local buf = vim.api.nvim_create_buf(false, true)

    local width = opts.width or math.floor(vim.o.columns * 0.6)
    local height = opts.height or math.floor(vim.o.lines * 0.8)

    local win_config = {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        style = "minimal",
        border = "rounded",
    }
    local win = vim.api.nvim_open_win(buf, true, win_config)
    return { buf = buf, win = win }
end

return M
