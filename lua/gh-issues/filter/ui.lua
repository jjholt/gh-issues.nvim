---@class gh-issues.filter.Ui
---@field win number|nil
---@field buf number|nil
---@field items gh-issues.Issue[]|gh-issues.PullRequest[]
local Ui = {}
Ui.__index = Ui

---@return gh-issues.filter.Ui
function Ui.new()
    local self = setmetatable({
        win = nil,
        buf = nil,
        items = {},
    }, Ui)

    return self
end

local keybinds = require("gh-issues.filter.keybinds")

---@param items gh-issues.Issue[]|gh-issues.PullRequest[}
function Ui:open(items)
    -- self.buf = vim.api.nvim_create_buf(false, true)

    local win = require("gh-issues.helpers").create_floating_window()

    self.buf = win.buf
    self.win = win.win
    keybinds.setup(self)

    self:load(items)
    self:render()
end

function Ui:load(items)
    self.items = items
    -- vim.print(self)
    error("todo")
end

function Ui:render()
    error("todo")
end

return Ui
