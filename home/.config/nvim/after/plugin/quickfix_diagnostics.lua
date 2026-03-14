local sev = vim.diagnostic.severity
local type = {
    [sev.ERROR] = "E",
    [sev.WARN] = "W",
    [sev.HINT] = "H",
    [sev.INFO] = "I",
}

--- @param title string
--- @return integer?
local function get_qf_id_for_title(title)
    local lastqflist = vim.fn.getqflist { nr = "$" }
    for i = 1, lastqflist.nr do
        local qflist = vim.fn.getqflist { nr = i, id = 0, title = 0 }
        if qflist.title == title then
            return qflist.id
        end
    end
    return nil
end

local qf_id = nil
local qf_title = "Diagnostics"

local function set_qf_diagnostics()
    local diagnostics = vim.diagnostic.get(nil)

    if #diagnostics > 0 then
        table.sort(diagnostics, function(a, b)
            if a.severity == b.severity then
                return a.lnum < b.lnum
            end
            return a.severity < b.severity
        end)
    end

    local items = {}
    for _, diag in ipairs(diagnostics) do
        table.insert(items, {
            bufnr = diag.bufnr,
            lnum = diag.lnum + 1,
            col = diag.col + 1,
            type = type[diag.severity],
            text = diag.message,
        })
    end

    vim.fn.setqflist({}, qf_id and "r" or " ", {
        title = qf_title,
        items = items,
        id = qf_id,
    })

    if qf_id == nil then
        qf_id = get_qf_id_for_title(qf_title)
    end
end

vim.keymap.set("n", "<leader>dq", function()
    if qf_id ~= nil then
        vim.cmd(("silent %dchistory"):format(qf_id))
        vim.cmd.copen()
    end
end, { silent = true })

local utils = require "core.utils"

vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = vim.api.nvim_create_augroup("user.diagnostic", {}),
    callback = utils.debounce(set_qf_diagnostics, 300),
})
