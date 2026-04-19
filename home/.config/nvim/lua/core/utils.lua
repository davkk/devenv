local M = {}

---@param trigger string
---@param body string | string[]
---@param opts? vim.keymap.set.Opts
function M.add_snippet(trigger, body, opts)
    vim.keymap.set("ia", trigger, function()
        -- only accept <C-]> as trigger key
        local c = vim.fn.nr2char(vim.fn.getchar(0))
        if c ~= "" then
            vim.api.nvim_feedkeys(trigger .. c, "i", true)
            return
        end
        if type(body) == "table" then
            body = table.concat(body, "\n")
        end
        vim.snippet.expand(body)
    end, opts)
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
