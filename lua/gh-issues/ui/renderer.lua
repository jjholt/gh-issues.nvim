local M = {}
local formatter = require("gh-issues.ui.formatter")

function M.apply_keybinds_highlights(buf)
    local ns = vim.api.nvim_create_namespace("gh-issues-links")
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

---@param drafts gh-issues.DraftComment[]
---@return string[] lines, table navigation_markers
function M.confirm(drafts)
    local lines = {}
    local navigation_markers = {}

    local keybind_lines = build_keybinds_header()
    for _, line in ipairs(keybind_lines) do table.insert(lines, line) end

    table.insert(lines, string.format("Pending Review Comments (%d)", #drafts))
    table.insert(lines, "")

    for _, draft in ipairs(drafts) do
        local lnum = #lines
        table.insert(navigation_markers, lnum)
        for _, line in ipairs(formatter.draft(draft)) do
            table.insert(lines, line)
        end
    end

    return lines, navigation_markers
end



---@param header string[]
---@param description string[]
---@param comments gh-issues.Comment[]
---@param reviews gh-issues.Review[]
---@return string[] lines, table link_locations, table review_navigation_markers
function M.normal(header, description, comments, reviews)
    local lines = {}
    local link_locations = {}
    local review_navigation_markers = {}

    local keybind_lines = build_keybinds_header()
    for _, line in ipairs(keybind_lines) do table.insert(lines, line) end

    for _, line in ipairs(header) do table.insert(lines, line) end
    for _, line in ipairs(description) do table.insert(lines, line) end

    table.insert(lines, string.format("Comments (%s)", #comments))
    for _, comment in ipairs(comments) do
        for _, line in ipairs(formatter.comment(comment)) do
            table.insert(lines, line)
        end
    end
    table.insert(lines, "")

    table.insert(lines, string.format("Reviews (%s)", #reviews))
    for _, review in ipairs(reviews) do
        local review_lines, _, col = formatter.review(review)
        local lnum = #lines

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

    return lines, link_locations, review_navigation_markers
end

---@param header string[]
---@param pr gh-issues.PullRequest|gh-issues.Issue
---@return string[] lines, table link_locations, table review_navigation_markers
function M.conflicts(header, pr)
    local lines = {}
    local link_locations = {}
    local review_navigation_markers = {}

    local keybind_lines = build_keybinds_header()
    for _, line in ipairs(keybind_lines) do table.insert(lines, line) end

    for _, line in ipairs(header) do table.insert(lines, line) end

    table.insert(lines, string.format("Conflicting files (%d)", #pr.conflicting_files))
    table.insert(lines, "")

    for _, path in ipairs(pr.conflicting_files) do
        -- find first hunk line for this file from diff data
        local first_line = 1
        if pr.diff and pr.diff[path] and #pr.diff[path] > 0 then
            first_line = pr.diff[path][1][1]
        end

        -- header line: @author | created_at
        table.insert(lines, string.format("@%s | %s", pr.user, pr.created_at))

        -- navigable line: branch  path:line
        local lnum = #lines
        local nav_line = string.format("%s:%d  %s", path, first_line, pr.branch)
        table.insert(lines, nav_line)
        table.insert(lines, "")

        table.insert(link_locations, {
            lnum = lnum,
            col = 0,
            path = path,
            line = first_line,
            diff = true,
        })
        table.insert(review_navigation_markers, lnum)
    end

    return lines, link_locations, review_navigation_markers
end
return M
