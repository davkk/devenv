vim.bo.bufhidden = "wipe"
vim.keymap.set("n", "_", function() vim.cmd.Explore(vim.fn.getcwd()) end, { buffer = true, noremap = true, silent = true })
