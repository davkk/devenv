-- sync jupyter notebook
vim.keymap.set("n", "<leader>jt", "<cmd>!jupytext --sync %<cr>", { buffer = 0, desc = "Sync jupytext" })
