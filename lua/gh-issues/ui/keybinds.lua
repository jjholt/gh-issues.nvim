local M = {}
local config = require("gh-issues").config
local keybinds = config.keybinds

M.binds = {
    {
        key = keybinds.initiate_review,
        desc = "Initiate a review",
    },
    {
        key = keybinds.add_to_quickfix,
        desc = "View current review",
    },
    {
        key = keybinds.nav_review_comments[1],
        desc = "Next review comment",
    },
    {
        key = keybinds.nav_review_comments[2],
        desc = "Previous review comment",
    },
    {
        key = config.keybinds.find_conflicts,
        desc = "Find conflicts",
    },
    {
        key = "q",
        desc = "Quit",
    },
}

function M.setup(ui)
    -- Close window by pressing q
    vim.keymap.set("n", "q", function()
        ui:close()
    end, { buffer = ui.buf })

    vim.keymap.set("n", "<CR>", function()
        local cursor_line = vim.api.nvim_win_get_cursor(ui.win)[1] - 1
        for _, loc in ipairs(ui.link_locations) do
            if loc.lnum == cursor_line then
                if loc.diff then
                    ui:close()
                    require("gh-issues.ui.diff").open(loc, ui.issue.branch)
                else
                    require("gh-issues.ui.diagnostics").set(ui.view.reviews)
                    ui:close()
                    vim.cmd("cclose")
                    vim.cmd(string.format("edit +%d %s", loc.line or 1, loc.path))
                end
                return
            end
        end
    end, { buffer = ui.buf })

    -- Populate quickfix and add diagnostics to the source files. <C-a> behaviour in PR window
    vim.keymap.set("n", keybinds.add_to_quickfix, function()
        if not ui.view.reviews or #ui.view.reviews == 0 then
            vim.notify("gh-issues: no reviews to add", vim.log.levels.INFO)
            return
        end
        require("gh-issues.ui.diagnostics").set(ui.view.reviews)
        require("gh-issues.quickfix").clear()
        require("gh-issues.quickfix").populate_reviews(ui.view.reviews, true)
        vim.notify(vim.inspect(ui.view.issue.base), vim.log.levels.INFO)

        ui:close()
    end, { buffer = ui.buf })

    -- Populate quickfix with modified files, add diagnostics to the source files. <C-r> behaviour in PR window
    vim.keymap.set("n", config.keybinds.initiate_review, function()
        -- Populate files with existing reviews
        if ui.view.reviews then
            require("gh-issues.ui.diagnostics").set(ui.view.reviews)
        end
        require("gh-issues.quickfix").clear()
        require("gh-issues.quickfix").populate_reviews(ui.view.reviews, false)

        local issue = ui.view.issue
        if issue then
            issue:fetch_files(function(files)
                require("gh-issues.quickfix").populate_pr_files(files)
            end)
        end
        ui:close()
    end, { buffer = ui.buf })

    -- Quick navigation between review comments
    vim.keymap.set("n", config.keybinds.nav_review_comments[1], function()
        if not ui.view.review_navigation_markers or #ui.view.review_navigation_markers == 0 then return end
        local cursor_line = vim.api.nvim_win_get_cursor(ui.win)[1] - 1 -- 0-indexed
        for _, lnum in ipairs(ui.view.review_navigation_markers) do
            if lnum > cursor_line then
                vim.api.nvim_win_set_cursor(ui.win, { lnum + 1, 0 }) -- 1-indexed
                return
            end
        end
        -- wrap: go to first
        vim.api.nvim_win_set_cursor(ui.win, { ui.view.review_navigation_markers[1] + 1, 0 })
    end, { buffer = ui.buf })

    vim.keymap.set("n", config.keybinds.nav_review_comments[2], function()
        if not ui.view.review_navigation_markers or #ui.view.review_navigation_markers == 0 then return end
        local cursor_line = vim.api.nvim_win_get_cursor(ui.win)[1] - 1 -- 0-indexed
        for i = #ui.view.review_navigation_markers, 1, -1 do
            if ui.view.review_navigation_markers[i] < cursor_line then
                vim.api.nvim_win_set_cursor(ui.win, { ui.view.review_navigation_markers[i] + 1, 0 }) -- 1-indexed
                return
            end
        end
        -- wrap: go to last
        vim.api.nvim_win_set_cursor(ui.win,
            { ui.view.review_navigation_markers[#ui.view.review_navigation_markers] + 1, 0 })
    end, { buffer = ui.buf })

    vim.keymap.set("n", config.keybinds.find_conflicts, function()
        if not ui.view.issue then
            vim.notify("gh-issues: no PR loaded", vim.log.levels.WARN)
            return
        end

        vim.notify("gh-issues: searching for conflicts...", vim.log.levels.INFO)

        local repository = ui.view.issue.repository
        local url = repository:url()
        local token = repository:get_token()
        if not token then return end

        local data = require("gh-issues.http").get(url .. "pulls", token)
        if not data then return end

        local PullRequest = require("gh-issues.pull_request")
        local all_prs = {}
        for _, datum in ipairs(data) do
            table.insert(all_prs, PullRequest.new(datum, repository, url))
        end

        require("gh-issues.conflicts").find(ui.view.issue, all_prs, function(conflicting)
            if #conflicting == 0 then
                vim.notify("gh-issues: no conflicting PRs found", vim.log.levels.INFO)
                return
            end
            ui:close()
            vim.notify(string.format("gh-issues: found %d conflicting PR(s)", #conflicting), vim.log.levels.WARN)
            require("gh-issues.quickfix").populate_issues(conflicting)
        end)
    end, { buffer = ui.buf })
end

return M
