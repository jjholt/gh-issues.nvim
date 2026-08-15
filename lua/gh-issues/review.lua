local M = {}
local ns = vim.api.nvim_create_namespace("gh-issues.review")
M.ns = ns
---@class gh-issues.DraftComment
---@field path string
---@field line number
---@field start_line number
---@field body string
---@field extmark_id number
---@field bufnr number

---@type gh-issues.DraftComment[]
local pending = {}

function M.new(args)
    -- get cursor and/or visual selection
    local bufnr = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(bufnr)

    local start_line, end_line
    if args and args.range > 0 then
        start_line = args.line1
        end_line = args.line2
    else
        start_line = vim.fn.line(".")
        end_line = start_line
    end
    local context = {
        start_line = start_line,
        end_line = end_line,
        bufnr = bufnr,
        path = path,
    }
    require("gh-issues.review.ui").new(context, function(body)
        ---@type gh-issues.DraftComment
        local comment = {
            path       = context.path,
            line       = context.end_line,
            start_line = context.start_line,
            body       = body,
            bufnr      = context.bufnr,
            extmark_id = 0,
        }
        local extmark_id = require("gh-issues.review.virtual_line").render(comment)
        comment.extmark_id = extmark_id
        M.add(comment)
    end)
end

---@param comment gh-issues.DraftComment
function M.add(comment)
    table.insert(pending, comment)
end

function M.get_pending()
    return pending
end

return M
