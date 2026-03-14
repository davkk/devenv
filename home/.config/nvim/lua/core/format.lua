local M = {}

local utils = require "core.utils"

---@class format.Formatter
---@field cmd (string | fun(bufnr: integer): string)[]
---@field filetypes string[]
---@field root_markers (string[] | fun(name: string): boolean)?

---@type table<string, format.Formatter>
local formatters = {}

---@param bufnr integer
---@param hunks integer[][]
---@param formatted string[]
local function apply_hunks(bufnr, hunks, formatted)
    for i = #hunks, 1, -1 do
        local fi, fc, ti, tc = unpack(hunks[i])

        local new_lines = {}
        for j = ti, ti + tc - 1 do
            table.insert(new_lines, formatted[j])
        end

        if fc == 0 then
            table.insert(new_lines, 1, vim.api.nvim_buf_get_lines(bufnr, fi - 1, fi, false)[1])
        end

        local start_row = fi - 1
        local end_row = fi + math.max(fc, 1) - 1
        vim.api.nvim_buf_set_lines(bufnr, start_row, end_row, false, new_lines)
    end
end

local function get_formatter(bufnr)
    local ft = vim.bo[bufnr].filetype
    for _, formatter in pairs(formatters) do
        for _, filetype in ipairs(formatter.filetypes) do
            local check_markers = false
            if formatter.root_markers ~= nil then
                check_markers = vim.fs.root(bufnr, formatter.root_markers) ~= nil
            end

            if filetype == ft and check_markers then
                return formatter
            end
        end
    end
    -- TODO: add log file
end

---@param formatter format.Formatter
function M.config(formatter)
    return table.insert(formatters, formatter)
end

---@param bufnr integer?
---@return boolean
function M.external_format(bufnr)
    bufnr = bufnr or 0

    local formatter = get_formatter(bufnr)
    if not formatter then
        return false
    end

    ---@type string[]
    local cmd = utils.tbl_copy(formatter.cmd)
    for idx, arg in ipairs(formatter.cmd) do
        if type(arg) == "function" then
            cmd[idx] = arg(bufnr)
        end
    end

    if vim.fn.executable(cmd[1]) == 0 then
        return false
    end

    local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local old_text = table.concat(old_lines, "\n")

    local sys_obj = vim.system(
        cmd,
        { text = true, stdin = true },
        vim.schedule_wrap(
            ---@param output vim.SystemCompleted
            function(output)
                if output.code == 0 and output.stdout then
                    local diff = vim.text.diff(old_text, output.stdout, {
                        algorithm = "histogram",
                        result_type = "indices",
                    }) ---@cast diff integer[][]?

                    if diff and #diff > 0 then
                        local new_lines = vim.split(output.stdout, "\n", { trimempty = false })
                        apply_hunks(bufnr, diff, new_lines)
                    end
                elseif output.stderr then
                    vim.notify(output.stderr, vim.log.levels.ERROR)
                end
            end
        )
    )

    sys_obj:write(old_text)
    sys_obj:write(nil)

    local ok, code = sys_obj:wait(4000)
    if not ok then
        vim.notify(code or "Unknown error", vim.log.levels.ERROR)
        return false
    end

    return true
end

---@param bufnr integer?
---@return boolean
function M.lsp_format(bufnr)
    bufnr = bufnr or 0

    local clients = vim.lsp.get_clients { bufnr = bufnr, method = "textDocument/formatting" }
    if #clients == 0 then
        return false
    end

    local params = vim.lsp.util.make_formatting_params()
    vim.lsp.buf_request(bufnr, "textDocument/formatting", params, function(err, result, ctx)
        if err or not result then
            vim.notify(("LSP formatting failed: %s"):format(err or "Unknown error"), vim.log.levels.ERROR)
            return
        end
        vim.lsp.util.apply_text_edits(
            result,
            ctx.bufnr,
            ctx.client_id and vim.lsp.get_client_by_id(ctx.client_id).offset_encoding or "utf-8"
        )
        vim.cmd.redraw()
    end)

    return true
end

return M
