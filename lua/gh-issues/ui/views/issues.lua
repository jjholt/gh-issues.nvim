---@class ViewIssue: gh-issues.View
---@field header string[]
---@field issue gh-issues.Issue|nil
---@field description string[]
---@field comments gh-issues.Comment[]

local View = {}
View.__index = View

---@param ui? gh-issues.Ui
---@return gh-issues.View
function View.new(ui)
    local self = setmetatable({
        ui = ui or nil,
        header = {},
        description = {},
        comments = {},
        reviews = {},
        link_locations = {},
        review_navigation_markers = {},
    }, View)

    return self
end

---@param ui gh-issues.Ui
---@param item gh-issues.Issue
---@param callback fun()
function View:load(ui, item, callback)
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


    self.comments = item:fetch_comments() or {}

    callback()
end

---@param ui gh-issues.Ui
function View:render(ui)
    local render = require("gh-issues.ui.render")
    self.link_locations, self.review_navigation_markers = render.render(ui.buf, self.header, self.description,
        self.comments, self.reviews, self.issue)
end

---@param ui gh-issues.Ui
---@param item gh-issues.Issue|gh-issues.PullRequest
function View:update(ui, item)
    self:load(ui,  item, function()
        if not ui:is_open() then return end
        self:render(ui)
    end)
end

return View
