vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.netrw_banner = 0
vim.g.netrw_cursor = 0
vim.g.netrw_altfile = 1
vim.g.loaded_nvim_dir_plugin = 1

vim.o.termguicolors = true
vim.o.number = true
vim.o.laststatus = 1
vim.o.shiftwidth = 4
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.expandtab = true
vim.o.smartcase = true
vim.o.ignorecase = true
vim.o.clipboard = "unnamedplus"
vim.o.undofile = true
vim.o.swapfile = false
vim.o.listchars = "trail:·,nbsp:␣"
vim.o.completeopt = "menuone,noinsert,fuzzy"
vim.o.pumheight = 10
vim.o.pumblend = 5
vim.o.winblend = 5
vim.o.wildmode = "noselect"
vim.o.wildoptions = "pum,tagfile,fuzzy"
vim.o.guicursor = vim.o.guicursor .. ",t:ver100-blinkon0-TermCursor"
vim.o.diffopt = vim.o.diffopt .. ",algorithm:histogram,linematch:60,hiddenoff,iwhite"
vim.o.grepprg = "rg --vimgrep --smart-case --hidden --glob=!.git"

function FindFunc(cmdarg)
    local find_cmd = ("%s --files"):format(vim.o.grepprg)
    local fnames = vim.fn.systemlist(find_cmd)
    return #cmdarg == 0 and fnames or vim.fn.matchfuzzy(fnames, cmdarg)
end
vim.o.findfunc = "v:lua.FindFunc"

vim.keymap.set("n", "-", "<cmd>Explore %:h<cr>")
for i = 1, 5 do
    vim.keymap.set("n", "<M-" .. i .. ">", "<cmd>" .. i .. "argu<cr>", { silent = true })
end
vim.keymap.set("n", "<leader>u", function()
    vim.cmd.packadd "nvim.undotree"
    vim.cmd.Undotree()
end)

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("user.yank", { clear = true }),
    pattern = "*",
    callback = function() vim.hl.on_yank { timeout = 150 } end,
})

vim.api.nvim_set_hl(0, "Normal", { bg = "none", update = true })
vim.api.nvim_set_hl(0, "NormalFloat", { link = "Pmenu" })
vim.api.nvim_set_hl(0, "StatusLine", { link = "StatusLineNC" })
vim.api.nvim_set_hl(0, "StatusLineTermNC", { link = "StatusLineNC" })
vim.api.nvim_set_hl(0, "DiffAdd", { bg = "none", update = true })
vim.api.nvim_set_hl(0, "DiffChange", { fg = "none", update = true })
vim.api.nvim_set_hl(0, "DiffText", { fg = "none", update = true })

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("user.ftplugin", { clear = true }),
    pattern = "*",
    callback = function() pcall(vim.treesitter.start) end,
})

require("vim._core.ui2").enable()

vim.pack.add {
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    "https://github.com/nvim-treesitter/nvim-treesitter-context",
}
require("nvim-treesitter").install { "lua", "cpp", "python", "go", "zig", "ocaml", "bash" }

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
vim.keymap.set("i", "<C-q>", "<Plug>(quickfill-accept)")
vim.keymap.set("i", "<C-S-q>", "<Plug>(quickfill-accept-replace)")
vim.keymap.set("i", "<C-l>", "<Plug>(quickfill-accept-word)")
vim.keymap.set("i", "<C-space>", "<Plug>(quickfill-trigger)")
