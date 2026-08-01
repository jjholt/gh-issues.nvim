local Issue = require("gh-issues.issue")

---@class gh-issues.PRFile
---@field filename string
---@field ranges number[][] list of {start_line, end_line} pairs from the patch hunks

---@class gh-issues.PullRequest: gh-issues.Issue
---@field reviews gh-issues.Review[]|nil
---@field draft boolean
---@field conflicting_files string[]|nil
---@field branch string|nil
---@field diff table|nil
local PullRequest = setmetatable({}, { __index = Issue })
PullRequest.__index = PullRequest

---@class gh-issues.Review: gh-issues.Comment
---@field path string
---@field line number|nil
---@field start_line number|nil
---@field side string
---@field state string
---@field draft boolean
---@field merged boolean
---@field diff_hunk string
---@field html_url string
---@field assignees string[]
---@field in_reply_to_id number|nil
---@field id number

---@param raw table
---@param repository gh-issues.Repository
---@param url string
function PullRequest.new(raw, repository, url)
    local self = Issue.new(raw, repository, url)
    setmetatable(self, PullRequest)
    ---@cast self gh-issues.PullRequest
    self.reviews = nil
    self.draft = raw.draft
    self.conflicting_files = nil
    self.branch = raw.head and raw.head.ref or nil
    self.diff = nil
    return self
end

---@param patch string
---@return number[][]
local function parse_ranges(patch)
    local ranges = {}
    for hunk in patch:gmatch("@@[^@]+@@") do
        local start, count = hunk:match("%+(%d+),(%d+)")
        if not start then
            start = hunk:match("%+(%d+)")
            count = "1"
        end
        if start then
            local s = tonumber(start)
            local c = tonumber(count)
            table.insert(ranges, { s - 1, s + c })
        end
    end
    return ranges
end

---@param a number[][]
---@param b number[][]
---@return boolean
local function ranges_overlap(a, b)
    for _, ra in ipairs(a) do
        for _, rb in ipairs(b) do
            if not (ra[2] < rb[1] or rb[2] < ra[1]) then
                return true
            end
        end
    end
    return false
end

---@param callback fun(files: gh-issues.PRFile[]|nil)
function PullRequest:fetch_files(callback)
    local token = self.repository:get_token()
    if not token then
        callback(nil)
        return
    end

    local url = self.url .. string.format("pulls/%d/files", self.number)

    require("gh-issues.http").async_get(url, token, function(data)
        if not data then
            callback(nil)
            return
        end

        local files = {}
        for _, raw in ipairs(data) do
            local ranges = {}
            if raw.patch and raw.patch ~= vim.NIL then
                ranges = parse_ranges(raw.patch)
            end
            table.insert(files, {
                filename = raw.filename,
                ranges = ranges,
            })
        end

        callback(files)
    end)
end

---@param a gh-issues.PRFile[]
---@param b gh-issues.PRFile[]
---@return string[]
function PullRequest.find_overlapping_files(a, b)
    local b_index = {}
    for _, file in ipairs(b) do
        b_index[file.filename] = file.ranges
    end

    local overlapping = {}
    for _, file in ipairs(a) do
        local b_ranges = b_index[file.filename]
        if b_ranges then
            if #file.ranges == 0 or #b_ranges == 0 then
                table.insert(overlapping, file.filename)
            elseif ranges_overlap(file.ranges, b_ranges) then
                table.insert(overlapping, file.filename)
            end
        end
    end

    return overlapping
end

---@param callback fun(hunks: table|nil)
function PullRequest:fetch_diff(callback)
    if self.diff then
        callback(self.diff)
    end

    if not self.branch then
        vim.notify("gh-issues: no branch info on this PR", vim.log.levels.WARN)
        callback(nil)
        return
    end

    if not self.conflicting_files or #self.conflicting_files == 0 then
        callback(nil)
        return
    end

    -- blocking fetch so the diff has the latest remote state
    vim.notify(string.format("gh-issues: fetching origin/%s...", self.branch), vim.log.levels.INFO)
    local fetch = vim.system({ "git", "fetch", "origin", self.branch }):wait()
    if fetch.code ~= 0 then
        vim.notify("gh-issues: git fetch failed: " .. fetch.stderr, vim.log.levels.ERROR)
        callback(nil)
        return
    end
    vim.notify("gh-issues: fetch done: " .. (fetch.stdout ~= "" and fetch.stdout or "ok"), vim.log.levels.INFO)

    local cmd = {
        "git", "diff",
        string.format("HEAD...origin/%s", self.branch),
        "--",
    }
    for _, f in ipairs(self.conflicting_files) do
        table.insert(cmd, f)
    end

    vim.system(cmd, {}, function(out)
        vim.schedule(function()
            if out.code ~= 0 then
                vim.notify("gh-issues: git diff failed: " .. out.stderr, vim.log.levels.ERROR)
                callback(nil)
                return
            end

            -- parse hunks per file
            ---@type table<string, number[][]>
            local hunks_by_file = {}
            local current_file = nil

            for _, line in ipairs(vim.split(out.stdout, "\n")) do
                local file = line:match("^%+%+%+ b/(.+)$")
                if file then
                    current_file = file
                    hunks_by_file[current_file] = {}
                end

                if current_file then
                    local start, count = line:match("^@@[^%+]*%+(%d+),(%d+)")
                    if not start then
                        start = line:match("^@@[^%+]*%+(%d+)")
                        count = "1"
                    end
                    if start then
                        local s = tonumber(start)
                        local c = tonumber(count)
                        table.insert(hunks_by_file[current_file], { s, s + c - 1 })
                    end
                end
            end

            self.diff = hunks_by_file
            callback(hunks_by_file)
        end)
    end)
end

---@param callback fun(comments: gh-issues.Comment[]|nil)
function PullRequest:fetch_comments(callback)
    if self.comments then
        callback(self.comments)
        return
    end

    local token = self.repository:get_token()
    if not token then
        callback(nil)
        return
    end

    local url = self.url .. string.format("issues/%d/comments", self.number)
    require("gh-issues.http").async_get(url, token, function(data)
        if not data then
            callback(nil)
            return
        end

        local comments = {}
        for _, raw in ipairs(data) do
            table.insert(comments, {
                user = raw.user.login,
                body = raw.body,
                created_at = raw.created_at,
            })
        end

        self.comments = comments
        callback(comments)
    end)
end

---@param callback fun(reviews: gh-issues.Review[]|nil)
function PullRequest:fetch_reviews(callback)
    if self.reviews then
        callback(self.reviews)
        return
    end

    local token = self.repository:get_token()
    if not token then
        callback(nil)
        return
    end

    local url = self.url .. string.format("pulls/%d/comments", self.number)
    require("gh-issues.http").async_get(url, token, function(data)
        if not data then
            callback(nil)
            return
        end

        local reviews = {}
        for _, raw in ipairs(data) do
            table.insert(reviews, {
                user = raw.user.login,
                body = raw.body,
                created_at = raw.created_at,
                path = raw.path,
                line = raw.line,
                start_line = raw.start_line,
                side = raw.side,
                state = raw.state,
                diff_hunk = raw.diff_hunk,
                html_url = raw.html_url,
                in_reply_to_id = raw.in_reply_to_id,
                id = raw.id,
            })
        end

        self.reviews = reviews
        callback(reviews)
    end)
end

---@param remote string
---@return gh-issues.PullRequest[]|nil
PullRequest.fetch = function(remote)
    local repository = require("gh-issues.git").new(remote)
    if not repository then return nil end

    local url = repository:url()
    local token = repository:get_token()
    if not token then return nil end

    local data = require("gh-issues.http").get(url .. "pulls", token)
    if not data then return nil end

    local issues = {}
    for _, datum in ipairs(data) do
        local issue = PullRequest.new(datum, repository, url)
        table.insert(issues, issue)
    end
    return issues
end

return PullRequest
