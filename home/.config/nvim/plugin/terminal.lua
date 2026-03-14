vim.opt.guicursor:append "t:blinkon0-TermCursor"

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>")
vim.keymap.set("t", "<S-Space>", "<Space>")

vim.keymap.set("n", "<leader>st", function()
    vim.cmd.new()
    vim.api.nvim_win_set_height(0, math.floor(vim.o.lines * 0.3))
    vim.wo.winfixheight = true
    vim.cmd.term()
end)

vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("user.terminal", {}),
    callback = function()
        vim.cmd.set "filetype=term"
    end,
})
