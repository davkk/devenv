local utils = require "core.utils"
local group = vim.api.nvim_create_augroup("user.statusline", { clear = true })

-- FILE PATH
---@return string
local function filepath()
    local path = vim.fn.expand "%:p:~"

    if #path == 0 then
        return "[No Name]"
    end

    path = utils.shorten_path(path, vim.o.columns / 2)

    local name = vim.fn.expand "%"
    local is_new_file = name ~= "" and vim.bo.buftype == "" and vim.fn.filereadable(name) == 0

    return "[" .. path .. (is_new_file and "][New]" or "]") .. "%r%m"
end

-- LSP DIAGNOSTICS
---@return string
local function lsp_diagnostics()
    local sev = vim.diagnostic.severity
    local levels = {
        error = sev.ERROR,
        warn = sev.WARN,
        info = sev.INFO,
        hint = sev.HINT,
    }

    local counts = {}
    for k, level in pairs(levels) do
        counts[k] = vim.tbl_count(vim.diagnostic.get(0, { severity = level }))
    end

    local error = ""
    local warn = ""
    local hint = ""
    local info = ""

    if counts.error > 0 then
        error = " %#DiagnosticSignError#E" .. counts.error
    end
    if counts.warn > 0 then
        warn = " %#DiagnosticSignWarn#W" .. counts.warn
    end
    if counts.hint > 0 then
        hint = " %#DiagnosticSignHint#H" .. counts.hint
    end
    if counts.info > 0 then
        info = " %#DiagnosticSignInfo#I" .. counts.info
    end

    return error .. warn .. hint .. info .. "%##"
end

-- CURSOR LOCATION
---@return string
local function location()
    local col = vim.fn.virtcol "."
    local row = vim.fn.line "."
    return string.format("[%3d:%-3d]", row, col)
end

-- GIT DIFF
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

-- LSP PROGRESS LOADER
local loader = { "∙  ", "∙∙ ", "∙∙∙", " ∙∙", "  ∙", "  " }
local loader_idx = 1
local loader_timer = nil
local lsp_loading = false

local function start_animation()
    if loader_timer then
        return
    end
    loader_timer = vim.uv.new_timer()
    if loader_timer ~= nil then
        loader_timer:start(
            0,
            120,
            vim.schedule_wrap(function()
                if lsp_loading then
                    loader_idx = (loader_idx % #loader) + 1
                    vim.cmd.redrawstatus()
                end
            end)
        )
    end
end

local function stop_animation()
    if loader_timer then
        loader_timer:stop()
        loader_timer:close()
        loader_timer = nil
    end
    loader_idx = 1
end

---@return string
local function lsp_progress()
    if not lsp_loading and #vim.lsp.get_clients() > 0 then
        lsp_loading = true
        start_animation()
    end
    return lsp_loading and loader[loader_idx] or ""
end

vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    pattern = "*",
    callback = function(args)
        local value = args.data.params.value
        if value.kind == "begin" then
            lsp_loading = true
            start_animation()
        elseif value.kind == "end" then
            lsp_loading = false
            stop_animation()
            vim.cmd.redrawstatus()
        end
    end,
})

StatusLine = {}

---@return string
function StatusLine.build_statusline()
    return table.concat {
        filepath(),
        "  ",
        git_changes(),
        "%=",
        lsp_loading and lsp_progress() or lsp_diagnostics(),
        "  ",
        location(),
    }
end

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "InsertLeave", "DiagnosticChanged" }, {
    group = group,
    callback = function()
        vim.opt.statusline = "%!v:lua.StatusLine.build_statusline()"
    end,
})
