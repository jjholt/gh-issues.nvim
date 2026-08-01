local Issue = require("gh-issues.issue")

---@class gh-issues.PRFile
---@field filename string
---@field ranges number[][] list of {start_line, end_line} pairs from the patch hunks

---@class gh-issues.PullRequest: gh-issues.Issue
---@field reviews gh-issues.Review[]|nil
---@field draft boolean
---@field conflicting_files string[]|nil files that overlap with other PRs
local PullRequest = setmetatable({}, { __index = Issue })
PullRequest.__index = PullRequest

---@class gh-issues.Review: gh-issues.Comment
---@field path string relative path to the file e.g. "lua/gh-issues/issue.lua"
---@field line number|nil line number in the file the comment applies to
---@field start_line number|nil first line for multi-line comments
---@field side string "LEFT" or "RIGHT" side of the diff
---@field state string
---@field draft boolean
---@field merged boolean
---@field diff_hunk string the diff context the comment was made on
---@field html_url string link to the comment on GitHub
---@field assignees string[]
---@field in_reply_to_id number|nil id of the parent comment if this is a reply
---@field id number needed so other comments can reference this as in_reply_to_id
---@field fetch_reviews fun(self: gh-issues.Issue): gh-issues.Review[]|nil

---@param raw table
---@param repository gh-issues.Repository
---@param url string
---@class gh-issues.PullRequest
function PullRequest.new(raw, repository, url)
    local self = Issue.new(raw, repository, url)
    setmetatable(self, PullRequest)
    ---@cast self gh-issues.PullRequest
    self.reviews = nil
    self.draft = raw.draft
    self.conflicting_files = nil
    return self
end

---@param patch string
---@return number[][] list of {start_line, end_line} pairs
local function parse_ranges(patch)
    local ranges = {}
    for hunk in patch:gmatch("@@[^@]+@@") do
        -- +start,count or just +start (count defaults to 1)
        local start, count = hunk:match("%+(%d+),(%d+)")
        if not start then
            start = hunk:match("%+(%d+)")
            count = "1"
        end
        if start then
            local s = tonumber(start)
            local c = tonumber(count)
            -- end is inclusive, expand by 1 on each side for adjacency
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
            -- overlap if not (ra ends before rb starts or rb ends before ra starts)
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
---@return string[] overlapping filenames
function PullRequest.find_overlapping_files(a, b)
    -- index b by filename for O(n) lookup
    local b_index = {}
    for _, file in ipairs(b) do
        b_index[file.filename] = file.ranges
    end

    local overlapping = {}
    for _, file in ipairs(a) do
        local b_ranges = b_index[file.filename]
        if b_ranges then
            if #file.ranges == 0 or #b_ranges == 0 then
                -- no patch info (e.g. binary files) — flag on filename match alone
                table.insert(overlapping, file.filename)
            elseif ranges_overlap(file.ranges, b_ranges) then
                table.insert(overlapping, file.filename)
            end
        end
    end

    return overlapping
end

---@param remote string
---@return gh-issues.PullRequest[]|nil
PullRequest.fetch = function(remote)
    local repository = require("gh-issues.git").new(remote)
    if not repository then return nil end

    local url = repository:url()
    local token = repository:get_token()
    if not token then return nil end

    local t0 = vim.loop.hrtime()
    local data = require("gh-issues.http").get(url .. "pulls", token)
    local elapsed = (vim.loop.hrtime() - t0) / 1e6
    vim.notify(string.format("gh-issues: fetch took %.0fms, got %d PRs", elapsed, data and #data or 0), vim.log.levels.INFO)


    -- local data = require("gh-issues.http").get(url .. "pulls", token)
    if not data then return nil end

    local issues = {}
    for _, datum in ipairs(data) do
        local issue = PullRequest.new(datum, repository, url)
        table.insert(issues, issue)
    end
    return issues
end

---@return gh-issues.Review[]|nil
function PullRequest:fetch_reviews()
    if self.reviews then
        return self.reviews
    end

    local token = self.repository:get_token()
    if not token then return nil end

    local id = self.number
    local url = self.url .. string.format("pulls/%d/comments", id)
    -- local data = require("gh-issues.http").get(url, token)

    local t0 = vim.loop.hrtime()
    local data = require("gh-issues.http").get(url, token)
    local elapsed = (vim.loop.hrtime() - t0) / 1e6
    vim.notify(string.format("gh-issues: fetch_reviews took %.0fms, got %d reviews", elapsed, data and #data or 0), vim.log.levels.INFO)


    if not data then return nil end

    local reviews = {}
    for _, raw in ipairs(data) do
        local assignees = {}
        if raw.assignees then
            for _, user in ipairs(raw.assignees) do
                table.insert(assignees, user.login)
            end
        end

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

    return reviews
end

return PullRequest
