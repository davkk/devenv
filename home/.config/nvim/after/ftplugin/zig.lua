if vim.fn.executable "zig" then
    vim.opt_local.formatprg = "zig fmt --stdin"
end
