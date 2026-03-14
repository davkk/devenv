vim.bo.bufhidden = "wipe"
vim.bo.buflisted = false

vim.keymap.set("n", "_", function()
    vim.cmd.Explore(vim.fn.getcwd())
end, { buffer = 0, noremap = true, silent = true })
