local M = {}

---@param trigger string
---@param body string | string[]
---@param opts? vim.keymap.set.Opts
function M.add(trigger, body, opts)
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

return M
