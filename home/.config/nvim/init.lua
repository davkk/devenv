vim.g.mapleader = vim.keycode "<space>"

vim.o.termguicolors = true
vim.o.exrc = true

vim.o.relativenumber = true
vim.o.number = true

vim.o.laststatus = 3
vim.o.statusline = "%<%f %r%m%=%{%v:lua.vim.diagnostic.status()%} %3l:%-2c"

vim.o.signcolumn = "yes"
vim.o.winborder = "solid"

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
    extends = "→",
    precedes = "←",
    conceal = "┊",
    nbsp = "␣",
}

vim.opt.diffopt:append "linematch:60"
vim.opt.diffopt:append "algorithm:histogram"

vim.opt.guicursor:append "t:ver100-blinkon0-TermCursor"

vim.o.nrformats = "unsigned"

vim.opt.complete:append "o"
vim.opt.completeopt:append "menuone"
vim.opt.completeopt:append "noinsert"
vim.opt.completeopt:append "fuzzy"

vim.o.pumheight = 10
vim.o.pumblend = 5

vim.o.wildmode = "noselect"
vim.opt.wildoptions:append "fuzzy"

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 0
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

vim.keymap.set("n", "<C-f>", ":sil! fin! ", { desc = "find files" })
vim.keymap.set("n", "<C-b>", ":sil! b! ", { desc = "pick buffer" })
vim.keymap.set("n", "<C-g>", ":sil! gr! ", { desc = "grep" })

function Format()
    local formatprg = vim.bo.formatprg
    if not formatprg or formatprg == "" then
        return 0
    end
    local start_lnum = vim.v.lnum
    local end_lnum = start_lnum + vim.v.count - 1
    local lines = vim.api.nvim_buf_get_lines(0, start_lnum - 1, end_lnum, true)
    local cmd = vim.split(vim.fn.expandcmd(formatprg), " ")
    local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local output = vim.system(cmd, { stdin = lines, cwd = cwd }):wait()
    if output.code ~= 0 then
        vim.schedule(function()
            vim.notify(output.stderr, vim.log.levels.ERROR)
        end)
        return 0
    end
    local formatted = vim.split(output.stdout, "\n", { trimempty = true })
    vim.api.nvim_buf_set_lines(0, start_lnum - 1, end_lnum, true, formatted)
    return 0
end
vim.bo.formatexpr = "v:lua.Format()"

local opts = { noremap = true, silent = true }

for _, v in pairs { "<C-d>", "<C-u>", "n", "N", "*", "#", "g*", "g#", "G", "<C-o>", "<C-i>" } do
    vim.keymap.set("n", v, v .. "zz", opts)
end

vim.keymap.set({ "n", "v" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ "n", "v" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.keymap.set("n", "<left>", "gT", opts)
vim.keymap.set("n", "<right>", "gt", opts)

for i = 1, 5 do
    vim.keymap.set("n", "<M-" .. i .. ">", "<cmd>" .. i .. "argu<cr>", { silent = true })
end

local function grep(input)
    local escaped = vim.fn.shellescape(input):gsub("%%", "\\%%"):gsub("#", "\\#")
    vim.cmd.grep { "-U --fixed-strings -- " .. escaped, bang = true, mods = { silent = true } }
end

vim.keymap.set("n", "<leader>gw", function()
    grep(vim.fn.expand "<cword>")
end, opts)

vim.keymap.set("x", "<leader>gw", function()
    local mode = vim.fn.mode()
    local lines = vim.fn.getregion(vim.fn.getpos "v", vim.fn.getpos ".", { type = mode })
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    grep(vim.trim(table.concat(lines, "\n")))
end, opts)

vim.keymap.set("n", "<C-e>", function()
    if vim.bo.filetype == "netrw" then
        vim.cmd.Rexplore()
        return
    end
    local filename = vim.fn.expand "%:p:t"
    vim.cmd.Explore()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    for idx, file in ipairs(lines) do
        if file == filename then
            vim.api.nvim_win_set_cursor(0, { idx, 0 })
            break
        end
    end
end, opts)

vim.keymap.set("n", "<leader>f", function()
    if vim.bo.formatprg ~= "" then
        local view = vim.fn.winsaveview()
        vim.cmd.normal { "gggqG", bang = true, mods = { silent = true, keepjumps = true } }
        vim.fn.winrestview(view)
    else
        vim.lsp.buf.format()
    end
end, opts)

vim.keymap.set("n", "grq", function()
    vim.diagnostic.setqflist()
    local sev_order = { E = 1, W = 2, I = 3, H = 4 }
    local items = vim.fn.getqflist()
    table.sort(items, function(a, b)
        local sa, sb = sev_order[a.type] or 5, sev_order[b.type] or 5
        return sa < sb or (sa == sb and a.lnum < b.lnum)
    end)
    vim.fn.setqflist({}, "r", { items = items })
end, opts)
vim.keymap.set("n", "grl", vim.diagnostic.setloclist, opts)

vim.keymap.set("n", "<leader>st", function()
    vim.cmd.new()
    vim.api.nvim_win_set_height(0, math.floor(vim.o.lines * 0.25))
    vim.wo.winfixheight = true
    vim.cmd.term()
end, opts)

local function git_diff(ref)
    ref = ref or "HEAD"
    vim.cmd.diffsplit { "git://" .. ref .. "/%", mods = { vertical = true, split = "leftabove" } }
    vim.cmd.wincmd "p"
end
vim.keymap.set("n", "<leader>gd", git_diff, opts)
vim.keymap.set("n", "<leader>gD", function()
    local ref = vim.fn.input "ref> "
    git_diff(ref)
end, opts)

local function git_blame(ref)
    ref = ref or "HEAD"
    local root = vim.fs.root(0, ".git")
    local path = vim.fn.expand("%:p"):sub(#root + 2)
    local row = unpack(vim.api.nvim_win_get_cursor(0))
    local result = vim.system({ "git", "blame", ref, ("-L%d,%d"):format(row, row), "--", path }, { cwd = root }):wait()
    print(result.stdout)
end
vim.keymap.set("n", "<leader>gb", git_blame, opts)
vim.keymap.set("n", "<leader>gB", function()
    local ref = vim.fn.input "ref> "
    git_blame(ref)
end, opts)

vim.cmd.packadd "cfilter"

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

local arglist_key = "ARGLIST_" .. vim.fn.getcwd():gsub("%W", "_"):upper()

vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        local l = vim.tbl_filter(function(f)
            return f:match "%S"
        end, vim.g[arglist_key] or {})
        vim.g[arglist_key] = l
        vim.cmd.argdelete { "*", mods = { silent = true, emsg_silent = true } }
        pcall(vim.cmd.argadd, { table.concat(vim.tbl_map(vim.fn.fnameescape, l), " ") })
    end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
        vim.g[arglist_key] = vim.fn.argv()
    end,
})

vim.api.nvim_create_autocmd("BufReadCmd", {
    pattern = "git://*/*",
    callback = function(ev)
        local ref, path = ev.match:match "git://([^/]+)/(.*)"
        local root = vim.fs.root(0, ".git")
        local result = vim.system({ "git", "show", ref .. ":" .. path }, { cwd = root }):wait()
        vim.api.nvim_buf_set_lines(ev.buf, 0, -1, false, vim.split(result.stdout, "\n"))
        vim.bo[ev.buf].modifiable = false
        vim.bo[ev.buf].buftype = "nofile"
        vim.bo[ev.buf].bufhidden = "wipe"
        vim.bo[ev.buf].filetype = vim.filetype.match { filename = path } or ""
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
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
        vim.opt_local.signcolumn = "no"
        vim.opt_local.scrolloff = 0
        vim.opt_local.sidescrolloff = 0
        vim.opt_local.whichwrap:append "h"
        vim.opt_local.whichwrap:append "l"
    end,
})

vim.api.nvim_create_autocmd("LspProgress", {
    callback = function(ev)
        local value = ev.data.params.value or {}
        local msg = value.message or "done"
        if #msg > 40 then
            msg = msg:sub(1, 37) .. "..."
        end
        vim.api.nvim_echo({ { msg } }, false, {
            id = "lsp",
            source = "lsp",
            kind = "progress",
            title = value.title,
            status = value.kind ~= "end" and "running" or "success",
            percent = value.percentage,
        })
    end,
})

vim.api.nvim_create_user_command("ToggleDiagnostics", function()
    vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, {})

vim.diagnostic.config {
    severity_sort = true,
    virtual_text = true,
    float = {
        source = true,
        show_header = true,
        header = "",
        prefix = "",
    },
}

require("vim._core.ui2").enable {
    enable = true,
    msg = {
        target = "msg",
        targets = {
            typed_cmd = "cmd",
            search_cmd = "cmd",
            search_count = "cmd",
            completion = "cmd",
            wildlist = "cmd",
            confirm = "cmd",
            [""] = "msg",
            empty = "msg",
            echo = "msg",
            echomsg = "msg",
            bufwrite = "msg",
            undo = "msg",
            wmsg = "msg",
            shell_ret = "msg",
            emsg = "pager",
            echoerr = "pager",
            lua_error = "pager",
            verbose = "pager",
            progress = "pager",
            shell_cmd = "pager",
            shell_out = "pager",
            shell_err = "pager",
            list_cmd = "pager",
            quickfix = "pager",
            rpc_error = "pager",
            lua_print = "pager",
        },
        cmd = {
            height = 0.3,
        },
        msg = {
            height = 0.3,
            timeout = 2000,
        },
        pager = {
            height = 0.5,
        },
    },
}
