local M = {}
M.check = function()
    vim.health.start("gh-issues")

    -- check gh cli is installed
    if vim.fn.executable("gh") == 0 then
        vim.health.error("github cli is not installed")
        return
    end
    vim.health.ok("gh cli is installed")

    -- check gh cli is authenticated
    local handle = io.popen("gh auth status 2>&1")
    if not handle then
        vim.health.error("could not run gh auth status")
        return
    end

    local result = handle:read("*a")
    handle:close()

    if result:match("not logged in") or result == "" then
        vim.health.error("gh cli is not authenticated", "run `gh auth login`")
        return
    end

    vim.health.ok("gh cli is authenticated")
end
return M
