local M = {}
local ns = require("gh-issues.review").ns
---@param comment gh-issues.DraftComment
---@return number
function M.render(comment)
    local lines = vim.split(comment.body, "\n")
    local virt_lines = {}
    for _, line in ipairs(lines) do
        table.insert(virt_lines, {
            {" " .. line, "DiagnosticVirtualTextInfo"}
        })
    end
    local extmark_id = vim.api.nvim_buf_set_extmark(comment.bufnr, ns, comment.line - 1, 0, {
        virt_lines = virt_lines,
        virt_lines_above = false,
    })
    return extmark_id
end

return M
