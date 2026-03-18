local function open_notes()
    local basename = vim.fs.basename(vim.fn.getcwd())
    local notes_path = vim.fs.joinpath(vim.env.HOME, "notes", basename .. ".md")
    vim.cmd("tab drop " .. notes_path)
end

vim.api.nvim_create_user_command("Notes", open_notes, {})
vim.keymap.set("n", "<leader>on", open_notes, { silent = true })
