local M = {}

---@param drafts gh-issues.DraftComment[]
function M.confirm(drafts)
    local float = require("gh-issues.helpers").create_floating_window()
    local renderer = require("gh-issues.ui.renderer")

    local navigation_markers = renderer.confirm(drafts)
end

return M
