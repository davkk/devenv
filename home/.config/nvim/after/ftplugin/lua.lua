if vim.fn.executable "stylua" and vim.fs.root(0, { ".stylua.toml" }) ~= nil then
    vim.opt_local.formatprg = "stylua --stdin-filepath % --search-parent-directories -"
end
