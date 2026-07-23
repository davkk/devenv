vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.netrw_banner = 0
vim.g.netrw_cursor = 0
vim.g.netrw_altfile = 1
vim.g.netrw_sort_sequence = [[[\/]$,*]]
vim.g.loaded_nvim_dir_plugin = 1
vim.g.quickfill = {
    url = "http://localhost:8012",
    model = "sweep-next-edit-1.5b.q8_0.v2",
    chunk_lines = 4,
    max_extra_chunks = 3,
    n_suffix = 8,
    n_prefix = 8,
    max_lsp_completion_items = 10,
    fresh_on_trigger_char = false,
}

vim.o.termguicolors = true
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
vim.o.undofile = true
vim.o.swapfile = false
vim.o.list = true
vim.o.fillchars = "stl:─,stlnc:─"
vim.o.nrformats = "unsigned"
vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldmethod = "expr"
vim.o.foldtext = ""
vim.o.pumheight = 10
vim.o.pumblend = 5
vim.o.winblend = 5
vim.o.wildmode = "noselect"
vim.o.grepprg = "rg --vimgrep -uu --smart-case --glob=!.git"

function FindFunc(cmdarg)
    local find_cmd = ("%s --files"):format(vim.o.grepprg)
    local fnames = vim.fn.systemlist(find_cmd)
    return #cmdarg == 0 and fnames or vim.fn.matchfuzzy(fnames, cmdarg)
end
vim.o.findfunc = "v:lua.FindFunc"

vim.opt.shortmess:append "c"
vim.opt.listchars = {
    tab = "» ",
    trail = "·",
    nbsp = "␣",
    extends = "→",
    precedes = "←",
}
vim.opt.guicursor:append "t:ver100-blinkon0-TermCursor"
vim.opt.diffopt:append {
    "algorithm:histogram",
    "linematch:60",
    "hiddenoff",
    "iwhite",
}
vim.opt.complete:append "o"
vim.opt.completeopt:append { "menuone", "noinsert", "fuzzy" }
vim.opt.wildoptions:append "fuzzy"

vim.keymap.set("n", "-", "<cmd>Explore %:h<CR>")
vim.keymap.set({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
for i = 1, 5 do
    vim.keymap.set("n", "<M-" .. i .. ">", "<cmd>" .. i .. "argu<cr>", { silent = true })
end
vim.keymap.set("i", "<C-q>", "<Plug>(quickfill-accept)")
vim.keymap.set("i", "<C-S-q>", "<Plug>(quickfill-accept-replace)")
vim.keymap.set("i", "<C-l>", "<Plug>(quickfill-accept-word)")
vim.keymap.set("i", "<C-space>", "<Plug>(quickfill-trigger)")

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

vim.api.nvim_create_user_command("TrimWhitespace", function() vim.cmd [[%s/\s\+$//e]] end, {})

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

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("user.yank", { clear = true }),
    pattern = "*",
    callback = function() vim.hl.on_yank { timeout = 150 } end,
})

vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("user.terminal", { clear = true }),
    callback = function(ev)
        vim.opt_local.scrolloff = 0
        vim.opt_local.sidescrolloff = 0
        vim.opt_local.whichwrap:append "h"
        vim.opt_local.whichwrap:append "l"
        vim.keymap.set("n", "<leader>tq", "<cmd>cgetb|bd!|cope<cr>", { buffer = ev.buf })
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

local ft = {
    cpp = function()
        vim.opt_local.iskeyword = vim.api.nvim_get_option_info2("iskeyword", {}).default
        vim.opt_local.formatprg = "clang-format -assume-filename %"
    end,
    go = function() vim.opt_local.formatprg = "gofmt" end,
    lua = function() vim.opt_local.formatprg = "stylua --stdin-filepath % --search-parent-directories -" end,
    python = function() vim.opt_local.formatprg = "ruff format --force-exclude --stdin-filename % -" end,
    zig = function() vim.opt_local.formatprg = "zig fmt --stdin" end,
    javascript = function() vim.opt_local.formatprg = "eslint_d --stdin --stdin-filename % --fix-to-stdout" end,
    make = function() vim.opt_local.expandtab = false end,
    qf = function() vim.cmd.packadd "cfilter" end,
    netrw = function()
        vim.bo.bufhidden = "wipe"
        vim.keymap.set(
            "n",
            "_",
            function() vim.cmd.Explore(vim.fn.getcwd()) end,
            { buffer = true, noremap = true, silent = true }
        )
    end,
    txt = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
        vim.opt_local.spelllang = { "en" }
    end,
}
ft.gitcommit = ft.txt
ft.markdown = ft.txt
ft.text = ft.txt
ft.typst = ft.txt
ft.typescript = ft.javascript

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("user.ftplugin", { clear = true }),
    pattern = vim.tbl_keys(ft),
    callback = function(ev)
        if pcall(vim.treesitter.start) then vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()" end
        if ft[ev.match] then vim.schedule(ft[ev.match]) end
    end,
})

require("vim._core.ui2").enable()

vim.pack.add {
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    "https://github.com/nvim-treesitter/nvim-treesitter-context",
}
require("nvim-treesitter").install { "lua", "cpp", "python", "go", "zig", "ocaml", "bash" }
