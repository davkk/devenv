local format = require "core.format"
local utils = require "core.utils"

local fn = utils.fn

format.config {
    cmd = { "stylua", "--stdin-filepath", utils.relative_path, "-" },
    filetypes = { "lua" },
    root_markers = { ".stylua.toml" },
}

format.config {
    cmd = { fn(utils.node_modules, "biome"), "--stdin-filepath", utils.relative_path, "-" },
    filetypes = { "javascript", "typescript", "json" },
    root_markers = { "biome.json" },
}

format.config {
    cmd = { fn(utils.node_modules, "prettierd"), utils.relative_path },
    filetypes = { "sass", "scss", "css", "less", "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_markers = function(name)
        return name:match "^%.prettierrc" or name:match "^prettier.config"
    end,
}

format.config {
    cmd = { fn(utils.node_modules, "eslint_d"), "--fix-to-stdout", "--stdin", "--stdin-filename", utils.relative_path },
    filetypes = { "javascript", "typescript" },
    root_markers = function(name)
        return name:match "^.eslintrc" or name:match "^eslint.config"
    end,
}

format.config {
    cmd = { "clang-format", "-assume-filename", utils.relative_path },
    filetypes = { "cpp" },
    root_markers = { ".clang-format" },
}

format.config {
    cmd = { "ruff", "format", "--force-exclude", "--stdin-filename", utils.relative_path, "-" },
    filetypes = { "python" },
}

format.config {
    cmd = { "zig", "fmt", "--stdin" },
    filetypes = { "zig" },
}

vim.keymap.set("n", "<leader>f", function()
    return format.external_format() or format.lsp_format()
end, { desc = "format buffer" })
