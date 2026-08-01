local M = {}

---@param loc table link_location entry with path, line, diff fields
---@param branch string the other PR's branch name
function M.open(loc, branch)
    -- find the target window (non-qf)
    local target_win = nil
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "qf" then
            target_win = win
            break
        end
    end

    -- fallback to qf window if no other window found
    if not target_win then
        target_win = vim.api.nvim_list_wins()[1]
    end

    vim.api.nvim_set_current_win(target_win)
    vim.cmd(string.format("edit +%d %s", loc.line or 1, loc.path))
    vim.cmd("diffthis")

    -- get the other branch's version of the file
    local git_path = string.format("origin/%s:%s", branch, loc.path)
    local result = vim.system({ "git", "show", git_path }):wait()
    if result.code ~= 0 then
        vim.notify("gh-issues: git show failed: " .. result.stderr, vim.log.levels.ERROR)
        vim.cmd("diffoff")
        return
    end

    -- load it into a scratch buffer
    local tmp_buf = vim.api.nvim_create_buf(false, true)
    local filetype = vim.bo[vim.api.nvim_get_current_buf()].filetype
    vim.api.nvim_buf_set_lines(tmp_buf, 0, -1, false, vim.split(result.stdout, "\n"))
    vim.bo[tmp_buf].filetype = filetype
    vim.bo[tmp_buf].modifiable = false

    vim.cmd("vert sbuffer " .. tmp_buf)
    vim.cmd("diffthis")

    -- focus the local file
    vim.api.nvim_set_current_win(target_win)
end

return M
