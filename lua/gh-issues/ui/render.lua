local M = {}
local ns = vim.api.nvim_create_namespace("gh-issues-links")
local renderer = require("gh-issues.ui.renderer")


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

---@param buf number
---@param header string[]
---@param description string[]
---@param comments gh-issues.Comment[]
---@param reviews gh-issues.Review[]|nil
---@param pr gh-issues.PullRequest|gh-issues.Issue
---@return table link_locations, table review_navigation_markers
function M.render(buf, header, description, comments, reviews, pr)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    local lines, link_locations, review_navigation_markers

    if pr and pr.conflicting_files and #pr.conflicting_files > 0 then
        lines, link_locations, review_navigation_markers = renderer.conflicts(header, pr)
    else
        lines, link_locations, review_navigation_markers = renderer.normal(header, description, comments, reviews or {})
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    apply_keybinds_highlights(buf)

    for _, loc in ipairs(link_locations) do
        local line = vim.api.nvim_buf_get_lines(buf, loc.lnum, loc.lnum + 1, false)[1] or ""
        vim.api.nvim_buf_set_extmark(buf, ns, loc.lnum, loc.col, {
            end_col = math.min(loc.col + #string.format("%s:%d", loc.path, loc.line or 1), #line),
            hl_group = "Special",
        })
    end
    return link_locations, review_navigation_markers
end

return M
