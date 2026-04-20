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

vim.o.winborder = "solid"

vim.o.nrformats = "unsigned"
vim.o.exrc = true

vim.o.autocomplete = false
vim.o.autocompletedelay = 100
vim.opt.complete:append "o"
vim.opt.completeopt = { "menu", "menuone", "noinsert", "popup", "fuzzy" }

vim.opt.wildmode = { "noselect", "full:full" }
vim.opt.wildoptions = { "pum", "fuzzy", "tagfile" }
vim.o.pumheight = 10
vim.o.pumblend = 5

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 0
vim.g.netrw_cursor = 0
vim.g.netrw_altfile = 1
vim.g.netrw_sort_sequence = [[[\/]$,*]]

vim.opt.guicursor:append "t:blinkon0-TermCursor"

local opts = { noremap = true, silent = true }

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

vim.keymap.set("n", "<C-e>", function()
    if vim.bo.filetype == "netrw" then
        vim.cmd.Rexplore()
    else
        local filename = vim.fn.expand "%:p:t"
        vim.cmd.Explore()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for idx, file in ipairs(lines) do
            if file == filename then
                vim.api.nvim_win_set_cursor(0, { idx, 0 })
                break
            end
        end
    end
end, opts)

vim.keymap.set("c", "<tab>", function()
    if vim.fn.wildmenumode() == 1 then
        return "<tab>"
    end
    vim.fn.wildtrigger()
    return ""
end, { expr = true })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", opts)
vim.keymap.set("n", "<leader>st", function()
    vim.cmd.new()
    vim.api.nvim_win_set_height(0, math.floor(vim.o.lines * 0.3))
    vim.wo.winfixheight = true
    vim.cmd.term()
end, opts)

local function open_notes()
    local basename = vim.fs.basename(vim.fn.getcwd())
    local notes_path = vim.fs.joinpath(vim.env.HOME, "notes", basename .. ".md")
    vim.cmd("tab drop " .. notes_path)
end
vim.keymap.set("n", "<leader>on", open_notes, { silent = true })
vim.api.nvim_create_user_command("Notes", open_notes, {})

vim.api.nvim_create_user_command("TrimWhitespace", function()
    vim.cmd [[%s/\s\+$//e]]
end, {})

vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("user.terminal", { clear = true }),
    callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.scrolloff = 0
        vim.opt_local.sidescrolloff = 0
        vim.opt_local.whichwrap:append "h"
        vim.opt_local.whichwrap:append "l"
    end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("user.yank", { clear = true }),
    pattern = "*",
    callback = function()
        vim.hl.on_yank { timeout = 150 }
    end,
})

vim.filetype.add {
    extension = {
        ["hip"] = "cuda",
        ["tex"] = "tex",
    },
}

local osc52 = require "vim.ui.clipboard.osc52"
local function paste()
    local content = vim.fn.getreg '"'
    return vim.split(content, "\n")
end
vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = osc52.copy "+",
        ["*"] = osc52.copy "*",
    },
    paste = {
        ["+"] = paste,
        ["*"] = paste,
    },
}
