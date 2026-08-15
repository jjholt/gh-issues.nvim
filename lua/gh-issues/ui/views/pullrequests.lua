---@class ViewPullRequest: gh-issues.View
---@field header string[]
---@field issue gh-issues.PullRequest|nil
---@field description string[]
---@field comments gh-issues.Comment[]
---@field reviews gh-issues.Review[]
---@field link_locations number[]
---@field modified_files any[]
---@field review_navigation_markers number[]

local ViewPR = {}
ViewPR.__index = ViewPR

---@param ui? gh-issues.Ui
---@return gh-issues.View
function ViewPR.new(ui)
    local self = setmetatable({
        ui = ui or nil,
        header = {},
        description = {},
        comments = {},
        reviews = {},
        link_locations = {},
        review_navigation_markers = {},
    }, ViewPR)

    return self
end

---@param ui gh-issues.Ui
---@param item gh-issues.Issue|gh-issues.PullRequest
---@param callback fun()
function ViewPR:load(ui, item, callback)
    self.issue = item

    local labels = {}
    for _, label in ipairs(item.labels) do
        table.insert(labels, label.name)
    end

    self.header = {
        string.format("@%s | %s", item.user, item.created_at),
        string.format("labels: %s", table.concat(labels, ", ")),
        "",
    }

    local config = vim.api.nvim_win_get_config(ui.win)
    config.title = string.format("#%d %s", item.number, item.title)
    config.title_pos = "center"
    vim.api.nvim_win_set_config(ui.win, config)

    local body = item.body
    self.description = vim.split(body, "\n")
    table.insert(self.description, "")


    self.comments = {}
    self.reviews = {}

    -- track how many async operations are pending
    local has_reviews = item.fetch_reviews ~= nil
    local has_diff = item.fetch_diff ~= nil and item.conflicting_files ~= nil
    if item.comments
        and (not has_reviews or item.reviews)
        and (not has_diff or item.diff)
    then
        self.comments = item.comments
        self.reviews = item.reviews or {}
        callback()
        return
    end

    local pending = 1 + (has_reviews and 1 or 0) + (has_diff and 1 or 0) -- comments + optional

    local function done()
        pending = pending - 1
        if pending == 0 then
            callback()
        end
    end

    item:fetch_comments(function(comments)
        self.comments = comments or {}
        done()
    end)

    if has_reviews then
        ---@cast item gh-issues.PullRequest
        item:fetch_reviews(function(reviews)
            self.reviews = reviews or {}
            done()
        end)
    end

    if has_diff then
        ---@cast item gh-issues.PullRequest
        item:fetch_diff(function(hunks)
            if hunks then
                require("gh-issues.ui.diagnostics").set_diff(item.branch, hunks)
            end
            done()
        end)
    end
end

---@param ui gh-issues.Ui
function ViewPR:render(ui)
    local renderer = require("gh-issues.ui.renderer")
    local render = require("gh-issues.ui.render")
    self.link_locations, self.review_navigation_markers = render.render(ui.buf, self.header, self.description,
        self.comments, self.reviews, self.issue)

    local lines, link_locations, review_navigation_markers

    if self.issue.conflicting_files and #self.issue.conflicting_files > 0 then
        lines, link_locations, review_navigation_markers = renderer.conflicts(self.header, self.issue)
    else
        lines, link_locations, review_navigation_markers = renderer.normal(self.header, self.description, self.comments, self.reviews or {})
    end

    vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, lines)

    renderer.apply_keybinds_highlights(ui.buf)

    for _, loc in ipairs(link_locations) do
        local ns = vim.api.nvim_create_namespace("gh-issues-links")
        local line = vim.api.nvim_buf_get_lines(ui.buf, loc.lnum, loc.lnum + 1, false)[1] or ""
        vim.api.nvim_buf_set_extmark(ui.buf, ns, loc.lnum, loc.col, {
            end_col = math.min(loc.col + #string.format("%s:%d", loc.path, loc.line or 1), #line),
            hl_group = "Special",
        })
    end
    return link_locations, review_navigation_markers
end

---@param ui gh-issues.Ui
---@param item gh-issues.Issue|gh-issues.PullRequest
function ViewPR:update(ui, item)
    self:load(ui,  item, function()
        if not ui:is_open() then return end
        self:render(ui)
    end)
end

return ViewPR
