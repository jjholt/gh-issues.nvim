local M = {}
local ns = vim.api.nvim_create_namespace("gh-issues-links")

local function build_keybinds_header()
    local keybinds = require("gh-issues.ui.keybinds")
    local line = ""
    for i, bind in ipairs(keybinds.binds) do
        line = line .. bind.key .. ": " .. bind.desc
        if i < #keybinds.binds then
            line = line .. "  |  "
        end
    end
    return {
        line,
        string.rep("─", vim.api.nvim_win_get_width(0)),
    }
end

local function apply_keybinds_highlights(buf)
    local keybinds = require("gh-issues.ui.keybinds")

    vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
        end_row = 1,
        hl_group = "Comment",
        priority = 10,
    })

    local col = 0
    for _, bind in ipairs(keybinds.binds) do
        vim.api.nvim_buf_set_extmark(buf, ns, 0, col, {
            end_col = col + #bind.key,
            hl_group = "Bold",
            priority = 100,
        })
        col = col + #bind.key + #(": " .. bind.desc .. "  |  ")
    end
end

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
---@return table link_locations, table review_navigation_markers
function M.render(buf, header, description, comments, reviews)
    local lines = {}
    local link_locations = {}
    local review_navigation_markers = {}

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    local header_lines = build_keybinds_header()
    for _, line in ipairs(header_lines) do
        table.insert(lines, line)
    end

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

            table.insert(review_navigation_markers, lnum)

            for _, line in ipairs(review_lines) do
                table.insert(lines, line)
            end
        end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    apply_keybinds_highlights(buf)

    for _, loc in ipairs(link_locations) do
        vim.api.nvim_buf_set_extmark(buf, ns, loc.lnum, loc.col, {
            end_col = loc.col + #string.format("%s:%d", loc.path, loc.line or 1),
            hl_group = "Special",
        })
    end



    return link_locations, review_navigation_markers
end

return M
