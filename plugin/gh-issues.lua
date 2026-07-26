if vim.g.gh_issues_loaded then
    return
end
vim.g.gh_issues_loaded = true

local gh = require("gh-issues.api")

vim.api.nvim_create_user_command("GhIssues", function(opts)
    gh.open_issues(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("GhPullRequest", function(opts)
    gh.open_pull_request(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("GhCleanCache", function()
    gh.clean_cache()
end, {})
