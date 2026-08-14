local M = {}

---@param iso_string string
local function parse_iso8601(iso_string)
    local y, mo, d, h, mi, s =
        iso_string:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    return os.time({
        year = y,
        month = mo,
        day = d,
        hour = h,
        min = mi,
        sec = s,
    })
end

---@param pr gh-issues.PullRequest|gh-issues.Issue
---@param days integer
---@return boolean
local function within_max_age(pr, days)
    local ts = parse_iso8601(pr.updated_at or pr.created_at)
    local age = (os.time() - ts) / 86400 -- s in day
    return age <= days
end

---@param pr gh-issues.PullRequest|gh-issues.Issue
---@param username string
---@return boolean
local function is_assigned(pr, username)
    return vim.list_contains(pr.assignees, username)
end

---@param pr gh-issues.PullRequest
---@param username string
---@return boolean
local function is_mentioned(pr, username)
    local mention = "@" .. username
    -- requested reviewer
    for _, name in ipairs(pr.request_reviewers or {}) do
        if name == username then return true end
    end

    -- @mention in body
    if pr.body and pr.body:find(mention, 1, true) then return true end

    -- @mention in comment
    for _, comment in ipairs(pr.comments or {}) do
        if comment.body and comment.body:find(mention, 1, true) then
            return true
        end
    end
    return true
end

---@param pr gh-issues.PullRequest
---@param threshold number
---@return boolean
local function is_sufficiently_reviewed(pr, threshold)
    local states = {}
    for _, review in ipairs(pr.reviews or {}) do
        if review.user then
            states[review.user] = review.state
        end
    end

    local approvals = 0
    for _, state in ipairs(states) do
        if state == "APPROVED" then
            approvals = approvals + 1
        end
    end
    return approvals >= threshold
end


local config = require("gh-issues").config
-- local ui = require("gh-issues.filter.ui")
-- require("gh-issues.filter.filter")

---@param data gh-issues.PullRequest[]
---@param username string
---@return gh-issues.PullRequest|gh-issues.Issue
function M.filter(data, username)
    local has_or_filter = config.filters.assigned or config.filters.mentioned or
    config.filters.sufficiently_reviwed.filter

    local result = {}
    for _, pr in ipairs(data) do
        local keep = false
        if config.filters.max_age_days > 0 then
            if not within_max_age(pr, config.filters.max_age_days) then
                goto continue
            end
        end

        -- Or gate:
        if has_or_filter then
            if config.filters.assigned then
                if is_assigned(pr, username) then
                    keep = true
                    goto continue
                end
            end

            if config.filters.mentioned then
                if is_mentioned(pr, username) then
                    keep = true
                    goto continue
                end
            end
            if config.filters.sufficiently_reviwed.filter then
                local is_suff_reviewed = is_sufficiently_reviewed(pr, config.filters.sufficiently_reviwed.number)
                if not is_suff_reviewed then
                    keep = true
                    goto continue
                end
            end
        end

        ::continue::
        if keep then
            result[#result + 1] = pr
        end
    end
    return result
end

return M
