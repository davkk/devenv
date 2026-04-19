vim.diagnostic.config {
    severity_sort = true,
    virtual_text = true,
    underline = true,
    update_in_insert = false,
    float = {
        source = true,
        show_header = true,
        style = "minimal",
        header = "",
        prefix = "",
        border = "solid",
    },
}

vim.api.nvim_create_user_command("ToggleDiagnostics", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, {})

local sev_types = { "E", "W", "I", "H" }
local qf_id = nil
local qf_title = "Diagnostics"

local function get_qf_nr_for_id(id)
    local last = vim.fn.getqflist({ nr = "$" }).nr
    for i = 1, last do
        local info = vim.fn.getqflist { nr = i, id = 0 }
        if info.id == id then
            return i
        end
    end
    return nil
end

vim.keymap.set("n", "<leader>dq", function()
    if qf_id then
        local nr = get_qf_nr_for_id(qf_id)
        if nr then
            vim.cmd(("silent %dchistory"):format(nr))
        else
            qf_id = nil
        end
    end
    vim.cmd.copen()
end, { silent = true })

vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = vim.api.nvim_create_augroup("user.diagnostic", { clear = true }),
    callback = function()
        local diagnostics = vim.diagnostic.get(nil)
        table.sort(diagnostics, function(a, b)
            if a.severity ~= b.severity then
                return a.severity < b.severity
            end
            return a.lnum < b.lnum
        end)

        local items = {}
        for _, diag in ipairs(diagnostics) do
            table.insert(items, {
                bufnr = diag.bufnr,
                lnum = diag.lnum + 1,
                col = diag.col + 1,
                type = sev_types[diag.severity - 1],
                text = diag.message,
            })
        end

        if qf_id then
            vim.fn.setqflist({}, "r", { id = qf_id, title = qf_title, items = items })
            if not get_qf_nr_for_id(qf_id) then
                qf_id = nil
            end
        end

        if not qf_id then
            vim.fn.setqflist({}, " ", { title = qf_title, items = items })
            local last_nr = vim.fn.getqflist({ nr = "$" }).nr
            qf_id = vim.fn.getqflist({ nr = last_nr, id = 0 }).id
        end
    end,
})
