local M = {}

local utils = require "core.utils"

---@class lint.Linter
---@field cmd (string | fun(bufnr: integer): string)[]
---@field pattern string[]
---@field stream string | nil
---@field parser fun(bufnr: integer, output: string): vim.Diagnostic[]
---@field root_markers (string[] | fun(name: string): boolean)?

---@type lint.Linter[]
local linters = {}

---@param name string
---@param linter lint.Linter
function M.config(name, linter)
    linters[name] = linter
end

---@param name string
---@param linter lint.Linter
local function start_linter(name, linter)
    local namespace = vim.api.nvim_create_namespace("user.linter." .. name)

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
        desc = name,
        group = vim.api.nvim_create_augroup("user.linter", { clear = false }),
        pattern = linter.pattern,
        callback = function(event)
            if linter.root_markers ~= nil then
                local check_markers = vim.fs.root(event.buf, linter.root_markers) ~= nil
                if not check_markers then
                    return
                end
            end

            ---@type string[]
            local cmd = utils.tbl_copy(linter.cmd)
            for idx, arg in ipairs(linter.cmd) do
                if type(arg) == "function" then
                    cmd[idx] = arg(event.buf)
            end
                end

            if vim.fn.executable(cmd[1]) == 0 then
                return
            end

            vim.system(
                cmd,
                { text = true },
                vim.schedule_wrap(function(output)
                    local stream = linter.stream and output[linter.stream] or output.stdout
                    if not stream then
                        vim.notify("Wrong stream specified in " .. name .. " config", vim.log.levels.ERROR)
                        return
                    end

                    local diagnostics = linter.parser(event.buf, stream)
                    vim.diagnostic.set(namespace, event.buf, diagnostics, {
                        underline = true,
                        virtual_text = true,
                        signs = true,
                    })
                end)
            )
        end,
    })

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        desc = ("clear %s"):format(name),
        group = vim.api.nvim_create_augroup("user.linter.clear." .. name, { clear = true }),
        pattern = linter.pattern,
        callback = function(event)
            vim.diagnostic.set(namespace, event.buf, {})
        end,
    })
end

---@param linter_names string[]
function M.enable(linter_names)
    for _, name in ipairs(linter_names) do
        local linter = linters[name]
        if not linter then
            vim.notify(("Linter %s is not configured"):format(name), vim.log.levels.WARN)
            return
        end
        start_linter(name, linter)
    end
end

return M
