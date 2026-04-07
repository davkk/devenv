vim.g.mapleader = vim.keycode "<space>"

vim.o.termguicolors = true

vim.o.relativenumber = true
vim.o.number = true

vim.o.laststatus = 3
vim.o.signcolumn = "yes"

vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.breakindent = true
vim.o.linebreak = true
vim.o.wrap = false

vim.opt.formatoptions:remove "o"
vim.opt.formatoptions:remove "t"

vim.o.inccommand = "split"
vim.o.smartcase = true
vim.o.ignorecase = true

vim.opt.clipboard:append "unnamedplus"

vim.o.splitright = true
vim.o.splitbelow = true

vim.opt.iskeyword:append "-"
vim.opt.isfname:append "@-@"

vim.o.undofile = true
vim.o.swapfile = false
vim.o.backup = false

vim.opt.shortmess:append "c"

vim.o.list = true
vim.opt.listchars = {
    tab = "» ",
    trail = "·",
    extends = "→",
    precedes = "←",
    conceal = "┊",
    nbsp = "␣",
}

vim.opt.diffopt:append "linematch:60"
vim.opt.diffopt:append "algorithm:histogram"

vim.opt.guicursor:append "t:ver100"

vim.opt.winborder = "solid"

local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<leader>nh", ":nohl<CR>", opts)

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], opts)

vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
vim.keymap.set("n", "{", "{zz", opts)
vim.keymap.set("n", "}", "}zz", opts)
vim.keymap.set("n", "n", "nzzzv", opts)
vim.keymap.set("n", "N", "Nzzzv", opts)
vim.keymap.set("n", "*", "*zz", opts)
vim.keymap.set("n", "#", "#zz", opts)
vim.keymap.set("n", "g*", "g*zz", opts)
vim.keymap.set("n", "g#", "g#zz", opts)
vim.keymap.set("n", "G", "Gzz", opts)
vim.keymap.set("n", "<C-o>", "<C-o>zz", opts)
vim.keymap.set("n", "<C-i>", "<C-i>zz", opts)

vim.keymap.set("n", "<A-Right>", "<C-w>5>", opts)
vim.keymap.set("n", "<A-Left>", "<C-w>5<", opts)
vim.keymap.set("n", "<A-Up>", "<C-w>2+", opts)
vim.keymap.set("n", "<A-Down>", "<C-w>2-", opts)

vim.keymap.set("n", "<left>", "gT", opts)
vim.keymap.set("n", "<right>", "gt", opts)

vim.keymap.set({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("user.yank", { clear = true }),
    desc = "Highlight selection on yank",
    pattern = "*",
    callback = function()
        vim.hl.on_yank { timeout = 150 }
    end,
})

vim.api.nvim_create_user_command("TrimWhitespace", function()
    vim.cmd [[%s/\s\+$//e]]
end, {})

vim.filetype.add {
    extension = {
        ["hip"] = "cuda",
        ["tex"] = "tex",
    },
}
