---@class gh-issues.Ui
---@field win number|nil
---@field buf number|nil
---@field header string[]
---@field issue gh-issues.Issue|gh-issues.PullRequest|nil
---@field description string[]
---@field comments gh-issues.Comment[]
---@field reviews gh-issues.Review[]
---@field link_locations number[]
---@field review_navigation_markers number[]
local Ui = {}
Ui.__index = Ui


local keybinds = require("gh-issues.ui.keybinds")
local render = require("gh-issues.ui.render")

---@return gh-issues.Ui
function Ui.new()
    local self = setmetatable({
        win = nil,
        buf = nil,
        header = {},
        description = {},
        comments = {},
        reviews = {},
        link_locations = {},
        review_navigation_markers = {},
    }, Ui)

    return self
end

---@return boolean
function Ui:is_open()
    return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

---@param item gh-issues.Issue|gh-issues.PullRequest
---@param callback fun()
function Ui:load(item, callback)
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

    local config = vim.api.nvim_win_get_config(self.win)
    config.title = string.format("#%d %s", item.number, item.title)
    config.title_pos = "center"
    vim.api.nvim_win_set_config(self.win, config)

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

---@param item gh-issues.Issue|gh-issues.PullRequest
function Ui:open(item)
    local win = require("gh-issues.helpers").create_floating_window()
    self.buf = win.buf
    self.win = win.win
    keybinds.setup(self)

    self:load(item, function()
        if not self:is_open() then return end
        self:render()
    end)
end

---@param item gh-issues.Issue|gh-issues.PullRequest
function Ui:update(item)
    self:load(item, function()
        if not self:is_open() then return end
        self:render()
    end)
end

function Ui:render()
    self.link_locations, self.review_navigation_markers = render.render(self.buf, self.header, self.description,
        self.comments, self.reviews, self.issue)
end

function Ui:close()
    if self:is_open() then
        vim.api.nvim_win_close(self.win, true)
        vim.api.nvim_buf_delete(self.buf, { force = true })
        self.win = nil
        self.buf = nil
    end
end

return Ui
