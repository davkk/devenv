local group = vim.api.nvim_create_augroup("user.search", { clear = true })

FindFunc = function(cmdarg)
    local fd_args = {
        "--type f",
        "--type l",
        "--hidden",
        "--follow",
        "--exclude .git",
    }

    local cmd = [[ find . ]]
    if vim.fn.executable "fd" == 1 then
        cmd = string.format("fd %s", table.concat(fd_args, " "))
    elseif vim.fn.executable "fdfind" == 1 then
        cmd = string.format("fdfind %s", table.concat(fd_args, " "))
    end

    local fnames = vim.fn.systemlist(cmd)
    if #cmdarg == 0 then
        return fnames
    else
        return vim.fn.matchfuzzy(fnames, cmdarg)
    end
end

vim.opt.findfunc = "v:lua.FindFunc"

if vim.fn.executable "rg" == 1 then
    vim.opt.grepprg = table.concat({
        "rg",
        "--vimgrep",
        "--no-heading",
        "--smart-case",
        "--hidden",
        "--glob=!.git",
    }, " ")
    vim.opt.grepformat:append "%f:%l:%c:%m"
end

vim.keymap.set("n", "<C-f>", ":sil! fin! ", { desc = "find files" })
vim.keymap.set("n", "<C-b>", ":sil! b! ", { desc = "pick buffer" })

vim.keymap.set("n", "<C-g>", ":sil! gr! ", { desc = "grep" })
vim.keymap.set({ "n", "v" }, "<leader>gw", function()
    local input
    if vim.fn.mode() == "v" or vim.fn.mode() == "V" then
        vim.cmd.normal [["vy]]
        local selection = vim.fn.getreg "v"
        input = string.gsub(selection, "\n", "")
    else
        input = vim.fn.expand "<cword>"
    end
    input = input:gsub("%%", "\\%%")
    input = input:gsub("#", "\\#")
    vim.cmd("sil! gr! -U --fixed-strings -- " .. vim.fn.shellescape(input))
end, { desc = "grep cword" })

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
    group = group,
    pattern = { "[^l]*" },
    command = "cwindow",
})
