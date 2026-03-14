local utils = require "core.utils"

vim.opt.wildchar = vim.fn.char2nr ""
vim.opt.wildmode = "noselect,full:full"
vim.opt.wildoptions = { "pum", "fuzzy" }
vim.opt.completeopt = { "menu", "menuone", "noinsert", "popup", "fuzzy" }
vim.o.pumheight = 10
vim.o.pumblend = 5

vim.keymap.set("i", "<cr>", function()
    return tonumber(vim.fn.pumvisible()) ~= 0 and "<C-e><cr>" or "<cr>"
end, { expr = true })

vim.keymap.set("i", "<bs>", function()
    return tonumber(vim.fn.pumvisible()) ~= 0
            and #vim.lsp.get_clients() > 0
            and utils.debounce(function()
                vim.schedule(function()
                    pcall(vim.lsp.completion.get)
                end)
            end, 300)()
        or "<bs>"
end, { expr = true })

vim.api.nvim_create_autocmd("InsertCharPre", {
    group = vim.api.nvim_create_augroup("user.completion", { clear = true }),
    callback = utils.debounce(function()
        if tonumber(vim.fn.pumvisible()) ~= 0 and #vim.lsp.get_clients() > 0 then
            vim.schedule(function()
                pcall(vim.lsp.completion.get)
            end)
        end
    end, 300),
})
