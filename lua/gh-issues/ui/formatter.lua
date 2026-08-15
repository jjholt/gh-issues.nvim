local M = {}
---@param comment gh-issues.Comment
---@return string[]
function M.comment(comment)
    local lines = {
        string.format("## %s (%s)", comment.user, comment.created_at),
        ""
    }
    for _, line in ipairs(vim.split(comment.body, "\n")) do
        table.insert(lines, line)
    end
    table.insert(lines, "")
    return lines
end

---@param review gh-issues.Review
---@return string[], string, number
function M.review(review)
    local location = (review.line and review.line ~= vim.NIL)
        and string.format("%s:%d", review.path, review.line)
        or review.path

    local header = string.format("%s ## %s (%s)", location, review.user, review.created_at)
    -- local location_col = #header - #location -- column where location starts
    local location_col = 0

    return {
        header,
        "",
        review.body,
        "",
    }, location, location_col
end

---@param draft gh-issues.DraftComment
---@return string[]
function M.draft(draft)
    local location = draft.start_line ~= draft.line
        and string.format("%s:%d-%d", draft.path, draft.start_line, draft.line)
        or string.format("%s:%d", draft.path, draft.line)

    return {
        location,
        "",
        draft.body,
        "",
    }
end

return M
