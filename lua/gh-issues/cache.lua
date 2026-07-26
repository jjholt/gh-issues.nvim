local M = {}

local memory_cache = {}
local TTL = 300  -- 5 minutes in seconds

---@param key string
---@return string
local function cache_path(key)
    return vim.fn.stdpath("cache") .. "/gh-issues/" .. key .. ".json"
end

---@param key string
---@param data any
function M.set(key, data)
    -- write to memory
    memory_cache[key] = {
        data = data,
        time = os.time(),
    }

    -- write to disk
    local path = cache_path(key)
    vim.schedule(function ()
        vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")  -- create dirs if needed
    end)
    local file = io.open(path, "w")
    if not file then return end
    file:write(vim.json.encode({
        data = data,
        time = os.time(),
    }))
    file:close()
end

---@param key string
---@return any|nil
function M.get(key)
    -- check memory first
    local mem = memory_cache[key]
    if mem and (os.time() - mem.time) < TTL then
        return mem.data
    end

    -- fall back to disk
    local path = cache_path(key)
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
function M.invalidate(key)
    memory_cache[key] = nil
    os.remove(cache_path(key))
end

function M.invalidate_all()
    memory_cache = {}
    vim.fn.delete(vim.fn.stdpath("cache") .. "/gh-issues", "rf")
end

return M
