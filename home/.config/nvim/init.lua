vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.o.termguicolors = true
vim.o.exrc = true

vim.o.signcolumn = "no"

vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.breakindent = true
vim.o.linebreak = true
vim.o.wrap = false

vim.o.inccommand = "split"
vim.o.smartcase = true
vim.o.ignorecase = true

vim.o.clipboard = "unnamedplus"

vim.o.splitright = true
vim.o.splitbelow = true

vim.opt.iskeyword:append "-"
vim.opt.isfname:append "@-@"

vim.o.undofile = true
vim.o.swapfile = false

vim.opt.shortmess:append "c"

vim.o.list = true
vim.opt.listchars = {
    tab = "» ",
    trail = "·",
    nbsp = "␣",
    extends = "→",
    precedes = "←",
}
vim.o.fillchars = "stl:─,stlnc:─"

vim.opt.guicursor:append "t:ver100-blinkon0-TermCursor"
vim.o.nrformats = "unsigned"

vim.opt.diffopt:append {
    "algorithm:histogram",
    "linematch:60",
    "hiddenoff",
    "iwhite",
}

vim.opt.complete:append "o"
vim.opt.completeopt:append { "menuone", "noinsert", "fuzzy" }

vim.o.pumheight = 10
vim.o.pumblend = 5
vim.o.winblend = 5

vim.o.wildmode = "noselect"
vim.opt.wildoptions:append "fuzzy"

vim.g.netrw_banner = 0
vim.g.netrw_cursor = 0
vim.g.netrw_altfile = 1
vim.g.netrw_sort_sequence = [[[\/]$,*]]

vim.o.grepprg = "rg --vimgrep --color=never --no-heading --smart-case --hidden --glob=!.git"
vim.opt.grepformat:prepend "%f:%l:%c:%m"

FindFunc = function(cmdarg)
    local find_cmd = vim.o.grepprg .. " --files"
    local fnames = vim.fn.systemlist(find_cmd)
    return #cmdarg == 0 and fnames or vim.fn.matchfuzzy(fnames, cmdarg)
end
vim.o.findfunc = "v:lua.FindFunc"

-- `!` forces the switch if current buffer has unsaved changes
vim.keymap.set("n", "<C-f>", ":fin! ", { desc = "find files" })
vim.keymap.set("n", "<C-b>", ":b! ", { desc = "pick buffer" })
-- `sil` hides command output; `!` stops auto-jump
vim.keymap.set("n", "<C-g>", ":sil gr! ", { desc = "grep" })

function Format(s, e)
    local formatprg = vim.bo.formatprg
    if formatprg == "" then
        return 1
    end
    s = s or vim.v.lnum
    e = e or (vim.v.lnum + vim.v.count - 1)
    local out = vim.system(
        vim.split(vim.fn.expandcmd(formatprg), " "),
        { stdin = vim.api.nvim_buf_get_lines(0, s - 1, e, true), cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0)) }
    ):wait()
    if out.code == 0 then
        vim.api.nvim_buf_set_lines(0, s - 1, e, true, vim.split(out.stdout, "\n", { trimempty = true }))
    end
    return out.code
end
vim.o.formatexpr = "v:lua.Format()"

for _, v in pairs { "<C-d>", "<C-u>", "n", "N", "*", "#", "g*", "g#", "G", "<C-o>", "<C-i>" } do
    vim.keymap.set("n", v, v .. "zz")
end

vim.keymap.set({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

for i = 1, 5 do
    vim.keymap.set("n", "<M-" .. i .. ">", "<cmd>" .. i .. "argu<cr>", { silent = true })
end

vim.keymap.set("n", "<C-e>", function()
    return vim.bo.filetype == "netrw" and vim.cmd.Rexplore() or vim.cmd.Explore()
end)

vim.keymap.set("n", "grq", function()
    vim.diagnostic.setqflist()
    local sev_order = { E = 1, W = 2, I = 3, H = 4 }
    local items = vim.fn.getqflist()
    table.sort(items, function(a, b)
        local sa, sb = sev_order[a.type] or 5, sev_order[b.type] or 5
        return sa < sb or (sa == sb and a.lnum < b.lnum)
    end)
    vim.fn.setqflist({}, "r", { items = items })
end)
vim.keymap.set("n", "grl", vim.diagnostic.setloclist)

local function grep(input)
    local escaped = vim.fn.shellescape(input):gsub("%%", "\\%%"):gsub("#", "\\#")
    vim.cmd.grep { "-U --fixed-strings -- " .. escaped, bang = true, mods = { silent = true } }
end
vim.keymap.set("n", "<leader>gw", function()
    grep(vim.fn.expand "<cword>")
end)
vim.keymap.set("x", "<leader>gw", function()
    local mode = vim.fn.mode()
    local lines = vim.fn.getregion(vim.fn.getpos "v", vim.fn.getpos ".", { type = mode })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    grep(vim.trim(table.concat(lines, "\n")))
end)

vim.keymap.set("n", "<leader>f", function()
    return vim.bo.formatprg ~= "" and Format(1, -1) or vim.lsp.buf.format()
end)

vim.keymap.set("n", "<leader>st", function()
    vim.cmd.new()
    vim.api.nvim_win_set_height(0, math.floor(vim.o.lines * 0.25))
    vim.wo.winfixheight = true
    vim.cmd.term()
end)

local function git_diff(rev)
    rev = rev or "HEAD"
    local file = vim.api.nvim_buf_get_name(0)
    local root = assert(vim.fs.root(file, ".git"), "not in a git repo")
    local path = vim.fs.relpath(root, file)
    vim.cmd.diffsplit {
        ("git://%s//%s:%s"):format(root, rev, path),
        mods = { vertical = true, split = "leftabove" },
    }
    vim.cmd.wincmd "p"
end
vim.keymap.set("n", "<leader>gd", git_diff)
vim.keymap.set("n", "<leader>gD", function()
    local ref = vim.fn.input "ref> "
    git_diff(ref)
end)

local function git_blame(ref)
    ref = ref or "HEAD"
    local file = vim.api.nvim_buf_get_name(0)
    local root = assert(vim.fs.root(0, ".git"), "not in a git repo")
    local path = vim.fs.relpath(root, file)
    local row = unpack(vim.api.nvim_win_get_cursor(0))
    local result = vim.system({ "git", "blame", ref, ("-L%d,%d"):format(row, row), "--", path }, { cwd = root }):wait()
    vim.api.nvim_echo({ { result.stdout } }, false, { id = "git_blame" })
end
vim.keymap.set("n", "<leader>gb", git_blame)
vim.keymap.set("n", "<leader>gB", function()
    local ref = vim.fn.input "ref> "
    git_blame(ref)
end)

vim.keymap.set("n", "<leader>u", function()
    vim.cmd.packadd "nvim.undotree"
    vim.cmd.Undotree()
end)

vim.api.nvim_create_user_command("Notes", function()
    local basename = vim.fs.basename(vim.fn.getcwd())
    local notes_path = vim.fs.joinpath(vim.env.HOME, "notes", basename .. ".md")
    vim.cmd("tab drop " .. notes_path)
end, {})

vim.api.nvim_create_user_command("TrimWhitespace", function()
    vim.cmd [[%s/\s\+$//e]]
end, {})

vim.api.nvim_create_autocmd("BufReadCmd", {
    group = vim.api.nvim_create_augroup("user.git", {}),
    pattern = "git://*//*",
    callback = function(ev)
        local root, obj = ev.match:match "^git://(.+)//(.+)$"
        local out = vim.system({ "git", "show", obj }, { cwd = root, text = true }):wait()
        vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, vim.split(out.stdout, "\n", { trimempty = true }))
        vim.bo[ev.buf].modifiable = false
        vim.bo[ev.buf].buftype = "nofile"
        vim.bo[ev.buf].bufhidden = "wipe"
        vim.bo[ev.buf].filetype = vim.filetype.match { filename = obj:match ":(.+)$" } or ""
    end,
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
    group = vim.api.nvim_create_augroup("user.search", { clear = true }),
    pattern = { "[^l]*" },
    command = "cwindow",
})

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("user.yank", { clear = true }),
    pattern = "*",
    callback = function()
        vim.hl.on_yank { timeout = 150 }
    end,
})

vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("user.terminal", { clear = true }),
    callback = function()
        vim.opt_local.scrolloff = 0
        vim.opt_local.sidescrolloff = 0
        vim.opt_local.whichwrap:append "h"
        vim.opt_local.whichwrap:append "l"
    end,
})

vim.api.nvim_set_hl(0, "Normal", { bg = "none", update = true })
vim.api.nvim_set_hl(0, "NormalFloat", { link = "Pmenu" })
vim.api.nvim_set_hl(0, "QuickFixLine", { link = "Pmenu" })
vim.api.nvim_set_hl(0, "WinSeparator", { link = "LineNr" })
vim.api.nvim_set_hl(0, "StatusLine", { link = "LineNr" })
vim.api.nvim_set_hl(0, "StatusLineNC", { link = "StatusLine" })
vim.api.nvim_set_hl(0, "StatusLineTermNC", { link = "StatusLine" })
vim.api.nvim_set_hl(0, "TabLine", { link = "StatusLine" })
vim.api.nvim_set_hl(0, "TabLineFill", { link = "StatusLine" })
vim.api.nvim_set_hl(0, "DiffAdd", { bg = "none", fg = "none", update = true })
vim.api.nvim_set_hl(0, "DiffChange", { fg = "none", update = true })
vim.api.nvim_set_hl(0, "DiffText", { fg = "none", update = true })

require("vim._core.ui2").enable { msg = { targets = { progress = "msg" } } }
