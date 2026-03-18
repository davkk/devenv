local M = {}

function M.fn(f, ...)
    local args = { ... }
    return function(...)
        return f(unpack(args), ...)
    end
end

---@param bufnr integer
---@return string
function M.relative_path(bufnr)
    local cwd = vim.fn.getcwd()
    local fullpath = vim.api.nvim_buf_get_name(bufnr)
    return fullpath:sub(#cwd + 2)
end

---@param path string
---@param max_len number
---@return string
function M.shorten_path(path, max_len)
    local len = #path
    local sep = package.config:sub(1, 1)
    if len <= max_len then
        return path
    end
    local segments = vim.split(path, sep)
    for idx = 1, #segments - 1 do
        if len <= max_len then
            break
        end
        local segment = segments[idx]
        local shortened = segment:sub(1, vim.startswith(segment, ".") and 2 or 1)
        segments[idx] = shortened
        len = len - (#segment - #shortened)
    end
    return table.concat(segments, sep)
end

---@param name string
---@return string
function M.node_modules(name)
    local path = vim.fs.find("node_modules/.bin/" .. name, { upward = true })
    return path[1] or name
end

---@param fn function
---@param delay number
---@return function
function M.debounce(fn, delay)
    local timer = nil
    return function(...)
        if timer then
            vim.fn.timer_stop(timer)
        end
        local args = { ... }
        timer = vim.fn.timer_start(delay, function()
            fn(unpack(args))
        end)
    end
end

---@generic T
---@param tbl T
---@return T
function M.tbl_copy(tbl)
    if not tbl then
        return tbl
    end
    local new = {}
    for idx, value in ipairs(tbl) do
        new[idx] = value
    end
    return new
end

---@generic T
---@param original T[]
---@param value T
---@return T | nil
function M.tbl_append(original, value)
    if not original then
        return nil
    end
    local new = M.tbl_copy(original)
    if new then
        table.insert(new, value)
    end
    return new
end

---@param source_path string
function M.add_local_plugin(source_path)
    local name = vim.fn.fnamemodify(source_path, ":t")
    local path = vim.fs.joinpath(vim.fn.stdpath "data", "site", "pack", "local", "start")
    local target = vim.fs.joinpath(path, name)
    if not vim.uv.fs_stat(target) then
        local source = vim.fn.fnamemodify(source_path, ":p")
        vim.fn.mkdir(path, "p")
        vim.uv.fs_symlink(source, target, { junction = true })
    end
end

return M
