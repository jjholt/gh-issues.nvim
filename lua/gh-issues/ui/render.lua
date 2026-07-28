local M = {}
local ns = vim.api.nvim_create_namespace("gh-issues-links")

---@param comment gh-issues.Comment
---@return string[]
local function format_comment(comment)
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
local function format_review(review)
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

---@param buf number
---@param header string[]
---@param description string[]
---@param comments gh-issues.Comment[]
---@param reviews gh-issues.Review[]|nil
---@return table link_locations
function M.render(buf, header, description, comments, reviews)
    local lines = {}
    local link_locations = {}

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    for _, line in ipairs(header) do table.insert(lines, line) end
    for _, line in ipairs(description) do table.insert(lines, line) end

    table.insert(lines, string.format("Comments (%s)", #comments))
    for _, comment in ipairs(comments) do
        for _, line in ipairs(format_comment(comment)) do
            table.insert(lines, line)
        end
    end
    table.insert(lines, "")

    if reviews then
        table.insert(lines, string.format("Reviews (%s)", #reviews))
        for _, review in ipairs(reviews) do
            local review_lines, _, col = format_review(review)
            local lnum = #lines -- 0-indexed, before inserting

            table.insert(link_locations, {
                lnum = lnum,
                col = col,
                path = review.path,
                line = review.line,
            })

            for _, line in ipairs(review_lines) do
                table.insert(lines, line)
            end
        end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    for _, loc in ipairs(link_locations) do
        vim.api.nvim_buf_set_extmark(buf, ns, loc.lnum, loc.col, {
            end_col = loc.col + #string.format("%s:%d", loc.path, loc.line or 1),
            hl_group = "Special",
        })
    end



    return link_locations
end

return M
