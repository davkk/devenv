local group = vim.api.nvim_create_augroup("user.statusline", { clear = true })

---@param path string
---@param max_len number
---@return string
local function shorten_path(path, max_len)
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

---@return string
local function filepath()
    local path = vim.fn.expand "%:p:~"
    if #path == 0 then
        return "[No Name]"
    end
    path = shorten_path(path, vim.o.columns / 2)
    local name = vim.fn.expand "%"
    local is_new_file = name ~= "" and vim.bo.buftype == "" and vim.fn.filereadable(name) == 0
    return "[" .. path .. (is_new_file and "][New]" or "]") .. "%r%m"
end

---@return string
local function lsp_diagnostics()
    return vim.diagnostic.status(0)
end

---@return string
local function location()
    local col = vim.fn.virtcol "."
    local row = vim.fn.line "."
    return string.format("[%4d:%-4d]", row, col)
end

---@param output string
---@return string
local function parse_shortstat(output)
    local diffs = {}
    local inserts = output:match "(%d+) insertions?" or nil
    if inserts ~= nil then
        table.insert(diffs, "+" .. inserts)
    end
    local deletions = output:match "(%d+) deletions?" or nil
    if deletions ~= nil then
        table.insert(diffs, "-" .. deletions)
    end
    local changed = output:match "(%d+) files? changed" or nil
    if changed ~= nil then
        table.insert(diffs, "~" .. changed)
    end
    return table.concat(diffs, " ")
end

---@param bufnr number
---@return string
local function get_git_diff(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)

    if
        vim.api.nvim_get_option_value("bufhidden", { buf = bufnr }) ~= ""
        or vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "nofile"
        or vim.fn.filereadable(name) ~= 1
    then
        return ""
    end

    local cwd = vim.fn.fnamemodify(name, ":h")
    local output = ""

    vim.fn.jobstart({ "git", "diff", "--shortstat", name }, {
        cwd = cwd,
        stdout_buffered = true,
        on_stdout = function(_, data)
            if data and #data > 0 then
                output = table.concat(data, "\n")
            end
        end,
        on_exit = function(_, exit_code)
            if exit_code == 0 then
                local ok, result = pcall(function()
                    return parse_shortstat(vim.trim(output))
                end)

                if ok then
                    vim.api.nvim_buf_set_var(bufnr, "git_changes", result)
                end
            end
        end,
    })
    return ""
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    callback = function(args)
        get_git_diff(args.buf)
    end,
})

---@return string
local function git_changes()
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, changes = pcall(vim.api.nvim_buf_get_var, bufnr, "git_changes")
    if ok and changes then
        return changes
    else
        return ""
    end
end

---@return string
function Statusline()
    return table.concat {
        filepath(),
        "  ",
        git_changes(),
        "%=",
        lsp_diagnostics(),
        "  ",
        location(),
    }
end

vim.o.statusline = "%!v:lua.Statusline()"
