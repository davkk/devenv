vim.bo.bufhidden = "wipe"
vim.keymap.set(
    "n",
    "_",
    function()
        local root = vim.fs.root(0, { { ".git" }, { "tags" } })
        if root then vim.cmd.edit(root) end
    end,
    { buffer = true, noremap = true, silent = true }
)
