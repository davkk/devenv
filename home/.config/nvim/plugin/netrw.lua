vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 0
vim.g.netrw_cursor = 0
vim.g.netrw_altfile = 1
vim.g.netrw_sort_sequence = [[[\/]$,*]]

vim.keymap.set("n", "<C-e>", function()
    if vim.bo.filetype == "netrw" then
        vim.cmd.Rexplore()
    else
        local filename = vim.fn.expand "%:p:t"
        vim.cmd.Explore()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for idx, file in ipairs(lines) do
            if file == filename then
                vim.api.nvim_win_set_cursor(0, { idx, 0 })
                break
            end
        end
    end
end, { noremap = true, silent = true })
