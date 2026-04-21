local group = vim.api.nvim_create_augroup("user.search", { clear = true })

local has_rg = vim.fn.executable "rg" == 1

if has_rg then
    vim.o.grepprg = "rg --vimgrep --color=never --no-heading --smart-case --hidden --glob=!.git"
    vim.opt.grepformat:prepend "%f:%l:%c:%m"
end

FindFunc = function(cmdarg)
    local find_cmd = has_rg and vim.o.grepprg .. " --files" or "find . -type f -not -path */.git/*"
    local fnames = vim.fn.systemlist(find_cmd)
    return #cmdarg == 0 and fnames or vim.fn.matchfuzzy(fnames, cmdarg)
end
vim.o.findfunc = "v:lua.FindFunc"

vim.keymap.set("n", "<C-f>", ":sil! fin! ", { desc = "find files" })
vim.keymap.set("n", "<C-b>", ":sil! b! ", { desc = "pick buffer" })
vim.keymap.set("n", "<C-g>", ":sil! gr! ", { desc = "grep" })

local function grep(input)
    local escaped = vim.fn.shellescape(input):gsub("%%", "\\%%"):gsub("#", "\\#")
    vim.cmd.grep { "-U --fixed-strings -- " .. escaped, bang = true, mods = { silent = true } }
end

vim.keymap.set("n", "<leader>gw", function()
    grep(vim.fn.expand "<cword>")
end, { desc = "grep cword" })

vim.keymap.set("x", "<leader>gw", function()
    local mode = vim.fn.mode()
    local lines = vim.fn.getregion(vim.fn.getpos "v", vim.fn.getpos ".", { type = mode })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    grep(vim.trim(table.concat(lines, "\n")))
end, { desc = "grep selection" })

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
    group = group,
    pattern = { "[^l]*" },
    command = "cwindow",
})
