---@class gh-issues.View
---@field win number|nil
---@field buf number|nil
---@field load fun(self, ui, item, callback: fun())
---@field render fun(self, ui)
---@field update fun(self, ui, item)

---@class gh-issues.Ui
---@field win number|nil
---@field buf number|nil
---@field view gh-issues.View|nil
local Ui = {}
Ui.__index = Ui

local keybinds = require("gh-issues.ui.keybinds")
-- local render = require("gh-issues.ui.render")

---@return gh-issues.Ui
function Ui.new()
    local self = setmetatable({
        win = nil,
        buf = nil,
        view = nil,
    }, Ui)

    return self
end

---@return boolean
function Ui:is_open()
    return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

---@param view gh-issues.View
function Ui:open(view)
    local win = require("gh-issues.helpers").create_floating_window()
    self.buf = win.buf
    self.win = win.win
    self.view = view
    keybinds.setup(self)
end

---@param view gh-issues.View|nil
---@param item gh-issues.Issue|gh-issues.PullRequest
function Ui:update(view, item)
    if not view then
        view = self.view
    end
    if not view then return end
    if not self:is_open() then return end
    view:load(self, item, function()
        view:render(self)
    end)
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
