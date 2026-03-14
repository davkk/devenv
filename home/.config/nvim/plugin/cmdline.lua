local group = vim.api.nvim_create_augroup("user.cmdline", { clear = true })

local keep_open = false

vim.api.nvim_create_autocmd("CmdlineChanged", {
    group = group,
    callback = function()
        if vim.api.nvim_get_mode().mode == "c" and keep_open then
            vim.opt.wildmenu = true
            vim.opt.wildmode = "noselect,full:full"
            vim.fn.wildtrigger()
        end
    end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function()
        keep_open = false
    end,
})

vim.keymap.set("c", "<C-n>", function()
    keep_open = true
    vim.opt.wildmenu = true
    vim.opt.wildmode = "noselect,full:full"
    if vim.fn.wildmenumode() == 1 then
        return "<C-n>"
    else
        vim.fn.wildtrigger()
        return ""
    end
end, { expr = true })

vim.keymap.set("c", "<C-e>", function()
    keep_open = false
    return "<C-e>"
end, { expr = true })
