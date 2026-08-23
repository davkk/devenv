vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.netrw_banner = 0
vim.g.netrw_cursor = 0
vim.g.netrw_altfile = 1
vim.g.loaded_nvim_dir_plugin = 1

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
vim.o.list = true
vim.o.completeopt = "menuone,noinsert,fuzzy"
vim.o.pumheight = 10
vim.o.wildmode = "noselect"
vim.o.wildoptions = "pum,tagfile,fuzzy"
vim.o.guicursor = ""
vim.o.diffopt = vim.o.diffopt .. ",algorithm:histogram,linematch:60,hiddenoff,iwhite"
vim.o.grepprg = "rg --vimgrep --smart-case --hidden --glob=!.git"

function FindFunc(cmdarg)
    local find_cmd = ("%s --files"):format(vim.o.grepprg)
    local fnames = vim.fn.systemlist(find_cmd)
    return #cmdarg == 0 and fnames or vim.fn.matchfuzzy(fnames, cmdarg)
end
vim.o.findfunc = "v:lua.FindFunc"

vim.keymap.set(
    "n",
    "-",
    function() return vim.api.nvim_buf_get_name(0) == "" and vim.cmd.Explore() or vim.cmd.Explore "%:h" end
)
for i = 1, 5 do
    vim.keymap.set("n", "<M-" .. i .. ">", "<cmd>" .. i .. "argu<cr>", { silent = true })
end
vim.keymap.set("n", "<leader>u", function()
    vim.cmd.packadd "nvim.undotree"
    vim.cmd.Undotree()
end)

vim.api.nvim_set_hl(0, "Normal", { bg = "none", ctermbg = "none", update = true })
require("vim._core.ui2").enable()

vim.pack.add {
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    "https://github.com/nvim-treesitter/nvim-treesitter-context",
}
require("nvim-treesitter").install { "lua", "cpp", "python", "go", "zig", "ocaml", "bash" }

vim.g.quickfill = {
    url = "http://localhost:8012",
    model = "sweep-next-edit-1.5b.q8_0.v2",
    chunk_lines = 32,
    max_extra_chunks = 4,
    n_suffix = 32,
    n_prefix = 16,
    max_lsp_completion_items = 10,
    fresh_on_trigger_char = false,
}
vim.keymap.set("i", "<C-q>", "<Plug>(quickfill-accept)")
vim.keymap.set("i", "<C-S-q>", "<Plug>(quickfill-accept-replace)")
vim.keymap.set("i", "<C-l>", "<Plug>(quickfill-accept-word)")
vim.keymap.set("i", "<C-space>", "<Plug>(quickfill-trigger)")
