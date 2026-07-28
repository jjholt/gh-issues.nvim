local M = {}

function M.setup(ui)
    vim.keymap.set("n", "q", function()
        ui:close()
    end, { buffer = ui.buf })

    vim.keymap.set("n", "<CR>", function()
        local cursor_line = vim.api.nvim_win_get_cursor(ui.win)[1] - 1 -- 0-indexed
        for _, loc in ipairs(ui.link_locations) do
            if loc.lnum == cursor_line then
                require("gh-issues.ui.diagnostics").set(ui.reviews)
                ui:close()
                vim.cmd(string.format("edit +%d %s", loc.line or 1, loc.path))
                return
            end
        end
    end, { buffer = ui.buf })

    local config = require("gh-issues").config
    vim.keymap.set("n", config.keybinds.add_to_quickfix, function()
        if not ui.reviews or #ui.reviews == 0 then
            vim.notify("gh-issues: no reviews to add", vim.log.levels.INFO)
            return
        end
        require("gh-issues.ui.diagnostics").set(ui.reviews)
        ui:close()
        require("gh-issues.quickfix").populate_reviews(ui.reviews)
    end, { buffer = ui.buf })
end

return M
