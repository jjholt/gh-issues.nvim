local M = {}

local memory_cache = {}
local TTL = 300  -- 5 minutes in seconds

---
---@param owner string
---@param repo string
---@param kind string
---@return string
function M.make_key(owner, repo, kind)
    return string.format("%s/%s/%s", owner, repo, kind)
end


---@param key string
---@return string
local function cache_dir(key)
    return string.format("%s/gh-issues/%s", vim.fn.stdpath("cache"), key)
end


---@param dir_key string
---@param id number|string
---@param data table
function M.set(dir_key, id, data)
    -- write to memory
    local key = dir_key .. tostring(id)
    memory_cache[key] = {
        data = data,
        time = os.time()
    }


    -- write to disk
    local dir = cache_dir(dir_key)
    local path = dir .. tostring(id) .. ".json"

    vim.fn.mkdir(dir, "p")
    local file = io.open(path, "w")
    if not file then
        vim.notify("gh-issues: could not write cache file", vim.log.levels.ERROR)
        return
    end
    file:write(vim.json.encode( {
        data = data,
        time = os.time()
    }))
    file:close()
end

---@param dir_key string
---@param id number|string
---@return any|nil
function M.get(dir_key, id)
    local key = dir_key .. tostring(id)
    -- check memory first
    local mem = memory_cache[key]
    if mem and (os.time() - mem.time) < TTL then
        return mem.data
    end

    -- fall back to disk
    local dir = cache_dir(dir_key)
    local path = dir .. tostring(id) .. ".json"

    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()

    local ok, decoded = pcall(vim.json.decode, content)
    if not ok then return nil end

    if (os.time() - decoded.time) > TTL then
        return nil  -- expired
    end

    -- promote to memory cache
    memory_cache[key] = decoded
    return decoded.data
end

---@param key string
---@return table|nil
function M.get_all(key)
    local dir = string.format("%s/gh-issues/%s", vim.fn.stdpath("cache"), key)
    if vim.fn.isdirectory(dir) == 0 then return nil end

    local files = vim.fn.readdir(dir)
    if #files == 0 then return nil end

    local results = {}
    for _, file in ipairs(files) do
        local id = file:match("^(.+)%.json$")
        if id then
            local data = M.get(key, id)
            if data then table.insert(results, data) end
        end
    end

    return #results > 0 and results or nil
end

---@param key string
function M.invalidate(key)
    memory_cache[key] = nil
    os.remove(cache_dir(key))
end

function M.invalidate_all()
    memory_cache = {}
    vim.fn.delete(vim.fn.stdpath("cache") .. "/gh-issues", "rf")
end

return M
