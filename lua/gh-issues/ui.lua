---@class gh-issues.Ui
---@field win number|nil
---@field buf number|nil
---@field header string[]
---@field description string[]
---@field comments string[]
local Ui = {}
Ui.__index = Ui

---@return gh-issues.Ui
function Ui.new()
    return setmetatable({
        win = nil,
        buf = nil,
        header = {},
        description = {},
        comments = {},
    }, Ui)
end

---@return boolean
function Ui:is_open()
    return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

---@param item gh-issues.Issue|gh-issues.PullRequest
function Ui:load(item)
    self.header = {
        string.format("@%s | %s", item.user, item.created_at),
        string.format("labels: %s", table.concat(item.labels, ", ")),
        "",
    }

    local config = vim.api.nvim_win_get_config(self.win)
    config.title = string.format("#%d %s", item.number, item.title)
    config.title_pos = "center"
    vim.api.nvim_win_set_config(self.win, config)

    local body = item.body
    if body == vim.NIL then
        body = ""
    end
    self.description = vim.split(body, "\n")
    table.insert(self.description, "")

    self.comments = {}
    -- comments will be populated separately
end

---@param item gh-issues.Issue|gh-issues.PullRequest
function Ui:render(item)
    local lines = {}
    for _, line in ipairs(self.header) do table.insert(lines, line) end
    for _, line in ipairs(self.description) do table.insert(lines, line) end
    for _, line in ipairs(self.comments) do table.insert(lines, line) end
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
end

---@param item gh-issues.Issue|gh-issues.PullRequest
function Ui:open(item)
    self.buf = vim.api.nvim_create_buf(false, true)

    local width = math.floor(vim.o.columns * 0.6)
    local height = math.floor(vim.o.lines * 0.8)

    self.win = vim.api.nvim_open_win(self.buf, false, {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        style = "minimal",
        border = "rounded",
    })

    self:load(item)
    self:render(item)
end

---@param item gh-issues.Issue|gh-issues.PullRequest
function Ui:update(item)
    self:load(item)
    self:render(item)
end

function Ui:close()
    if self:is_open() then
        vim.api.nvim_win_close(self.win, true)
        self.win = nil
        self.buf = nil
    end
end

return Ui
