---@class gh-issues.Ui
---@field win number|nil
---@field buf number|nil
---@field header string[]
---@field description string[]
---@field comments gh-issues.Comment[]
---@field reviews gh-issues.Review[]
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
    }, Ui)
    keybinds.setup(self)
    return self
end

---@return boolean
function Ui:is_open()
    return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

local function create_floating_window(opts)
    opts = opts or {}
    local buf = vim.api.nvim_create_buf(false, true)

    local width = opts.width or math.floor(vim.o.columns * 0.6)
    local height = opts.height or math.floor(vim.o.lines * 0.8)

    local win_config = {
        relative = "editor",
        width = width,
        height = height,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.floor((vim.o.lines - height) / 2),
        style = "minimal",
        border = "rounded",
    }
    local win = vim.api.nvim_open_win(buf, true, win_config)
    return { buf = buf, win = win }
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

    self.comments = item:fetch_comments() or {}
    self.reviews = {}

    if item.fetch_reviews then
        ---@cast item gh-issues.PullRequest
        self.reviews = item:fetch_reviews() or {}
    end
end

function Ui:render()
    self.link_locations = render.render(self.buf, self.header, self.description, self.comments, self.reviews)
end

---@param item gh-issues.Issue|gh-issues.PullRequest
function Ui:open(item)
    -- self.buf = vim.api.nvim_create_buf(false, true)

    local win = create_floating_window()

    self.buf = win.buf
    self.win = win.win


    self:load(item)
    self:render()
end

---@param item gh-issues.Issue|gh-issues.PullRequest
function Ui:update(item)
    self:load(item)
    self:render()
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
