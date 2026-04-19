function Format()
    local formatprg = vim.bo.formatprg
    if not formatprg or formatprg == "" then
        return 0
    end
    local start_lnum = vim.v.lnum
    local end_lnum = start_lnum + vim.v.count - 1
    local lines = vim.api.nvim_buf_get_lines(0, start_lnum - 1, end_lnum, true)
    local cmd = vim.split(vim.fn.expandcmd(formatprg), " ")
    local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local output = vim.system(cmd, { stdin = lines, cwd = cwd }):wait()
    if output.code ~= 0 then
        vim.schedule(function()
            vim.notify(output.stderr, vim.log.levels.ERROR)
        end)
        return 0
    end
    local formatted = vim.split(output.stdout, "\n", { trimempty = true })
    vim.api.nvim_buf_set_lines(0, start_lnum - 1, end_lnum, true, formatted)
    return 0
end

vim.bo.formatexpr = "v:lua.Format()"

vim.keymap.set("n", "<leader>f", function()
    if vim.bo.formatprg ~= "" then
        local view = vim.fn.winsaveview()
        vim.cmd.normal { "gggqG", bang = true, mods = { silent = true, keepjumps = true } }
        vim.fn.winrestview(view)
    else
        vim.lsp.buf.format()
    end
end, { desc = "format buffer" })
