vim.pack.add { { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" } }

local treesitter = require "nvim-treesitter"
treesitter.install {
    "lua",
    "luadoc",
    "vim",
    "vimdoc",
    "bash",
    "html",
    "markdown",
    "javascript",
    "jsdoc",
    "typescript",
    "tsx",
    "css",
    "json",
    "c",
    "cpp",
    "doxygen",
    "python",
    "angular",
    "zig",
    "java",
}

vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldmethod = "expr"
vim.o.foldtext = ""

vim.api.nvim_create_autocmd("FileType", {
    callback = function()
        local ok = pcall(vim.treesitter.start)
        if ok then
            vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end
    end,
})
